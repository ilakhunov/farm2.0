from __future__ import annotations

from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, Field

from app.models.product import ProductCategory


class ProductBase(BaseModel):
    name: str = Field(..., min_length=1, max_length=255)
    description: str | None = None
    category: ProductCategory
    price: float = Field(..., gt=0)
    quantity: float = Field(..., ge=0)
    unit: str = Field(default="kg", max_length=32)
    image_url: str | None = None


class ProductCreate(ProductBase):
    pass


class ProductUpdate(BaseModel):
    name: str | None = Field(None, min_length=1, max_length=255)
    description: str | None = None
    category: ProductCategory | None = None
    price: float | None = Field(None, gt=0)
    quantity: float | None = Field(None, ge=0)
    unit: str | None = Field(None, max_length=32)
    image_url: str | None = None
    is_active: bool | None = None


class ProductResponse(ProductBase):
    id: UUID
    farmer_id: UUID
    is_active: bool
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


class ProductListResponse(BaseModel):
    items: list[ProductResponse]
    total: int
