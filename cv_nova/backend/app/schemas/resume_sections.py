"""Schemas for the repeatable resume sections. Each item carries a client-
generated `id` (string) so the Flutter drag-and-drop editor can reorder,
edit, and delete items locally without round-tripping to the server for an
id — the server trusts client-generated ids within a resume the user owns.
"""
from pydantic import BaseModel, Field


class PersonalInfo(BaseModel):
    full_name: str = ""
    email: str = ""
    phone: str = ""
    location: str = ""
    website: str = ""


class ExperienceItem(BaseModel):
    id: str
    company: str
    role: str
    location: str = ""
    start_date: str = ""  # ISO "YYYY-MM" — kept as string for "Present" support
    end_date: str = ""
    is_current: bool = False
    bullets: list[str] = Field(default_factory=list)


class EducationItem(BaseModel):
    id: str
    institution: str
    degree: str
    field_of_study: str = ""
    start_date: str = ""
    end_date: str = ""
    grade: str = ""
    description: str = ""


class ProjectItem(BaseModel):
    id: str
    name: str
    description: str = ""
    tech_stack: list[str] = Field(default_factory=list)
    link: str = ""
    bullets: list[str] = Field(default_factory=list)


class CertificationItem(BaseModel):
    id: str
    name: str
    issuer: str = ""
    issue_date: str = ""
    expiry_date: str = ""
    credential_url: str = ""


class AchievementItem(BaseModel):
    id: str
    title: str
    description: str = ""
    date: str = ""


class LanguageItem(BaseModel):
    id: str
    name: str
    proficiency: str = "conversational"  # basic | conversational | fluent | native


class ReferenceItem(BaseModel):
    id: str
    name: str
    relationship: str = ""
    contact: str = ""


class LinkItem(BaseModel):
    id: str
    label: str
    url: str


class CustomSection(BaseModel):
    id: str
    title: str
    content: list[str] = Field(default_factory=list)
