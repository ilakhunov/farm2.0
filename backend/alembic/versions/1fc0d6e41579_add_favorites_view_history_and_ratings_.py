"""Add favorites, view_history and ratings tables

Revision ID: 1fc0d6e41579
Revises: ba6ef332b3ec
Create Date: 2025-11-13 20:42:04.927795

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '1fc0d6e41579'
down_revision: Union[str, None] = 'ba6ef332b3ec'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # Create favorites table
    op.create_table(
        'favorites',
        sa.Column('id', sa.dialects.postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column('user_id', sa.dialects.postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('product_id', sa.dialects.postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('created_at', sa.DateTime(), nullable=False),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ondelete='CASCADE'),
        sa.ForeignKeyConstraint(['product_id'], ['products.id'], ondelete='CASCADE'),
    )
    op.create_index('ix_favorites_user_id', 'favorites', ['user_id'])
    op.create_index('ix_favorites_product_id', 'favorites', ['product_id'])
    op.create_unique_constraint('uq_favorites_user_product', 'favorites', ['user_id', 'product_id'])
    
    # Create view_history table
    op.create_table(
        'view_history',
        sa.Column('id', sa.dialects.postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column('user_id', sa.dialects.postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('product_id', sa.dialects.postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('viewed_at', sa.DateTime(), nullable=False),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ondelete='CASCADE'),
        sa.ForeignKeyConstraint(['product_id'], ['products.id'], ondelete='CASCADE'),
    )
    op.create_index('ix_view_history_user_id', 'view_history', ['user_id'])
    op.create_index('ix_view_history_product_id', 'view_history', ['product_id'])
    op.create_index('ix_view_history_viewed_at', 'view_history', ['viewed_at'])
    
    # Create ratings table
    op.create_table(
        'ratings',
        sa.Column('id', sa.dialects.postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column('user_id', sa.dialects.postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('rating_type', sa.Enum('product', 'seller', name='ratingtype'), nullable=False),
        sa.Column('product_id', sa.dialects.postgresql.UUID(as_uuid=True), nullable=True),
        sa.Column('seller_id', sa.dialects.postgresql.UUID(as_uuid=True), nullable=True),
        sa.Column('rating', sa.Integer(), nullable=False),
        sa.Column('comment', sa.Text(), nullable=True),
        sa.Column('images', sa.Text(), nullable=True),  # JSON array
        sa.Column('is_approved', sa.Boolean(), nullable=False, server_default='false'),
        sa.Column('moderated_by', sa.dialects.postgresql.UUID(as_uuid=True), nullable=True),
        sa.Column('moderated_at', sa.DateTime(), nullable=True),
        sa.Column('reply', sa.Text(), nullable=True),
        sa.Column('replied_at', sa.DateTime(), nullable=True),
        sa.Column('created_at', sa.DateTime(), nullable=False),
        sa.Column('updated_at', sa.DateTime(), nullable=False),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ondelete='CASCADE'),
        sa.ForeignKeyConstraint(['product_id'], ['products.id'], ondelete='CASCADE'),
        sa.ForeignKeyConstraint(['seller_id'], ['users.id'], ondelete='CASCADE'),
        sa.ForeignKeyConstraint(['moderated_by'], ['users.id'], ondelete='SET NULL'),
    )
    op.create_index('ix_ratings_user_id', 'ratings', ['user_id'])
    op.create_index('ix_ratings_product_id', 'ratings', ['product_id'])
    op.create_index('ix_ratings_seller_id', 'ratings', ['seller_id'])
    op.create_index('ix_ratings_rating_type', 'ratings', ['rating_type'])
    op.create_index('ix_ratings_is_approved', 'ratings', ['is_approved'])
    
    # Add image_urls column to products
    op.add_column('products', sa.Column('image_urls', sa.Text(), nullable=True))


def downgrade() -> None:
    op.drop_column('products', 'image_urls')
    op.drop_table('ratings')
    op.drop_table('view_history')
    op.drop_table('favorites')
    op.execute('DROP TYPE IF EXISTS ratingtype')
