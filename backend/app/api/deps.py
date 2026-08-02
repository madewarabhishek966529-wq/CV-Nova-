import uuid
from typing import Annotated

from fastapi import Depends
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession

from app.database.session import get_db
from app.models.user import User
from app.repositories.user_repository import UserRepository

DbSession = Annotated[AsyncSession, Depends(get_db)]

# CVNova runs as a single-user local app: no login, no signup, no tokens,
# no session — every request is implicitly "the" user. This fixed id is
# the anchor. The first request the app ever receives auto-provisions this
# one row in `users`; every request after that just fetches it. Keeping a
# real row (rather than stripping user_id off Resume entirely) means the
# existing ownership-scoped schema and service layer didn't need to change
# at all — only where "the current user" comes from changed.
LOCAL_USER_ID = uuid.UUID("00000000-0000-0000-0000-000000000001")
_LOCAL_USER_EMAIL = "local@cvnova.app"
_LOCAL_USER_NAME = "Me"


async def get_current_user(db: DbSession) -> User:
    repo = UserRepository(db)
    user = await repo.get_by_id(LOCAL_USER_ID)
    if user is not None:
        return user

    # Not there yet — provision it. hashed_password is a placeholder that's
    # never checked against anything; the column only exists because the
    # user table predates single-user mode and other rows' FKs point at it.
    user = User(
        id=LOCAL_USER_ID,
        email=_LOCAL_USER_EMAIL,
        hashed_password="!disabled!",
        full_name=_LOCAL_USER_NAME,
    )
    db.add(user)
    try:
        await db.commit()
        await db.refresh(user)
        return user
    except IntegrityError:
        # Lost a first-request race to another concurrent request — that's
        # fine, it already created the row. Roll back and fetch it.
        await db.rollback()
        existing = await repo.get_by_id(LOCAL_USER_ID)
        assert existing is not None
        return existing


CurrentUser = Annotated[User, Depends(get_current_user)]
