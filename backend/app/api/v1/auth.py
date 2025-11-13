from __future__ import annotations

import random
from datetime import datetime, timedelta

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import get_settings
from app.core.security import create_token
from app.db.session import get_db
from app.models.otp import PhoneOTP
from app.models.user import EntityType, User, UserRole
from app.schemas.auth import (
    AuthResponse,
    SendOTPRequest,
    TokenResponse,
    UserProfile,
    VerifyOTPRequest,
)
from app.services.sms import get_sms_provider
from app.utils.phone import normalize_phone_number

router = APIRouter(prefix="/auth", tags=["auth"])


@router.post("/send-otp", status_code=status.HTTP_202_ACCEPTED)
async def send_otp(payload: SendOTPRequest, db: AsyncSession = Depends(get_db)) -> dict[str, object]:
    settings = get_settings()
    try:
        normalized_phone = normalize_phone_number(payload.phone_number)
    except ValueError as exc:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(exc)) from exc

    stmt = (
        select(PhoneOTP)
        .where(PhoneOTP.phone_number == normalized_phone)
        .order_by(PhoneOTP.created_at.desc())
        .limit(1)
    )
    result = await db.execute(stmt)
    existing_otp = result.scalar_one_or_none()
    now = datetime.utcnow()
    if existing_otp and (now - existing_otp.created_at).total_seconds() < settings.otp_resend_interval_seconds:
        raise HTTPException(status_code=status.HTTP_429_TOO_MANY_REQUESTS, detail="OTP recently sent. Try again later.")

    code = f"{random.randint(0, 999999):06d}"
    otp = PhoneOTP(
        phone_number=normalized_phone,
        code=code,
        expires_at=now + timedelta(minutes=settings.otp_expiration_minutes),
        max_attempts=settings.otp_attempt_limit,
    )
    db.add(otp)
    await db.commit()

    sms_provider = get_sms_provider()
    await sms_provider.send_code(phone_number=normalized_phone, code=code)

    response: dict[str, object] = {"message": "OTP sent"}
    if settings.sms_provider == "dev" or settings.sms_debug_echo:
        response["debug"] = {"otp": code}

    return response


@router.post("/verify-otp", response_model=AuthResponse)
async def verify_otp(payload: VerifyOTPRequest, db: AsyncSession = Depends(get_db)) -> AuthResponse:
    settings = get_settings()
    try:
        normalized_phone = normalize_phone_number(payload.phone_number)
    except ValueError as exc:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(exc)) from exc

    stmt = (
        select(PhoneOTP)
        .where(PhoneOTP.phone_number == normalized_phone)
        .order_by(PhoneOTP.created_at.desc())
        .limit(1)
    )
    result = await db.execute(stmt)
    otp = result.scalar_one_or_none()
    if not otp:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="OTP not found")

    now = datetime.utcnow()
    if otp.expires_at < now:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="OTP expired")
    if otp.attempts >= otp.max_attempts:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="OTP attempt limit exceeded")

    if otp.code != payload.code:
        otp.attempts += 1
        await db.commit()
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid OTP code")

    user_stmt = select(User).where(User.phone_number == normalized_phone)
    user_result = await db.execute(user_stmt)
    user = user_result.scalar_one_or_none()

    if user is None:
        if payload.role is None:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Role is required for new users")
        user = User(
            phone_number=normalized_phone,
            role=payload.role,
            entity_type=_resolve_entity_type(payload),
            tax_id=payload.tax_id,
            legal_name=payload.legal_name,
            legal_address=payload.legal_address,
            bank_account=payload.bank_account,
            email=payload.email,
            is_verified=False,
        )
        db.add(user)
    else:
        if payload.role and payload.role != user.role:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Role mismatch")
        _update_user_metadata(user, payload)

    db.delete(otp)
    await db.commit()
    await db.refresh(user)

    access_token = create_token(
        subject=str(user.id),
        expires_delta=timedelta(minutes=settings.access_token_expire_minutes),
    )
    refresh_token = create_token(
        subject=str(user.id),
        expires_delta=timedelta(minutes=settings.refresh_token_expire_minutes),
    )

    return AuthResponse(
        token=TokenResponse(
            access_token=access_token,
            refresh_token=refresh_token,
            expires_in=settings.access_token_expire_minutes * 60,
            refresh_expires_in=settings.refresh_token_expire_minutes * 60,
        ),
        user=_map_user_profile(user),
    )


def _resolve_entity_type(payload: VerifyOTPRequest) -> EntityType | None:
    # EntityType doesn't have FARMER value, return None or payload.entity_type
    return payload.entity_type


def _update_user_metadata(user: User, payload: VerifyOTPRequest) -> None:
    if payload.entity_type:
        user.entity_type = payload.entity_type
    if payload.tax_id:
        user.tax_id = payload.tax_id
    if payload.legal_name:
        user.legal_name = payload.legal_name
    if payload.legal_address:
        user.legal_address = payload.legal_address
    if payload.bank_account:
        user.bank_account = payload.bank_account
    if payload.email:
        user.email = payload.email


def _map_user_profile(user: User) -> UserProfile:
    return UserProfile(
        id=str(user.id),
        phone_number=user.phone_number,
        role=user.role,
        entity_type=user.entity_type,
        tax_id=user.tax_id,
        legal_name=user.legal_name,
        legal_address=user.legal_address,
        bank_account=user.bank_account,
        email=user.email,
        is_verified=user.is_verified,
        created_at=user.created_at,
        updated_at=user.updated_at,
    )
