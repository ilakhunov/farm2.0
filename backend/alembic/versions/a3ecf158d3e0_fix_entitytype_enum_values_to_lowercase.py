"""Fix entitytype enum values to lowercase

Revision ID: a3ecf158d3e0
Revises: a85bf57fa344
Create Date: 2025-11-13 15:48:06.373909

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'a3ecf158d3e0'
down_revision: Union[str, None] = 'a85bf57fa344'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # Change enum values from uppercase to lowercase for entitytype
    op.execute("ALTER TABLE users ALTER COLUMN entity_type TYPE text")
    op.execute("DROP TYPE entitytype")
    op.execute("CREATE TYPE entitytype AS ENUM ('legal_entity', 'sole_proprietor', 'self_employed', 'farmer')")
    op.execute("UPDATE users SET entity_type = LOWER(entity_type) WHERE entity_type IS NOT NULL")
    op.execute("ALTER TABLE users ALTER COLUMN entity_type TYPE entitytype USING entity_type::entitytype")


def downgrade() -> None:
    # Revert to uppercase enum values
    op.execute("ALTER TABLE users ALTER COLUMN entity_type TYPE text")
    op.execute("DROP TYPE entitytype")
    op.execute("CREATE TYPE entitytype AS ENUM ('LEGAL_ENTITY', 'SOLE_PROPRIETOR', 'SELF_EMPLOYED', 'FARMER')")
    op.execute("UPDATE users SET entity_type = UPPER(entity_type) WHERE entity_type IS NOT NULL")
    op.execute("ALTER TABLE users ALTER COLUMN entity_type TYPE entitytype USING entity_type::entitytype")
