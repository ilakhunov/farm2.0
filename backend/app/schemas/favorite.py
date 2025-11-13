from __future__ import annotations

from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, ConfigDict

from app.schemas.product import ProductResponse


class FavoriteCreate(BaseModel):
    product_id: UUID


class FavoriteResponse(BaseModel):
    id: UUID
    user_id: UUID
    product_id: UUID
    product: ProductResponse | None = None
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)

