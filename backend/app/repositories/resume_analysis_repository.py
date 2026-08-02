import uuid

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.resume_analysis import ResumeAnalysis


class ResumeAnalysisRepository:
    def __init__(self, session: AsyncSession):
        self._session = session

    async def create(
        self,
        *,
        user_id: uuid.UUID,
        filename: str,
        word_count: int,
        score: dict,
        feedback: dict,
        extracted_text: str,
    ) -> ResumeAnalysis:
        analysis = ResumeAnalysis(
            user_id=user_id,
            filename=filename,
            word_count=word_count,
            score=score,
            feedback=feedback,
            extracted_text=extracted_text,
        )
        self._session.add(analysis)
        await self._session.flush()
        await self._session.refresh(analysis)
        await self._session.commit()
        return analysis

    async def get_owned(self, analysis_id: uuid.UUID, user_id: uuid.UUID) -> ResumeAnalysis | None:
        analysis = await self._session.get(ResumeAnalysis, analysis_id)
        if analysis is None or analysis.user_id != user_id:
            return None
        return analysis

    async def list_for_user(self, user_id: uuid.UUID) -> list[ResumeAnalysis]:
        result = await self._session.execute(
            select(ResumeAnalysis)
            .where(ResumeAnalysis.user_id == user_id)
            .order_by(ResumeAnalysis.created_at.desc())
        )
        return list(result.scalars().all())

    async def get_latest_for_user(self, user_id: uuid.UUID) -> ResumeAnalysis | None:
        result = await self._session.execute(
            select(ResumeAnalysis)
            .where(ResumeAnalysis.user_id == user_id)
            .order_by(ResumeAnalysis.created_at.desc())
            .limit(1)
        )
        return result.scalars().first()
