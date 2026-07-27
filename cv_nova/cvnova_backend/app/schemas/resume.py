import uuid
from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field, field_validator

from app.models.resume import SECTION_KEYS
from app.schemas.resume_sections import (
    AchievementItem,
    CertificationItem,
    CustomSection,
    EducationItem,
    ExperienceItem,
    LanguageItem,
    LinkItem,
    PersonalInfo,
    ProjectItem,
    ReferenceItem,
)


class ResumeBase(BaseModel):
    title: str = Field(default="Untitled Resume", min_length=1, max_length=150)
    template: str = "modern"
    theme_color: str = "#4A3AFF"
    font: str = "inter"
    is_primary: bool = False

    photo_url: str | None = None
    headline: str | None = Field(default=None, max_length=200)
    professional_summary: str | None = None
    personal_info: PersonalInfo = Field(default_factory=PersonalInfo)

    experience: list[ExperienceItem] = Field(default_factory=list)
    projects: list[ProjectItem] = Field(default_factory=list)
    education: list[EducationItem] = Field(default_factory=list)
    certifications: list[CertificationItem] = Field(default_factory=list)
    achievements: list[AchievementItem] = Field(default_factory=list)
    skills: list[str] = Field(default_factory=list)
    languages: list[LanguageItem] = Field(default_factory=list)
    interests: list[str] = Field(default_factory=list)
    references: list[ReferenceItem] = Field(default_factory=list)
    links: list[LinkItem] = Field(default_factory=list)
    custom_sections: list[CustomSection] = Field(default_factory=list)

    section_order: list[str] = Field(default_factory=lambda: list(SECTION_KEYS))
    hidden_sections: list[str] = Field(default_factory=list)

    @field_validator("section_order")
    @classmethod
    def _validate_section_order(cls, value: list[str]) -> list[str]:
        unknown = set(value) - set(SECTION_KEYS)
        if unknown:
            raise ValueError(f"Unknown section key(s): {sorted(unknown)}")
        return value

    @field_validator("hidden_sections")
    @classmethod
    def _validate_hidden_sections(cls, value: list[str]) -> list[str]:
        unknown = set(value) - set(SECTION_KEYS)
        if unknown:
            raise ValueError(f"Unknown section key(s): {sorted(unknown)}")
        return value


class ResumeCreate(BaseModel):
    """Only `title` is required on creation — everything else defaults to
    an empty resume that the editor fills in incrementally with autosave."""
    title: str = Field(default="Untitled Resume", min_length=1, max_length=150)
    template: str = "modern"


class ResumeUpdate(ResumeBase):
    """Full-document replace, used by autosave. The editor always sends the
    complete current state rather than a diff — simpler client logic, and
    the payload is small enough (single resume, not a whole account) that
    this isn't a performance concern."""
    pass


class ResumeRead(ResumeBase):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    user_id: uuid.UUID
    created_at: datetime
    updated_at: datetime


class ResumeSummary(BaseModel):
    """Lightweight shape for the resume list screen — avoids shipping every
    section's full content just to render a list of cards."""
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    title: str
    template: str
    theme_color: str
    is_primary: bool
    headline: str | None
    updated_at: datetime
