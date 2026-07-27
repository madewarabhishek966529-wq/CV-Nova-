from enum import StrEnum


class ContentType(StrEnum):
    """What kind of resume content to generate. Each maps to a distinct
    prompt template in prompts.py — see PROMPT_TEMPLATES."""

    SUMMARY = "summary"
    CAREER_OBJECTIVE = "career_objective"
    EXPERIENCE_BULLETS = "experience_bullets"
    RESPONSIBILITIES = "responsibilities"
    PROJECT_DESCRIPTION = "project_description"
    ACHIEVEMENT = "achievement"
    TECHNICAL_SKILLS = "technical_skills"
    SOFT_SKILLS = "soft_skills"
    INTERNSHIP_DESCRIPTION = "internship_description"
    LEADERSHIP_DESCRIPTION = "leadership_description"
    CUSTOM_SECTION = "custom_section"


class Tone(StrEnum):
    PROFESSIONAL = "professional"
    TECHNICAL = "technical"
    EXECUTIVE = "executive"
    CREATIVE = "creative"
    MINIMAL = "minimal"
    STUDENT = "student"
