"""Import models here for Alembic autogeneration."""
from app.db.session import Base  # noqa: F401
from app.models import delivery, order, otp, product, transaction, user  # noqa: F401
