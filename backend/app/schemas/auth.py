from __future__ import annotations

from datetime import datetime

from pydantic import BaseModel, Field

from app.models.user import EntityType, UserRole


class SendOTPRequest(BaseModel):
    phone_number: str = Field(..., min_length=9, max_length=32)
    role: UserRole | None = None
    entity_type: EntityType | None = None


class VerifyOTPRequest(BaseModel):
    phone_number: str = Field(..., min_length=9, max_length=32)
    code: str = Field(..., min_length=4, max_length=12)
    role: UserRole | None = None
    entity_type: EntityType | None = None
    tax_id: str | None = None
    legal_name: str | None = None
    legal_address: str | None = None
    bank_account: str | None = None
    email: str | None = None


class TokenResponse(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    expires_in: int
    refresh_expires_in: int


class UserProfile(BaseModel):
    id: str
    phone_number: str
    role: UserRole
    entity_type: EntityType | None
    tax_id: str | None
    legal_name: str | None
    legal_address: str | None
    bank_account: str | None
    email: str | None
    is_verified: bool
    created_at: datetime
    updated_at: datetime


class AuthResponse(BaseModel):
    token: TokenResponse
    user: UserProfile


class LogoutResponse(BaseModel):
    message: str = "Successfully logged out"
