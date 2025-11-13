from __future__ import annotations

import logging
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import select, func, update as sa_update, text as sa_text
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.dependencies import get_current_user
from app.db.session import get_db
from app.models.order import Order, OrderItem, OrderStatus
from app.models.product import Product
from app.models.user import User, UserRole
from app.schemas.order import OrderCreate, OrderItemResponse, OrderListResponse, OrderResponse, OrderUpdate

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/orders", tags=["orders"])


@router.post("", response_model=OrderResponse, status_code=status.HTTP_201_CREATED)
async def create_order(
    payload: OrderCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> OrderResponse:
    try:
        logger.info(f"Creating order for shop {current_user.id}, farmer {payload.farmer_id}")
        
        if current_user.role != UserRole.SHOP:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Only shops can create orders")

        # Verify farmer exists
        farmer_stmt = select(User).where(User.id == payload.farmer_id, User.role == UserRole.FARMER)
        farmer_result = await db.execute(farmer_stmt)
        farmer = farmer_result.scalar_one_or_none()
        if not farmer:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Farmer not found")

        # Validate products and calculate total
        total_amount = 0.0
        order_items = []
        
        for item_data in payload.items:
            logger.info(f"Processing order item: product_id={item_data.product_id}, quantity={item_data.quantity}")
            product_stmt = select(Product).where(Product.id == item_data.product_id, Product.is_active == True)
            product_result = await db.execute(product_stmt)
            product = product_result.scalar_one_or_none()
            
            if not product:
                raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=f"Product {item_data.product_id} not found")
            
            if product.farmer_id != payload.farmer_id:
                raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=f"Product {item_data.product_id} does not belong to this farmer")
            
            if product.quantity < item_data.quantity:
                raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=f"Insufficient quantity for product {product.name}")
            
            item_total = float(product.price) * item_data.quantity
            total_amount += item_total
            
            order_items.append({
                "product": product,
                "quantity": item_data.quantity,
                "price": float(product.price),
            })

        logger.info(f"Total amount calculated: {total_amount}")

        # Create order
        order = Order(
            shop_id=current_user.id,
            farmer_id=payload.farmer_id,
            status=OrderStatus.PENDING,
            total_amount=total_amount,
            delivery_address=payload.delivery_address,
            notes=payload.notes,
        )
        db.add(order)
        await db.flush()  # Get order.id
        logger.info(f"Order created in DB, ID: {order.id}")

        # Create order items
        for item_data in order_items:
            order_item = OrderItem(
                order_id=order.id,
                product_id=item_data["product"].id,
                quantity=item_data["quantity"],
                price=item_data["price"],
            )
            db.add(order_item)
        
        await db.flush()  # Flush to get order_item IDs
        
        # Reduce product quantities after flush using SQL update
        for item_data in order_items:
            product_id = item_data["product"].id
            quantity_to_reduce = item_data["quantity"]
            # Reload product and update
            product_stmt = select(Product).where(Product.id == product_id)
            product_result = await db.execute(product_stmt)
            product = product_result.scalar_one_or_none()
            
            if not product:
                logger.error(f"Product {product_id} not found when reducing quantity")
                await db.rollback()
                raise HTTPException(
                    status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                    detail=f"Product {product_id} not found"
                )
            
            # Double-check quantity is still sufficient (race condition protection)
            if product.quantity < quantity_to_reduce:
                logger.error(f"Insufficient quantity for product {product_id}: available={product.quantity}, requested={quantity_to_reduce}")
                await db.rollback()
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail=f"Insufficient quantity for product {product.name}"
                )
            
            from decimal import Decimal
            product.quantity = Decimal(str(product.quantity)) - Decimal(str(quantity_to_reduce))
            if product.quantity < 0:
                product.quantity = 0  # Prevent negative quantities

        await db.commit()
        logger.info(f"Order committed to DB: {order.id}")
        
        # Reload order with items for response using selectinload
        from sqlalchemy.orm import selectinload
        order_stmt = select(Order).options(selectinload(Order.items)).where(Order.id == order.id)
        order_result = await db.execute(order_stmt)
        reloaded_order = order_result.scalar_one_or_none()
        
        if not reloaded_order:
            logger.error(f"Order {order.id} not found after commit")
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Order was created but could not be retrieved"
            )
        
        logger.info(f"Order loaded with {len(reloaded_order.items)} items")
        
        # Create response manually to avoid validation issues
        items_data = [OrderItemResponse.model_validate(item) for item in reloaded_order.items]
        response = OrderResponse(
            id=reloaded_order.id,
            shop_id=reloaded_order.shop_id,
            farmer_id=reloaded_order.farmer_id,
            status=reloaded_order.status,
            total_amount=float(reloaded_order.total_amount),
            delivery_address=reloaded_order.delivery_address,
            notes=reloaded_order.notes,
            items=items_data,
            created_at=reloaded_order.created_at,
            updated_at=reloaded_order.updated_at,
        )
        
        logger.info(f"Order response created successfully")
        return response
    except HTTPException:
        # Re-raise HTTP exceptions as-is
        await db.rollback()
        raise
    except Exception as e:
        logger.error(f"Error creating order: {e}", exc_info=True)
        await db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to create order: {str(e)}"
        ) from e


