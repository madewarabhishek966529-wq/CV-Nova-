import uuid

from sqlalchemy.ext.asyncio import AsyncSession

from app.ats.pdf_extractor import UnreadablePdfError, extract_text
from app.ats.scorer import score_resume_text
from app.repositories.resume_analysis_repository import ResumeAnalysisRepository

MAX_UPLOAD_BYTES = 5 * 1024 * 1024  # 5MB — a text resume PDF is never anywhere near this
_STORED_TEXT_CAP = 20_000  # characters — plenty for display/re-scoring, bounds row size


class UploadTooLargeError(Exception):
    pass


class NotAPdfError(Exception):
    pass


class AnalysisNotFoundError(Exception):
    pass


class AtsService:
    def __init__(self, db: AsyncSession):
        self._db = db
        self._repo = ResumeAnalysisRepository(db)

    async def analyze(
        self,
        *,
        user_id: uuid.UUID,
        filename: str,
        content_type: str | None,
        file_bytes: bytes,
        target_keywords: list[str] | None = None,
    ):
        if content_type not in (None, "application/pdf") and not filename.lower().endswith(".pdf"):
            raise NotAPdfError("Only PDF files are supported")
        if len(file_bytes) > MAX_UPLOAD_BYTES:
            raise UploadTooLargeError(f"File exceeds the {MAX_UPLOAD_BYTES // (1024 * 1024)}MB limit")

        text = extract_text(file_bytes)  # raises UnreadablePdfError, left to the caller
        result = score_resume_text(text, target_keywords=target_keywords)

        return await self._repo.create(
            user_id=user_id,
            filename=filename,
            word_count=result.word_count,
            score=result.score.__dict__,
            feedback=result.feedback.__dict__,
            extracted_text=text[:_STORED_TEXT_CAP],
        )

    async def list_analyses(self, user_id: uuid.UUID):
        return await self._repo.list_for_user(user_id)

    async def get_latest(self, user_id: uuid.UUID):
        return await self._repo.get_latest_for_user(user_id)

    async def get_owned(self, analysis_id: uuid.UUID, user_id: uuid.UUID):
        analysis = await self._repo.get_owned(analysis_id, user_id)
        if analysis is None:
            raise AnalysisNotFoundError()
        return analysis


__all__ = [
    "AtsService",
    "UploadTooLargeError",
    "NotAPdfError",
    "AnalysisNotFoundError",
    "UnreadablePdfError",
]
