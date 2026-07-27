from app.ai.enums import ContentType, Tone

_TONE_GUIDANCE: dict[Tone, str] = {
    Tone.PROFESSIONAL: "Clear, polished, and businesslike. No slang, no exclamation points.",
    Tone.TECHNICAL: "Precise and specific. Favor concrete technologies, metrics, and outcomes over adjectives.",
    Tone.EXECUTIVE: "Confident and outcome-driven. Emphasize scope, leadership, and business impact.",
    Tone.CREATIVE: "Engaging and a little more personal, while staying credible for a resume — not gimmicky.",
    Tone.MINIMAL: "As few words as possible without losing meaning. Cut every word that isn't load-bearing.",
    Tone.STUDENT: "Approachable and honest about being early-career. Emphasize coursework, projects, and potential.",
}

_BASE_SYSTEM_PROMPT = (
    "You are a resume-writing assistant embedded in CVNova, a resume builder. "
    "You write only the requested resume content — no preamble, no explanation, "
    "no markdown formatting, no quotation marks around the output. "
    "Never invent facts, numbers, employers, or dates that are not given to you "
    "in the input; work only with what the user provided, and phrase it well."
)


def _context_lines(context: dict[str, str], keys: list[str]) -> str:
    """Render only the context keys that were actually provided, each as
    "Label: value" — keeps the prompt from listing empty fields, which
    tends to make small local models produce boilerplate about the blanks."""
    lines = []
    for key in keys:
        value = context.get(key, "").strip()
        if value:
            label = key.replace("_", " ").capitalize()
            lines.append(f"{label}: {value}")
    return "\n".join(lines)


# Each entry: (instruction, relevant context keys, default output-count hint)
_CONTENT_SPECS: dict[ContentType, tuple[str, list[str]]] = {
    ContentType.SUMMARY: (
        "Write a professional summary (2-4 sentences, one paragraph, no line "
        "breaks) for a resume, based on the details below.",
        ["role", "years_experience", "key_skills", "industry", "notes"],
    ),
    ContentType.CAREER_OBJECTIVE: (
        "Write a career objective statement (1-2 sentences) for a resume, "
        "based on the details below.",
        ["role", "goal", "notes"],
    ),
    ContentType.EXPERIENCE_BULLETS: (
        "Write resume bullet points describing this work experience, based on "
        "the raw notes below. Output one bullet per line, no bullet symbol or "
        "numbering — just the sentence. Start each bullet with a strong past-tense "
        "action verb. Include numbers/metrics only if they appear in the notes.",
        ["role", "company", "notes", "bullet_count"],
    ),
    ContentType.RESPONSIBILITIES: (
        "Write resume bullet points describing this role's day-to-day "
        "responsibilities, based on the notes below. One per line, no bullet "
        "symbol, start with a present or past-tense action verb as appropriate.",
        ["role", "company", "notes", "bullet_count"],
    ),
    ContentType.PROJECT_DESCRIPTION: (
        "Write a short project description (1-2 sentences) followed by bullet "
        "points of what was built/achieved, based on the notes below. Format: "
        "first line is the description, remaining lines are bullets (one per "
        "line, no bullet symbol).",
        ["project_name", "tech_stack", "notes", "bullet_count"],
    ),
    ContentType.ACHIEVEMENT: (
        "Write a one-sentence resume achievement statement based on the notes "
        "below. Lead with the outcome.",
        ["notes"],
    ),
    ContentType.TECHNICAL_SKILLS: (
        "Given this raw list/description of technical skills, output a cleaned-up "
        "comma-separated list of technical skills suitable for a resume's skills "
        "section. Standardize naming (e.g. 'react.js' -> 'React'), remove "
        "duplicates, do not add skills that weren't mentioned.",
        ["notes"],
    ),
    ContentType.SOFT_SKILLS: (
        "Given this description of how someone works, output a comma-separated "
        "list of 4-8 soft skills a resume reader would recognize (e.g. "
        "'Cross-functional collaboration', 'Stakeholder communication'). Base "
        "them only on what's described, don't invent unrelated ones.",
        ["notes"],
    ),
    ContentType.INTERNSHIP_DESCRIPTION: (
        "Write resume bullet points for this internship, based on the notes "
        "below. One per line, no bullet symbol, start with an action verb. "
        "It's fine and expected for an internship to sound early-career.",
        ["role", "company", "notes", "bullet_count"],
    ),
    ContentType.LEADERSHIP_DESCRIPTION: (
        "Write resume bullet points describing this leadership experience, "
        "based on the notes below. One per line, no bullet symbol, emphasize "
        "the people/scope led and the outcome.",
        ["role", "context", "notes", "bullet_count"],
    ),
    ContentType.CUSTOM_SECTION: (
        "Write resume content for a custom section titled per below, based on "
        "the notes. Output one line per bullet, no bullet symbol.",
        ["section_title", "notes"],
    ),
}


def build_prompt(content_type: ContentType, tone: Tone, context: dict[str, str]) -> tuple[str, str]:
    """Returns (system_prompt, user_prompt) for the Ollama request."""
    instruction, keys = _CONTENT_SPECS[content_type]
    tone_guidance = _TONE_GUIDANCE[tone]

    system_prompt = f"{_BASE_SYSTEM_PROMPT}\n\nTone: {tone.value} — {tone_guidance}"

    details = _context_lines(context, keys)
    bullet_count = context.get("bullet_count", "").strip()
    count_hint = f"\n\nWrite {bullet_count} bullet point(s)." if bullet_count else ""

    user_prompt = f"{instruction}{count_hint}\n\n{details}" if details else instruction

    return system_prompt, user_prompt
