from __future__ import annotations

from datetime import datetime, timedelta
from typing import Any

from jose import JWTError, jwt

from app.core.config import get_settings

ALGORITHM = "HS256"


def create_token(*, subject: str, expires_delta: timedelta) -> str:
    settings = get_settings()
    payload: dict[str, Any] = {
        "sub": subject,
        "exp": datetime.utcnow() + expires_delta,
        "iat": datetime.utcnow(),
    }
    return jwt.encode(payload, settings.secret_key, algorithm=ALGORITHM)


def decode_token(token: str) -> dict[str, Any]:
    settings = get_settings()
    try:
        return jwt.decode(token, settings.secret_key, algorithms=[ALGORITHM])
    except JWTError as exc:
        raise ValueError("Invalid token") from exc
