import uuid

from fastapi import APIRouter, HTTPException, status

from app.api.deps import CurrentUser, DbSession
from app.schemas.resume import ResumeCreate, ResumeRead, ResumeSummary, ResumeUpdate
from app.services.resume_service import ResumeNotFoundError, ResumeService

router = APIRouter(prefix="/resumes", tags=["resumes"])


@router.get("", response_model=list[ResumeSummary])
async def list_resumes(current_user: CurrentUser, db: DbSession):
    service = ResumeService(db)
    return await service.list_resumes(current_user.id)


@router.post("", response_model=ResumeRead, status_code=status.HTTP_201_CREATED)
async def create_resume(payload: ResumeCreate, current_user: CurrentUser, db: DbSession):
    service = ResumeService(db)
    return await service.create(current_user.id, payload)


@router.get("/{resume_id}", response_model=ResumeRead)
async def get_resume(resume_id: uuid.UUID, current_user: CurrentUser, db: DbSession):
    service = ResumeService(db)
    try:
        return await service.get_owned(resume_id, current_user.id)
    except ResumeNotFoundError as exc:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Resume not found") from exc


@router.put("/{resume_id}", response_model=ResumeRead)
async def update_resume(
    resume_id: uuid.UUID, payload: ResumeUpdate, current_user: CurrentUser, db: DbSession
):
    """Full-document replace — the editor's autosave always sends complete
    current state. See ResumeUpdate docstring."""
    service = ResumeService(db)
    try:
        return await service.update(resume_id, current_user.id, payload)
    except ResumeNotFoundError as exc:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Resume not found") from exc


@router.delete("/{resume_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_resume(resume_id: uuid.UUID, current_user: CurrentUser, db: DbSession):
    service = ResumeService(db)
    try:
        await service.delete(resume_id, current_user.id)
    except ResumeNotFoundError as exc:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Resume not found") from exc


@router.post("/{resume_id}/duplicate", response_model=ResumeRead, status_code=status.HTTP_201_CREATED)
async def duplicate_resume(resume_id: uuid.UUID, current_user: CurrentUser, db: DbSession):
    service = ResumeService(db)
    try:
        return await service.duplicate(resume_id, current_user.id)
    except ResumeNotFoundError as exc:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Resume not found") from exc
