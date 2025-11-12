"""Initial migration: all models

Revision ID: initial_001
Revises: 
Create Date: 2024-11-07

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

# revision identifiers, used by Alembic.
revision: str = 'initial_001'
down_revision: Union[str, None] = None
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # Create enum types
    op.execute("CREATE TYPE userrole AS ENUM ('farmer', 'shop', 'admin')")
    op.execute("CREATE TYPE entitytype AS ENUM ('legal_entity', 'sole_proprietor', 'self_employed', 'farmer')")
    op.execute("CREATE TYPE productcategory AS ENUM ('vegetables', 'fruits', 'grains', 'dairy', 'meat', 'other')")
    op.execute("CREATE TYPE orderstatus AS ENUM ('pending', 'confirmed', 'processing', 'shipped', 'delivered', 'cancelled')")
    op.execute("CREATE TYPE paymentprovider AS ENUM ('payme', 'click', 'arca')")
    op.execute("CREATE TYPE transactionstatus AS ENUM ('pending', 'completed', 'failed', 'cancelled', 'refunded')")
    op.execute("CREATE TYPE deliverystatus AS ENUM ('pending', 'assigned', 'in_transit', 'delivered', 'failed', 'cancelled')")

    # Create users table
    op.create_table(
        'users',
        sa.Column('id', postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column('phone_number', sa.String(32), nullable=False),
        sa.Column('role', postgresql.ENUM('farmer', 'shop', 'admin', name='userrole'), nullable=False),
        sa.Column('entity_type', postgresql.ENUM('legal_entity', 'sole_proprietor', 'self_employed', 'farmer', name='entitytype'), nullable=True),
        sa.Column('tax_id', sa.String(32), nullable=True),
        sa.Column('legal_name', sa.String(255), nullable=True),
        sa.Column('legal_address', sa.String(255), nullable=True),
        sa.Column('bank_account', sa.String(64), nullable=True),
        sa.Column('email', sa.String(255), nullable=True),
        sa.Column('is_active', sa.Boolean(), nullable=False, server_default='true'),
        sa.Column('is_verified', sa.Boolean(), nullable=False, server_default='false'),
        sa.Column('created_at', sa.DateTime(), nullable=False),
        sa.Column('updated_at', sa.DateTime(), nullable=False),
        sa.UniqueConstraint('phone_number', name='uq_users_phone_number')
    )

    # Create phone_otps table
    op.create_table(
        'phone_otps',
        sa.Column('id', postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column('phone_number', sa.String(32), nullable=False),
        sa.Column('code', sa.String(12), nullable=False),
        sa.Column('expires_at', sa.DateTime(), nullable=False),
        sa.Column('attempts', sa.Integer(), nullable=False, server_default='0'),
        sa.Column('max_attempts', sa.Integer(), nullable=False, server_default='5'),
        sa.Column('created_at', sa.DateTime(), nullable=False),
        sa.Column('user_id', postgresql.UUID(as_uuid=True), nullable=True),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ondelete='SET NULL')
    )

    # Create products table
    op.create_table(
        'products',
        sa.Column('id', postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column('farmer_id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('name', sa.String(255), nullable=False),
        sa.Column('description', sa.Text(), nullable=True),
        sa.Column('category', postgresql.ENUM('vegetables', 'fruits', 'grains', 'dairy', 'meat', 'other', name='productcategory'), nullable=False),
        sa.Column('price', sa.Numeric(10, 2), nullable=False),
        sa.Column('quantity', sa.Numeric(10, 2), nullable=False, server_default='0.0'),
        sa.Column('unit', sa.String(32), nullable=False, server_default='kg'),
        sa.Column('image_url', sa.String(512), nullable=True),
        sa.Column('is_active', sa.Boolean(), nullable=False, server_default='true'),
        sa.Column('created_at', sa.DateTime(), nullable=False),
        sa.Column('updated_at', sa.DateTime(), nullable=False),
        sa.ForeignKeyConstraint(['farmer_id'], ['users.id'], ondelete='CASCADE')
    )

    # Create orders table
    op.create_table(
        'orders',
        sa.Column('id', postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column('shop_id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('farmer_id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('status', postgresql.ENUM('pending', 'confirmed', 'processing', 'shipped', 'delivered', 'cancelled', name='orderstatus'), nullable=False, server_default='pending'),
        sa.Column('total_amount', sa.Numeric(10, 2), nullable=False, server_default='0.0'),
        sa.Column('delivery_address', sa.String(512), nullable=True),
        sa.Column('notes', sa.String(1000), nullable=True),
        sa.Column('created_at', sa.DateTime(), nullable=False),
        sa.Column('updated_at', sa.DateTime(), nullable=False),
        sa.ForeignKeyConstraint(['shop_id'], ['users.id'], ondelete='CASCADE'),
        sa.ForeignKeyConstraint(['farmer_id'], ['users.id'], ondelete='CASCADE')
    )

    # Create order_items table
    op.create_table(
        'order_items',
        sa.Column('id', postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column('order_id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('product_id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('quantity', sa.Numeric(10, 2), nullable=False),
        sa.Column('price', sa.Numeric(10, 2), nullable=False),
        sa.Column('created_at', sa.DateTime(), nullable=False),
        sa.ForeignKeyConstraint(['order_id'], ['orders.id'], ondelete='CASCADE'),
        sa.ForeignKeyConstraint(['product_id'], ['products.id'], ondelete='SET NULL')
    )

    # Create transactions table
    op.create_table(
        'transactions',
        sa.Column('id', postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column('order_id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('amount', sa.Numeric(10, 2), nullable=False),
        sa.Column('provider', postgresql.ENUM('payme', 'click', 'arca', name='paymentprovider'), nullable=False),
        sa.Column('status', postgresql.ENUM('pending', 'completed', 'failed', 'cancelled', 'refunded', name='transactionstatus'), nullable=False, server_default='pending'),
        sa.Column('external_id', sa.String(255), nullable=True),
        sa.Column('payment_method', sa.String(64), nullable=True),
        sa.Column('metadata', sa.String(2000), nullable=True),
        sa.Column('created_at', sa.DateTime(), nullable=False),
        sa.Column('updated_at', sa.DateTime(), nullable=False),
        sa.ForeignKeyConstraint(['order_id'], ['orders.id'], ondelete='CASCADE')
    )

    # Create deliveries table
    op.create_table(
        'deliveries',
        sa.Column('id', postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column('order_id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('status', postgresql.ENUM('pending', 'assigned', 'in_transit', 'delivered', 'failed', 'cancelled', name='deliverystatus'), nullable=False, server_default='pending'),
        sa.Column('delivery_address', sa.String(512), nullable=False),
        sa.Column('courier_name', sa.String(255), nullable=True),
        sa.Column('courier_phone', sa.String(32), nullable=True),
        sa.Column('tracking_number', sa.String(128), nullable=True),
        sa.Column('estimated_delivery', sa.DateTime(), nullable=True),
        sa.Column('delivered_at', sa.DateTime(), nullable=True),
        sa.Column('notes', sa.String(1000), nullable=True),
        sa.Column('created_at', sa.DateTime(), nullable=False),
        sa.Column('updated_at', sa.DateTime(), nullable=False),
        sa.ForeignKeyConstraint(['order_id'], ['orders.id'], ondelete='CASCADE'),
        sa.UniqueConstraint('order_id')
    )

    # Create indexes
    op.create_index('ix_phone_otps_phone_number', 'phone_otps', ['phone_number'])
    op.create_index('ix_products_farmer_id', 'products', ['farmer_id'])
    op.create_index('ix_orders_shop_id', 'orders', ['shop_id'])
    op.create_index('ix_orders_farmer_id', 'orders', ['farmer_id'])
    op.create_index('ix_order_items_order_id', 'order_items', ['order_id'])
    op.create_index('ix_transactions_order_id', 'transactions', ['order_id'])


def downgrade() -> None:
    # Drop tables
    op.drop_table('deliveries')
    op.drop_table('transactions')
    op.drop_table('order_items')
    op.drop_table('orders')
    op.drop_table('products')
    op.drop_table('phone_otps')
    op.drop_table('users')

    # Drop enum types
    op.execute('DROP TYPE IF EXISTS deliverystatus')
    op.execute('DROP TYPE IF EXISTS transactionstatus')
    op.execute('DROP TYPE IF EXISTS paymentprovider')
    op.execute('DROP TYPE IF EXISTS orderstatus')
    op.execute('DROP TYPE IF EXISTS productcategory')
    op.execute('DROP TYPE IF EXISTS entitytype')
    op.execute('DROP TYPE IF EXISTS userrole')
