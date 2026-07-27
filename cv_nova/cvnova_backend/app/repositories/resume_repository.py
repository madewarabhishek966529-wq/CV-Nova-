import uuid

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.resume import Resume


class ResumeRepository:
    def __init__(self, session: AsyncSession):
        self._session = session

    async def list_for_user(self, user_id: uuid.UUID) -> list[Resume]:
        result = await self._session.execute(
            select(Resume).where(Resume.user_id == user_id).order_by(Resume.updated_at.desc())
        )
        return list(result.scalars().all())

    async def get(self, resume_id: uuid.UUID) -> Resume | None:
        return await self._session.get(Resume, resume_id)

    async def create(self, *, user_id: uuid.UUID, title: str, template: str) -> Resume:
        resume = Resume(user_id=user_id, title=title, template=template)
        self._session.add(resume)
        await self._session.flush()
        await self._session.refresh(resume)
        return resume

    async def save(self, resume: Resume) -> Resume:
        await self._session.flush()
        await self._session.refresh(resume)
        return resume

    async def delete(self, resume: Resume) -> None:
        await self._session.delete(resume)
        await self._session.flush()

    async def count_for_user(self, user_id: uuid.UUID) -> int:
        resumes = await self.list_for_user(user_id)
        return len(resumes)
