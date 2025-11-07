from __future__ import annotations

from datetime import datetime
from uuid import UUID

from pydantic import BaseModel

from app.models.delivery import DeliveryStatus


class DeliveryResponse(BaseModel):
    id: UUID
    order_id: UUID
    status: DeliveryStatus
    delivery_address: str
    courier_name: str | None
    courier_phone: str | None
    tracking_number: str | None
    estimated_delivery: datetime | None
    delivered_at: datetime | None
    notes: str | None
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


class DeliveryUpdate(BaseModel):
    status: DeliveryStatus | None = None
    courier_name: str | None = None
    courier_phone: str | None = None
    tracking_number: str | None = None
    estimated_delivery: datetime | None = None
    notes: str | None = None
