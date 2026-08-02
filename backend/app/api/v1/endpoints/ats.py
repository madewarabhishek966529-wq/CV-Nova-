import uuid

from fastapi import APIRouter, File, Form, HTTPException, UploadFile, status

from app.api.deps import CurrentUser, DbSession
from app.schemas.resume_analysis import ResumeAnalysisRead, ResumeAnalysisSummary
from app.services.ats_service import (
    AnalysisNotFoundError,
    AtsService,
    NotAPdfError,
    UnreadablePdfError,
    UploadTooLargeError,
)

router = APIRouter(prefix="/ats", tags=["ats"])


@router.post("/analyze", response_model=ResumeAnalysisRead, status_code=status.HTTP_201_CREATED)
async def analyze_resume(
    current_user: CurrentUser,
    db: DbSession,
    file: UploadFile = File(...),
    # Comma-separated target keywords (e.g. from a job description) — optional.
    # Without it, scoring falls back to a generic keyword bank.
    target_keywords: str | None = Form(default=None),
):
    service = AtsService(db)
    keywords = [k.strip() for k in target_keywords.split(",")] if target_keywords else None
    file_bytes = await file.read()

    try:
        return await service.analyze(
            user_id=current_user.id,
            filename=file.filename or "resume.pdf",
            content_type=file.content_type,
            file_bytes=file_bytes,
            target_keywords=keywords,
        )
    except NotAPdfError as exc:
        raise HTTPException(status_code=status.HTTP_415_UNSUPPORTED_MEDIA_TYPE, detail=str(exc)) from exc
    except UploadTooLargeError as exc:
        raise HTTPException(status_code=status.HTTP_413_REQUEST_ENTITY_TOO_LARGE, detail=str(exc)) from exc
    except UnreadablePdfError as exc:
        raise HTTPException(status_code=status.HTTP_422_UNPROCESSABLE_ENTITY, detail=str(exc)) from exc


@router.get("/analyses", response_model=list[ResumeAnalysisSummary])
async def list_analyses(current_user: CurrentUser, db: DbSession):
    service = AtsService(db)
    return await service.list_analyses(current_user.id)


@router.get("/analyses/latest", response_model=ResumeAnalysisRead)
async def latest_analysis(current_user: CurrentUser, db: DbSession):
    service = AtsService(db)
    analysis = await service.get_latest(current_user.id)
    if analysis is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="No analyses yet")
    return analysis


@router.get("/analyses/{analysis_id}", response_model=ResumeAnalysisRead)
async def get_analysis(analysis_id: uuid.UUID, current_user: CurrentUser, db: DbSession):
    service = AtsService(db)
    try:
        return await service.get_owned(analysis_id, current_user.id)
    except AnalysisNotFoundError as exc:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Analysis not found") from exc
