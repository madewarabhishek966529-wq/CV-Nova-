import uuid

from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import (
    InvalidTokenError,
    TokenType,
    create_access_token,
    create_refresh_token,
    decode_token,
    hash_password,
    verify_password,
)
from app.models.user import User
from app.repositories.user_repository import UserRepository
from app.schemas.auth import Token
from app.schemas.user import UserCreate


class EmailAlreadyRegisteredError(Exception):
    pass


class InvalidCredentialsError(Exception):
    pass


class UserNotFoundError(Exception):
    pass


class AuthService:
    def __init__(self, session: AsyncSession):
        self._session = session
        self._users = UserRepository(session)

    async def signup(self, payload: UserCreate) -> tuple[User, Token]:
        existing = await self._users.get_by_email(payload.email)
        if existing is not None:
            raise EmailAlreadyRegisteredError(payload.email)

        user = await self._users.create(
            email=payload.email,
            hashed_password=hash_password(payload.password),
            full_name=payload.full_name,
        )
        await self._session.commit()

        return user, self._issue_tokens(user)

    async def login(self, email: str, password: str) -> tuple[User, Token]:
        user = await self._users.get_by_email(email)
        if user is None or not verify_password(password, user.hashed_password):
            raise InvalidCredentialsError()
        if not user.is_active:
            raise InvalidCredentialsError()

        return user, self._issue_tokens(user)

    async def refresh(self, refresh_token: str) -> Token:
        try:
            subject = decode_token(refresh_token, TokenType.REFRESH)
            user_id = uuid.UUID(subject)
        except (InvalidTokenError, ValueError) as exc:
            raise InvalidCredentialsError() from exc

        user = await self._users.get_by_id(user_id)
        if user is None or not user.is_active:
            raise UserNotFoundError()

        return self._issue_tokens(user)

    def _issue_tokens(self, user: User) -> Token:
        subject = str(user.id)
        return Token(
            access_token=create_access_token(subject),
            refresh_token=create_refresh_token(subject),
        )
