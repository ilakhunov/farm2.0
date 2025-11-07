from __future__ import annotations

from datetime import datetime

from pydantic import BaseModel, Field

from app.models.user import EntityType, UserRole


class UserBase(BaseModel):
    phone_number: str
    role: UserRole
    entity_type: EntityType | None = None
    tax_id: str | None = None
    legal_name: str | None = None
    legal_address: str | None = None
    bank_account: str | None = None
    email: str | None = None
    is_verified: bool
    created_at: datetime
    updated_at: datetime


class UserUpdateRequest(BaseModel):
    entity_type: EntityType | None = None
    tax_id: str | None = Field(default=None, max_length=32)
    legal_name: str | None = Field(default=None, max_length=255)
    legal_address: str | None = Field(default=None, max_length=255)
    bank_account: str | None = Field(default=None, max_length=64)
    email: str | None = Field(default=None, max_length=255)


class UserResponse(UserBase):
    id: str
