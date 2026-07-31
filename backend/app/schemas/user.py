import uuid
from datetime import datetime

from pydantic import BaseModel, ConfigDict, EmailStr, Field, field_validator

from app.models.user import UserRole


class UserCreate(BaseModel):
    email: EmailStr
    password: str = Field(min_length=8, max_length=128)
    full_name: str = Field(min_length=1, max_length=120)

    @field_validator("email")
    @classmethod
    def normalize_email(cls, value: str) -> str:
        # Emails are treated case-insensitively (as every real mailbox provider
        # does, whatever RFC 5321 technically allows). Normalizing here — the
        # one place every signup email passes through — means storage,
        # uniqueness checks, and login all agree on the same identity for an
        # address no matter how the user capitalized it.
        return value.strip().lower()


class UserRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    email: EmailStr
    full_name: str
    role: UserRole
    is_active: bool
    is_verified: bool
    created_at: datetime
