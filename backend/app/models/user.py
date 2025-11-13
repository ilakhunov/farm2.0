from __future__ import annotations

import enum
import uuid
from datetime import datetime

from sqlalchemy import Boolean, Enum, String, UniqueConstraint
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column

from app.db.session import Base


class UserRole(str, enum.Enum):
    FARMER = "farmer"
    SHOP = "shop"
    ADMIN = "admin"


class EntityType(str, enum.Enum):
    LEGAL_ENTITY = "legal_entity"
    SOLE_PROPRIETOR = "sole_proprietor"
    SELF_EMPLOYED = "self_employed"
    FARMER = "farmer"


class User(Base):
    __tablename__ = "users"
    __table_args__ = (
        UniqueConstraint("phone_number", name="uq_users_phone_number"),
    )

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    phone_number: Mapped[str] = mapped_column(String(32), nullable=False)
    username: Mapped[str | None] = mapped_column(String(64), nullable=True, unique=True)
    password_hash: Mapped[str | None] = mapped_column(String(255), nullable=True)
    role: Mapped[UserRole] = mapped_column(Enum(UserRole, values_callable=lambda obj: [e.value for e in obj]), nullable=False)
    entity_type: Mapped[EntityType | None] = mapped_column(Enum(EntityType, values_callable=lambda obj: [e.value for e in obj]), nullable=True)
    tax_id: Mapped[str | None] = mapped_column(String(32))
    legal_name: Mapped[str | None] = mapped_column(String(255))
    legal_address: Mapped[str | None] = mapped_column(String(255))
    bank_account: Mapped[str | None] = mapped_column(String(64))
    email: Mapped[str | None] = mapped_column(String(255))
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)
    is_verified: Mapped[bool] = mapped_column(Boolean, default=False)
    created_at: Mapped[datetime] = mapped_column(default=datetime.utcnow, nullable=False)
    updated_at: Mapped[datetime] = mapped_column(default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False)
