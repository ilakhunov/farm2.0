from __future__ import annotations

from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, ConfigDict

from app.models.transaction import PaymentProvider, TransactionStatus


class TransactionResponse(BaseModel):
    id: UUID
    order_id: UUID
    amount: float
    provider: PaymentProvider
    status: TransactionStatus
    external_id: str | None
    payment_method: str | None
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)


class PaymentInitRequest(BaseModel):
    order_id: UUID
    provider: PaymentProvider


class PaymentInitResponse(BaseModel):
    transaction_id: UUID
    payment_url: str | None = None
    payment_data: dict | None = None  # Provider-specific data
