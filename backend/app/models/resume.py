import uuid

from sqlalchemy import JSON, Boolean, ForeignKey, String, Text
from sqlalchemy.dialects.postgresql import JSONB, UUID
from sqlalchemy.orm import Mapped, mapped_column

from app.database.base import Base, TimestampMixin, new_uuid

# Portable JSON type: real JSONB on Postgres (indexable, efficient), plain
# JSON everywhere else (e.g. SQLite in tests). Use this instead of importing
# JSONB directly so the model stays testable without a Postgres instance.
PortableJSON = JSON().with_variant(JSONB, "postgresql")

# Section keys — the canonical vocabulary for section_order / hidden_sections.
# Kept here (not just in the frontend) so the backend can validate against it.
SECTION_KEYS = [
    "personal_info",
    "headline",
    "summary",
    "experience",
    "projects",
    "education",
    "certifications",
    "achievements",
    "skills",
    "languages",
    "interests",
    "references",
    "links",
    "custom_sections",
]


class Resume(TimestampMixin, Base):
    """A single resume document.

    Design note: singular fields (title, headline, summary, template...) are
    real columns. Repeatable sections (experience, education, projects, ...)
    are stored as JSONB arrays rather than normalized into their own tables.
    This is a deliberate tradeoff for a document-shaped, user-reordered,
    frequently-autosaved object — see backend README "Database schema" for
    the reasoning. Every JSONB field's shape is enforced at the API boundary
    by the corresponding Pydantic schema in app/schemas/resume.py, not by
    the database.
    """

    __tablename__ = "resumes"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=new_uuid)
    user_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), index=True, nullable=False
    )

    # Meta
    title: Mapped[str] = mapped_column(String(150), nullable=False, default="Untitled Resume")
    template: Mapped[str] = mapped_column(String(50), nullable=False, default="modern")
    theme_color: Mapped[str] = mapped_column(String(20), nullable=False, default="#4A3AFF")
    font: Mapped[str] = mapped_column(String(50), nullable=False, default="inter")
    is_primary: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)

    # Singular content
    photo_url: Mapped[str | None] = mapped_column(String(500), nullable=True)
    headline: Mapped[str | None] = mapped_column(String(200), nullable=True)
    professional_summary: Mapped[str | None] = mapped_column(Text, nullable=True)
    personal_info: Mapped[dict] = mapped_column(PortableJSON, nullable=False, default=dict)

    # Repeatable sections — each a JSON array; shape validated at API layer.
    experience: Mapped[list] = mapped_column(PortableJSON, nullable=False, default=list)
    projects: Mapped[list] = mapped_column(PortableJSON, nullable=False, default=list)
    education: Mapped[list] = mapped_column(PortableJSON, nullable=False, default=list)
    certifications: Mapped[list] = mapped_column(PortableJSON, nullable=False, default=list)
    achievements: Mapped[list] = mapped_column(PortableJSON, nullable=False, default=list)
    skills: Mapped[list] = mapped_column(PortableJSON, nullable=False, default=list)
    languages: Mapped[list] = mapped_column(PortableJSON, nullable=False, default=list)
    interests: Mapped[list] = mapped_column(PortableJSON, nullable=False, default=list)
    references: Mapped[list] = mapped_column(PortableJSON, nullable=False, default=list)
    links: Mapped[list] = mapped_column(PortableJSON, nullable=False, default=list)
    custom_sections: Mapped[list] = mapped_column(PortableJSON, nullable=False, default=list)

    # Layout state
    section_order: Mapped[list] = mapped_column(PortableJSON, nullable=False, default=lambda: list(SECTION_KEYS))
    hidden_sections: Mapped[list] = mapped_column(PortableJSON, nullable=False, default=list)

    def __repr__(self) -> str:
        return f"<Resume id={self.id} user_id={self.user_id} title={self.title!r}>"
