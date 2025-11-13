"""Fix productcategory enum values to lowercase

Revision ID: fix_productcategory_lowercase
Revises: a3ecf158d3e0
Create Date: 2025-11-13 16:10:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'fix_productcategory_lowercase'
down_revision: Union[str, None] = 'a3ecf158d3e0'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # Change enum values from uppercase to lowercase for productcategory
    op.execute("ALTER TABLE products ALTER COLUMN category TYPE text")
    op.execute("DROP TYPE productcategory")
    op.execute("CREATE TYPE productcategory AS ENUM ('vegetables', 'fruits', 'grains', 'dairy', 'meat', 'other')")
    op.execute("UPDATE products SET category = LOWER(category) WHERE category IS NOT NULL")
    op.execute("ALTER TABLE products ALTER COLUMN category TYPE productcategory USING category::productcategory")


def downgrade() -> None:
    # Revert to uppercase enum values
    op.execute("ALTER TABLE products ALTER COLUMN category TYPE text")
    op.execute("DROP TYPE productcategory")
    op.execute("CREATE TYPE productcategory AS ENUM ('VEGETABLES', 'FRUITS', 'GRAINS', 'DAIRY', 'MEAT', 'OTHER')")
    op.execute("UPDATE products SET category = UPPER(category) WHERE category IS NOT NULL")
    op.execute("ALTER TABLE products ALTER COLUMN category TYPE productcategory USING category::productcategory")

