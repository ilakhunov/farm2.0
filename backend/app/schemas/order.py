from __future__ import annotations

from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, Field

from app.models.order import OrderStatus


class OrderItemCreate(BaseModel):
    product_id: UUID
    quantity: float = Field(..., gt=0)


class OrderItemResponse(BaseModel):
    id: UUID
    product_id: UUID
    quantity: float
    price: float
    created_at: datetime

    class Config:
        from_attributes = True


class OrderCreate(BaseModel):
    farmer_id: UUID
    items: list[OrderItemCreate] = Field(..., min_length=1)
    delivery_address: str | None = None
    notes: str | None = None


class OrderUpdate(BaseModel):
    status: OrderStatus | None = None
    delivery_address: str | None = None
    notes: str | None = None


class OrderResponse(BaseModel):
    id: UUID
    shop_id: UUID
    farmer_id: UUID
    status: OrderStatus
    total_amount: float
    delivery_address: str | None
    notes: str | None
    items: list[OrderItemResponse]
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


class OrderListResponse(BaseModel):
    items: list[OrderResponse]
    total: int
