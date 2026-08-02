"""Rule-based resume scoring — deterministic, no external calls.

Deliberately not LLM-based: a score has to be reproducible and available
even when Ollama isn't running, and rule-based ATS-style checks (section
headers, quantified bullets, action verbs, keyword coverage) are actually
how most real-world ATS keyword scanners work anyway. Pure function, no
I/O — same shape as app/ai/prompts.build_prompt.
"""

import re
from dataclasses import dataclass, field

_SECTION_HEADERS = [
    "experience",
    "education",
    "skills",
    "projects",
    "summary",
    "certifications",
    "achievements",
]

_ACTION_VERBS = {
    "led", "built", "developed", "designed", "implemented", "managed",
    "created", "improved", "increased", "reduced", "launched", "architected",
    "optimized", "automated", "delivered", "spearheaded", "coordinated",
    "analyzed", "established", "mentored", "streamlined", "drove",
    "engineered", "executed", "founded", "generated", "achieved",
    "collaborated", "resolved", "trained", "negotiated", "authored",
    "deployed", "scaled", "migrated", "refactored", "shipped",
}

# Used only when the caller doesn't supply a target job description —
# a broad, generic bank so an unscoped "just check my resume" upload still
# gets a meaningful keyword signal instead of an empty one.
_GENERIC_KEYWORD_BANK = [
    "python", "javascript", "typescript", "java", "sql", "react", "flutter",
    "aws", "azure", "docker", "kubernetes", "git", "api", "rest", "agile",
    "scrum", "ci/cd", "testing", "leadership", "communication",
    "problem-solving", "teamwork", "project management", "data analysis",
    "machine learning", "cloud", "database", "cross-functional",
]

_EMAIL_RE = re.compile(r"[\w.+-]+@[\w-]+\.[\w.-]+")
_PHONE_RE = re.compile(r"(\+?\d[\d\s().-]{8,}\d)")
_DIGIT_RE = re.compile(r"\d")

_IDEAL_WORD_RANGE = (400, 1100)
_MIN_VIABLE_WORDS = 120


@dataclass
class ScoreBreakdown:
    overall: int
    formatting: int
    keywords: int
    impact: int


@dataclass
class Feedback:
    strengths: list[str] = field(default_factory=list)
    weaknesses: list[str] = field(default_factory=list)
    missing_keywords: list[str] = field(default_factory=list)
    suggestions: list[str] = field(default_factory=list)


@dataclass
class AnalysisResult:
    score: ScoreBreakdown
    feedback: Feedback
    word_count: int


def _bullet_like_lines(text: str) -> list[str]:
    lines = [ln.strip() for ln in text.splitlines()]
    bullets = [ln for ln in lines if ln.startswith(("•", "-", "*", "◦", "▪"))]
    if bullets:
        return bullets
    # Some PDF text extraction drops bullet glyphs entirely — fall back to
    # short, non-header lines as a proxy for "bullet points" in that case.
    return [ln for ln in lines if 25 <= len(ln) <= 200 and not ln.endswith(":")]


