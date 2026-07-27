from fastapi import APIRouter

from app.api.v1.endpoints import ai, auth, resumes, users

api_router = APIRouter()
api_router.include_router(auth.router)
api_router.include_router(users.router)
api_router.include_router(resumes.router)
api_router.include_router(ai.router)

# Reserved for upcoming phases:
# api_router.include_router(ats.router)
# api_router.include_router(portfolio.router)
# api_router.include_router(interview.router)
# api_router.include_router(analytics.router)
