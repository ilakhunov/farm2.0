from __future__ import annotations

from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field

from app.models.rating import RatingType


class RatingCreate(BaseModel):
    rating_type: RatingType
    product_id: UUID | None = None
    seller_id: UUID | None = None
    rating: int = Field(..., ge=1, le=5)
    comment: str | None = None
    images: list[str] | None = None


class RatingUpdate(BaseModel):
    rating: int | None = Field(None, ge=1, le=5)
    comment: str | None = None
    images: list[str] | None = None


class RatingReply(BaseModel):
    reply: str = Field(..., min_length=1)


class RatingResponse(BaseModel):
    id: UUID
    user_id: UUID
    rating_type: RatingType
    product_id: UUID | None = None
    seller_id: UUID | None = None
    rating: int
    comment: str | None = None
    images: list[str] | None = None
    is_approved: bool
    reply: str | None = None
    replied_at: datetime | None = None
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)


class RatingStats(BaseModel):
    average_rating: float
    total_ratings: int
    rating_distribution: dict[int, int]  # {1: count, 2: count, ...}

