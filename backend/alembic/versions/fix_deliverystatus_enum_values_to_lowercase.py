"""Fix deliverystatus enum values to lowercase

Revision ID: fix_deliverystatus_lowercase
Revises: fix_orderstatus_lowercase
Create Date: 2025-11-13 16:16:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'fix_deliverystatus_lowercase'
down_revision: Union[str, None] = 'fix_orderstatus_lowercase'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # Change enum values from uppercase to lowercase for deliverystatus
    op.execute("ALTER TABLE deliveries ALTER COLUMN status TYPE text")
    op.execute("DROP TYPE deliverystatus")
    op.execute("CREATE TYPE deliverystatus AS ENUM ('pending', 'assigned', 'in_transit', 'delivered', 'failed', 'cancelled')")
    op.execute("UPDATE deliveries SET status = LOWER(status) WHERE status IS NOT NULL")
    op.execute("ALTER TABLE deliveries ALTER COLUMN status TYPE deliverystatus USING status::deliverystatus")


def downgrade() -> None:
    # Revert to uppercase enum values
    op.execute("ALTER TABLE deliveries ALTER COLUMN status TYPE text")
    op.execute("DROP TYPE deliverystatus")
    op.execute("CREATE TYPE deliverystatus AS ENUM ('PENDING', 'ASSIGNED', 'IN_TRANSIT', 'DELIVERED', 'FAILED', 'CANCELLED')")
    op.execute("UPDATE deliveries SET status = UPPER(status) WHERE status IS NOT NULL")
    op.execute("ALTER TABLE deliveries ALTER COLUMN status TYPE deliverystatus USING status::deliverystatus")

