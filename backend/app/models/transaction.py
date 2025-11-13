from __future__ import annotations

import enum
import uuid
from datetime import datetime

from sqlalchemy import Enum, ForeignKey, Numeric, String
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.session import Base
from app.db.utils import utcnow


class PaymentProvider(str, enum.Enum):
    PAYME = "payme"
    CLICK = "click"
    ARCA = "arca"


class TransactionStatus(str, enum.Enum):
    PENDING = "pending"
    COMPLETED = "completed"
    FAILED = "failed"
    CANCELLED = "cancelled"
    REFUNDED = "refunded"


class Transaction(Base):
    __tablename__ = "transactions"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    order_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("orders.id", ondelete="CASCADE"), nullable=False)
    amount: Mapped[float] = mapped_column(Numeric(10, 2), nullable=False)
    provider: Mapped[PaymentProvider] = mapped_column(Enum(PaymentProvider, values_callable=lambda obj: [e.value for e in obj]), nullable=False)
    status: Mapped[TransactionStatus] = mapped_column(Enum(TransactionStatus, values_callable=lambda obj: [e.value for e in obj]), default=TransactionStatus.PENDING, nullable=False)
    external_id: Mapped[str | None] = mapped_column(String(255), nullable=True)  # ID from payment provider
    payment_method: Mapped[str | None] = mapped_column(String(64), nullable=True)
    payment_metadata: Mapped[str | None] = mapped_column(String(2000), nullable=True)  # JSON string for additional data
    created_at: Mapped[datetime] = mapped_column(default=utcnow, nullable=False)
    updated_at: Mapped[datetime] = mapped_column(default=utcnow, onupdate=utcnow, nullable=False)

    order = relationship("Order", backref="transactions")
