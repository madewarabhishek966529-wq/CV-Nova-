import uuid

from sqlalchemy import ForeignKey, Integer, String, Text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column

from app.database.base import Base, TimestampMixin, new_uuid
from app.models.resume import PortableJSON


class ResumeAnalysis(TimestampMixin, Base):
    """One PDF-upload ATS analysis. Deliberately separate from `Resume` —
    this scores an arbitrary uploaded PDF (which may not correspond to any
    resume built in the app at all), so it isn't FK'd to a resume row.
    """

    __tablename__ = "resume_analyses"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=new_uuid)
    user_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), index=True, nullable=False
    )

    filename: Mapped[str] = mapped_column(String(255), nullable=False)
    word_count: Mapped[int] = mapped_column(Integer, nullable=False)

    # {"overall": int, "formatting": int, "keywords": int, "impact": int}
    score: Mapped[dict] = mapped_column(PortableJSON, nullable=False)
    # {"strengths": [...], "weaknesses": [...], "missing_keywords": [...], "suggestions": [...]}
    feedback: Mapped[dict] = mapped_column(PortableJSON, nullable=False)

    # Capped in the service layer before persisting — kept for reference /
    # potential re-scoring, not meant to store unbounded raw text.
    extracted_text: Mapped[str] = mapped_column(Text, nullable=False)
