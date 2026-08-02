from fastapi import APIRouter

from app.api.v1.endpoints import ai, ats, resumes, users

api_router = APIRouter()
api_router.include_router(users.router)
api_router.include_router(resumes.router)
api_router.include_router(ai.router)
api_router.include_router(ats.router)

# Reserved for upcoming phases:
# api_router.include_router(ats.router)
# api_router.include_router(portfolio.router)
# api_router.include_router(interview.router)
# api_router.include_router(analytics.router)
