"""Database utility functions."""
from __future__ import annotations

from datetime import UTC, datetime


def utcnow() -> datetime:
    """Get current UTC datetime (timezone-aware)."""
    return datetime.now(UTC)

