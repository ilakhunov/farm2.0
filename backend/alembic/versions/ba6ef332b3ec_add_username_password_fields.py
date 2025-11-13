"""add username password fields

Revision ID: ba6ef332b3ec
Revises: fix_deliverystatus_enum_values_to_lowercase
Create Date: 2025-11-13 18:21:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'ba6ef332b3ec'
down_revision: Union[str, None] = 'fix_deliverystatus_lowercase'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # Add username column (nullable, unique)
    op.add_column('users', sa.Column('username', sa.String(length=64), nullable=True))
    op.create_unique_constraint('uq_users_username', 'users', ['username'])
    
    # Add password_hash column (nullable)
    op.add_column('users', sa.Column('password_hash', sa.String(length=255), nullable=True))


def downgrade() -> None:
    # Remove columns
    op.drop_constraint('uq_users_username', 'users', type_='unique')
    op.drop_column('users', 'password_hash')
    op.drop_column('users', 'username')
