"""Fix orderstatus enum values to lowercase

Revision ID: fix_orderstatus_lowercase
Revises: fix_productcategory_lowercase
Create Date: 2025-11-13 16:15:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'fix_orderstatus_lowercase'
down_revision: Union[str, None] = 'fix_productcategory_lowercase'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # Change enum values from uppercase to lowercase for orderstatus
    op.execute("ALTER TABLE orders ALTER COLUMN status TYPE text")
    op.execute("DROP TYPE orderstatus")
    op.execute("CREATE TYPE orderstatus AS ENUM ('pending', 'confirmed', 'processing', 'shipped', 'delivered', 'cancelled')")
    op.execute("UPDATE orders SET status = LOWER(status) WHERE status IS NOT NULL")
    op.execute("ALTER TABLE orders ALTER COLUMN status TYPE orderstatus USING status::orderstatus")


def downgrade() -> None:
    # Revert to uppercase enum values
    op.execute("ALTER TABLE orders ALTER COLUMN status TYPE text")
    op.execute("DROP TYPE orderstatus")
    op.execute("CREATE TYPE orderstatus AS ENUM ('PENDING', 'CONFIRMED', 'PROCESSING', 'SHIPPED', 'DELIVERED', 'CANCELLED')")
    op.execute("UPDATE orders SET status = UPPER(status) WHERE status IS NOT NULL")
    op.execute("ALTER TABLE orders ALTER COLUMN status TYPE orderstatus USING status::orderstatus")

