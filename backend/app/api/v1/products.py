from __future__ import annotations

import logging
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.dependencies import get_current_user
from app.db.session import get_db
from app.models.product import Product, ProductCategory
from app.models.user import User, UserRole
from app.schemas.product import ProductCreate, ProductListResponse, ProductResponse, ProductUpdate

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/products", tags=["products"])


@router.post("", response_model=ProductResponse, status_code=status.HTTP_201_CREATED)
async def create_product(
    payload: ProductCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> ProductResponse:
    if current_user.role != UserRole.FARMER:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Only farmers can create products")

    try:
        logger.info(f"Creating product for farmer {current_user.id}: {payload.name}")
        product = Product(
            farmer_id=current_user.id,
            name=payload.name,
            description=payload.description,
            category=payload.category,
            price=payload.price,
            quantity=payload.quantity,
            unit=payload.unit,
            image_url=payload.image_url,
        )
        db.add(product)
        await db.commit()
        await db.refresh(product)
        logger.info(f"Product created successfully: {product.id}")
        return ProductResponse.model_validate(product)
    except Exception as e:
        logger.error(f"Error creating product: {e}", exc_info=True)
        await db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to create product: {str(e)}"
        ) from e


@router.get("", response_model=ProductListResponse)
async def list_products(
    category: ProductCategory | None = Query(None),
    farmer_id: UUID | None = Query(None),
    min_price: float | None = Query(None),
    max_price: float | None = Query(None),
    search: str | None = Query(None),
    limit: int = Query(20, ge=1, le=100),
    offset: int = Query(0, ge=0),
    db: AsyncSession = Depends(get_db),
) -> ProductListResponse:
    stmt = select(Product).where(Product.is_active == True)
    
    if category:
        stmt = stmt.where(Product.category == category)
    if farmer_id:
        stmt = stmt.where(Product.farmer_id == farmer_id)
    if min_price is not None:
        stmt = stmt.where(Product.price >= min_price)
    if max_price is not None:
        stmt = stmt.where(Product.price <= max_price)
    if search:
        search_pattern = f"%{search}%"
        stmt = stmt.where(Product.name.ilike(search_pattern) | Product.description.ilike(search_pattern))
    
    count_stmt = select(func.count()).select_from(stmt.subquery())
    total_result = await db.execute(count_stmt)
    total = total_result.scalar_one()
    
    stmt = stmt.order_by(Product.created_at.desc()).limit(limit).offset(offset)
    result = await db.execute(stmt)
    products = result.scalars().all()
    
    return ProductListResponse(
        items=[ProductResponse.model_validate(p) for p in products],
        total=total,
    )


@router.get("/{product_id}", response_model=ProductResponse)
async def get_product(
    product_id: UUID,
    db: AsyncSession = Depends(get_db),
) -> ProductResponse:
    stmt = select(Product).where(Product.id == product_id, Product.is_active == True)
    result = await db.execute(stmt)
    product = result.scalar_one_or_none()
    
    if not product:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Product not found")
    
    return ProductResponse.model_validate(product)


@router.patch("/{product_id}", response_model=ProductResponse)
async def update_product(
    product_id: UUID,
    payload: ProductUpdate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> ProductResponse:
    stmt = select(Product).where(Product.id == product_id)
    result = await db.execute(stmt)
    product = result.scalar_one_or_none()
    
    if not product:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Product not found")
    
    if product.farmer_id != current_user.id and current_user.role != UserRole.ADMIN:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Not authorized to update this product")
    
    update_data = payload.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        setattr(product, field, value)
    
    await db.commit()
    await db.refresh(product)
    return ProductResponse.model_validate(product)


@router.delete("/{product_id}", status_code=status.HTTP_204_NO_CONTENT, response_model=None)
async def delete_product(
    product_id: UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> None:
    stmt = select(Product).where(Product.id == product_id)
    result = await db.execute(stmt)
    product = result.scalar_one_or_none()
    
    if not product:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Product not found")
    
    if product.farmer_id != current_user.id and current_user.role != UserRole.ADMIN:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Not authorized to delete this product")
    
    # Check if product has active orders
    from app.models.order import Order, OrderItem, OrderStatus
    from sqlalchemy import and_
    
    order_items_stmt = select(OrderItem).join(Order).where(
        and_(
            OrderItem.product_id == product.id,
            Order.status.in_([OrderStatus.PENDING, OrderStatus.CONFIRMED, OrderStatus.PROCESSING, OrderStatus.SHIPPED])
        )
    )
    order_items_result = await db.execute(order_items_stmt)
    active_order_items = order_items_result.scalars().all()
    
    if active_order_items:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Cannot delete product with active orders"
        )
    
    await db.delete(product)
    await db.commit()
