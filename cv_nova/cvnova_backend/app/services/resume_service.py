import uuid

from sqlalchemy.ext.asyncio import AsyncSession

from app.models.resume import Resume
from app.repositories.resume_repository import ResumeRepository
from app.schemas.resume import ResumeCreate, ResumeUpdate


class ResumeNotFoundError(Exception):
    pass


class ResumeService:
    def __init__(self, session: AsyncSession):
        self._session = session
        self._resumes = ResumeRepository(session)

    async def list_resumes(self, user_id: uuid.UUID) -> list[Resume]:
        return await self._resumes.list_for_user(user_id)

    async def get_owned(self, resume_id: uuid.UUID, user_id: uuid.UUID) -> Resume:
        resume = await self._resumes.get(resume_id)
        if resume is None or resume.user_id != user_id:
            # 404, not 403 — don't reveal whether a resume id belongs to
            # someone else.
            raise ResumeNotFoundError()
        return resume

    async def create(self, user_id: uuid.UUID, payload: ResumeCreate) -> Resume:
        is_first = await self._resumes.count_for_user(user_id) == 0
        resume = await self._resumes.create(
            user_id=user_id, title=payload.title, template=payload.template
        )
        if is_first:
            resume.is_primary = True
            resume = await self._resumes.save(resume)
        await self._session.commit()
        await self._session.refresh(resume)
        return resume

    async def update(
        self, resume_id: uuid.UUID, user_id: uuid.UUID, payload: ResumeUpdate
    ) -> Resume:
        resume = await self.get_owned(resume_id, user_id)

        if payload.is_primary and not resume.is_primary:
            await self._unset_other_primaries(user_id, keep=resume_id)

        for field, value in payload.model_dump(mode="json").items():
            setattr(resume, field, value)

        resume = await self._resumes.save(resume)
        await self._session.commit()
        await self._session.refresh(resume)
        return resume

    async def delete(self, resume_id: uuid.UUID, user_id: uuid.UUID) -> None:
        resume = await self.get_owned(resume_id, user_id)
        was_primary = resume.is_primary
        await self._resumes.delete(resume)
        await self._session.commit()

        if was_primary:
            remaining = await self._resumes.list_for_user(user_id)
            if remaining:
                remaining[0].is_primary = True
                await self._resumes.save(remaining[0])
                await self._session.commit()

    async def duplicate(self, resume_id: uuid.UUID, user_id: uuid.UUID) -> Resume:
        original = await self.get_owned(resume_id, user_id)

        copy = Resume(
            user_id=user_id,
            title=f"{original.title} (Copy)",
            template=original.template,
            theme_color=original.theme_color,
            font=original.font,
            is_primary=False,
            photo_url=original.photo_url,
            headline=original.headline,
            professional_summary=original.professional_summary,
            personal_info=dict(original.personal_info),
            experience=list(original.experience),
            projects=list(original.projects),
            education=list(original.education),
            certifications=list(original.certifications),
            achievements=list(original.achievements),
            skills=list(original.skills),
            languages=list(original.languages),
            interests=list(original.interests),
            references=list(original.references),
            links=list(original.links),
            custom_sections=list(original.custom_sections),
            section_order=list(original.section_order),
            hidden_sections=list(original.hidden_sections),
        )
        self._session.add(copy)
        await self._session.commit()
        await self._session.refresh(copy)
        return copy

    async def _unset_other_primaries(self, user_id: uuid.UUID, keep: uuid.UUID) -> None:
        for resume in await self._resumes.list_for_user(user_id):
            if resume.id != keep and resume.is_primary:
                resume.is_primary = False
                await self._resumes.save(resume)