def score_resume_text(text: str, target_keywords: list[str] | None = None) -> AnalysisResult:
    words = re.findall(r"[A-Za-z']+", text)
    word_count = len(words)
    lower_text = text.lower()
    feedback = Feedback()

    # --- Formatting: length + section headers + contact info -------------
    lo, hi = _IDEAL_WORD_RANGE
    if word_count < _MIN_VIABLE_WORDS:
        length_score = 20
        feedback.weaknesses.append(f"Resume is very short ({word_count} words)")
        feedback.suggestions.append(
            "Add more detail to your experience and skills sections — "
            "most resumes read as too thin below ~120 words."
        )
    elif word_count < lo:
        length_score = 65
        feedback.suggestions.append("Consider expanding on your experience bullets a bit further.")
    elif word_count <= hi:
        length_score = 100
        feedback.strengths.append(f"Resume length is in a strong range ({word_count} words)")
    else:
        length_score = 70
        feedback.suggestions.append(
            f"Resume is on the long side ({word_count} words) — consider trimming to the most relevant content."
        )

    found_headers = [h for h in _SECTION_HEADERS if h in lower_text]
    header_score = round(100 * len(found_headers) / len(_SECTION_HEADERS))
    if header_score >= 70:
        feedback.strengths.append("Uses clear, standard section headers")
    else:
        missing = [h for h in _SECTION_HEADERS if h not in found_headers]
        feedback.weaknesses.append("Missing some standard section headers")
        feedback.suggestions.append(
            f"Add clearly labeled sections for: {', '.join(missing[:4])}"
        )

    has_email = bool(_EMAIL_RE.search(text))
    has_phone = bool(_PHONE_RE.search(text))
    contact_score = 100 if (has_email and has_phone) else (50 if (has_email or has_phone) else 0)
    if contact_score == 100:
        feedback.strengths.append("Contact information (email and phone) is present")
    else:
        feedback.weaknesses.append("Contact information looks incomplete")
        feedback.suggestions.append("Make sure both an email and a phone number appear near the top.")

    formatting = round(0.4 * length_score + 0.35 * header_score + 0.25 * contact_score)

    # --- Impact: action verbs + quantified results in bullets ------------
    bullets = _bullet_like_lines(text)
    if bullets:
        action_hits = sum(
            1 for b in bullets if b.lstrip("•-*◦▪ ").split(" ")[0].lower().strip(".,") in _ACTION_VERBS
        )
        quantified_hits = sum(1 for b in bullets if _DIGIT_RE.search(b))
        action_score = round(100 * action_hits / len(bullets))
        quantified_score = round(100 * quantified_hits / len(bullets))
    else:
        action_score = 0
        quantified_score = 0
        feedback.weaknesses.append("Couldn't detect distinct bullet points")
        feedback.suggestions.append("Use bullet points to describe your experience, one accomplishment per line.")

    if action_score >= 50:
        feedback.strengths.append("Bullets frequently open with strong action verbs")
    else:
        feedback.weaknesses.append("Few bullets open with a strong action verb")
        feedback.suggestions.append(
            "Start bullets with action verbs like 'built', 'led', 'improved', or 'reduced' rather than passive phrasing."
        )

    if quantified_score >= 40:
        feedback.strengths.append("Several bullets include measurable results")
    else:
        feedback.weaknesses.append("Few bullets include numbers or measurable impact")
        feedback.suggestions.append(
            "Quantify results where you can — e.g. 'reduced load time by 30%' instead of 'improved performance'."
        )

    impact = round(0.5 * action_score + 0.5 * quantified_score)

    # --- Keywords: against a target list if given, else a generic bank ---
    bank = [k.strip().lower() for k in target_keywords] if target_keywords else _GENERIC_KEYWORD_BANK
    bank = [k for k in bank if k]
    if bank:
        found_keywords = [k for k in bank if k in lower_text]
        missing_keywords = [k for k in bank if k not in found_keywords]
        keywords_score = round(100 * len(found_keywords) / len(bank))
    else:
        found_keywords, missing_keywords, keywords_score = [], [], 0

    feedback.missing_keywords = missing_keywords[:10]
    if keywords_score >= 60:
        feedback.strengths.append("Strong keyword coverage against the target list")
    elif bank:
        feedback.weaknesses.append("Low keyword coverage against the target list")
        if missing_keywords:
            feedback.suggestions.append(
                f"Consider working in relevant keywords such as: {', '.join(missing_keywords[:5])}"
            )

    overall = round(0.3 * formatting + 0.3 * keywords_score + 0.4 * impact)

    return AnalysisResult(
        score=ScoreBreakdown(
            overall=overall, formatting=formatting, keywords=keywords_score, impact=impact
        ),
        feedback=feedback,
        word_count=word_count,
    )