@router.get("", response_model=OrderListResponse)
async def list_orders(
    status_filter: OrderStatus | None = Query(None, alias="status"),
    farmer_id: UUID | None = Query(None),
    shop_id: UUID | None = Query(None),
    limit: int = Query(20, ge=1, le=100),
    offset: int = Query(0, ge=0),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> OrderListResponse:
    stmt = select(Order)
    
    # Apply role-based filtering
    if current_user.role == UserRole.FARMER:
        stmt = stmt.where(Order.farmer_id == current_user.id)
    elif current_user.role == UserRole.SHOP:
        stmt = stmt.where(Order.shop_id == current_user.id)
    elif current_user.role != UserRole.ADMIN:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Not authorized")
    
    if status_filter:
        stmt = stmt.where(Order.status == status_filter)
    if farmer_id:
        stmt = stmt.where(Order.farmer_id == farmer_id)
    if shop_id:
        stmt = stmt.where(Order.shop_id == shop_id)
    
    count_stmt = select(func.count()).select_from(stmt.subquery())
    total_result = await db.execute(count_stmt)
    total = total_result.scalar_one()
    
    stmt = stmt.order_by(Order.created_at.desc()).limit(limit).offset(offset)
    result = await db.execute(stmt)
    orders = result.scalars().all()
    
    # Load items for each order
    for order in orders:
        items_stmt = select(OrderItem).where(OrderItem.order_id == order.id)
        items_result = await db.execute(items_stmt)
        order.items = items_result.scalars().all()
    
    return OrderListResponse(
        items=[OrderResponse.model_validate(o) for o in orders],
        total=total,
    )


@router.get("/{order_id}", response_model=OrderResponse)
async def get_order(
    order_id: UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> OrderResponse:
    stmt = select(Order).where(Order.id == order_id)
    result = await db.execute(stmt)
    order = result.scalar_one_or_none()
    
    if not order:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Order not found")
    
    # Check authorization
    if current_user.role not in (UserRole.ADMIN,) and order.shop_id != current_user.id and order.farmer_id != current_user.id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Not authorized to view this order")
    
    items_stmt = select(OrderItem).where(OrderItem.order_id == order.id)
    items_result = await db.execute(items_stmt)
    order.items = items_result.scalars().all()
    
    return OrderResponse.model_validate(order)


@router.patch("/{order_id}", response_model=OrderResponse)
async def update_order(
    order_id: UUID,
    payload: OrderUpdate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> OrderResponse:
    stmt = select(Order).where(Order.id == order_id)
    result = await db.execute(stmt)
    order = result.scalar_one_or_none()
    
    if not order:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Order not found")
    
    # Check authorization
    can_update = (
        current_user.role == UserRole.ADMIN
        or (current_user.role == UserRole.FARMER and order.farmer_id == current_user.id)
        or (current_user.role == UserRole.SHOP and order.shop_id == current_user.id)
    )
    
    if not can_update:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Not authorized to update this order")
    
    # Status transition rules
    if payload.status:
        if payload.status == OrderStatus.CONFIRMED and order.status != OrderStatus.PENDING:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Can only confirm pending orders")
        if payload.status == OrderStatus.CANCELLED and order.status in (OrderStatus.DELIVERED, OrderStatus.CANCELLED):
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Cannot cancel delivered or already cancelled orders")
    
    update_data = payload.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        setattr(order, field, value)
    
    await db.commit()
    await db.refresh(order)
    
    items_stmt = select(OrderItem).where(OrderItem.order_id == order.id)
    items_result = await db.execute(items_stmt)
    order.items = items_result.scalars().all()
    
    return OrderResponse.model_validate(order)
