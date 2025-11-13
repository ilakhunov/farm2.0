"""Fix userrole enum values to lowercase

Revision ID: a85bf57fa344
Revises: 96566c5df4f7
Create Date: 2025-11-13 15:46:46.391708

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'a85bf57fa344'
down_revision: Union[str, None] = '96566c5df4f7'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # Change enum values from uppercase to lowercase
    # PostgreSQL doesn't support ALTER TYPE to rename enum values directly,
    # so we need to recreate the enum with new values
    
    # First, alter the column to use text temporarily
    op.execute("ALTER TABLE users ALTER COLUMN role TYPE text")
    
    # Drop the old enum
    op.execute("DROP TYPE userrole")
    
    # Create new enum with lowercase values
    op.execute("CREATE TYPE userrole AS ENUM ('farmer', 'shop', 'admin')")
    
    # Update existing data to lowercase
    op.execute("UPDATE users SET role = LOWER(role)")
    
    # Change column back to enum type
    op.execute("ALTER TABLE users ALTER COLUMN role TYPE userrole USING role::userrole")


def downgrade() -> None:
    # Revert to uppercase enum values
    op.execute("ALTER TABLE users ALTER COLUMN role TYPE text")
    op.execute("DROP TYPE userrole")
    op.execute("CREATE TYPE userrole AS ENUM ('FARMER', 'SHOP', 'ADMIN')")
    op.execute("UPDATE users SET role = UPPER(role)")
    op.execute("ALTER TABLE users ALTER COLUMN role TYPE userrole USING role::userrole")
