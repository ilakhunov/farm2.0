from __future__ import annotations

import enum
import uuid
from datetime import datetime

from sqlalchemy import Enum, ForeignKey, Integer, Text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.session import Base
from app.db.utils import utcnow


class RatingType(str, enum.Enum):
    PRODUCT = "product"
    SELLER = "seller"


class Rating(Base):
    """Модель для рейтингов и отзывов товаров и продавцов"""
    __tablename__ = "ratings"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    rating_type: Mapped[RatingType] = mapped_column(Enum(RatingType, values_callable=lambda obj: [e.value for e in obj]), nullable=False)
    
    # Для рейтинга товара
    product_id: Mapped[uuid.UUID | None] = mapped_column(UUID(as_uuid=True), ForeignKey("products.id", ondelete="CASCADE"), nullable=True)
    
    # Для рейтинга продавца
    seller_id: Mapped[uuid.UUID | None] = mapped_column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=True)
    
    rating: Mapped[int] = mapped_column(Integer, nullable=False)  # 1-5
    comment: Mapped[str | None] = mapped_column(Text, nullable=True)
    images: Mapped[list[str] | None] = mapped_column(Text, nullable=True)  # JSON array of image URLs
    
    # Модерация
    is_approved: Mapped[bool] = mapped_column(default=False, nullable=False)
    moderated_by: Mapped[uuid.UUID | None] = mapped_column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="SET NULL"), nullable=True)
    moderated_at: Mapped[datetime | None] = mapped_column(nullable=True)
    
    # Ответ продавца
    reply: Mapped[str | None] = mapped_column(Text, nullable=True)
    replied_at: Mapped[datetime | None] = mapped_column(nullable=True)
    
    created_at: Mapped[datetime] = mapped_column(default=utcnow, nullable=False)
    updated_at: Mapped[datetime] = mapped_column(default=utcnow, onupdate=utcnow, nullable=False)

    user = relationship("User", foreign_keys=[user_id], backref="ratings_given")
    product = relationship("Product", backref="ratings")
    seller = relationship("User", foreign_keys=[seller_id], backref="ratings_received")
    moderator = relationship("User", foreign_keys=[moderated_by])

