from __future__ import annotations

from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.dependencies import get_current_user
from app.db.session import get_db
from app.models.delivery import Delivery, DeliveryStatus
from app.models.order import Order
from app.models.user import User, UserRole
from app.schemas.delivery import DeliveryResponse, DeliveryUpdate

router = APIRouter(prefix="/deliveries", tags=["deliveries"])


@router.get("/order/{order_id}", response_model=DeliveryResponse)
async def get_delivery_by_order(
    order_id: UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> DeliveryResponse:
    """Get delivery information for an order."""
    stmt = select(Delivery).where(Delivery.order_id == order_id)
    result = await db.execute(stmt)
    delivery = result.scalar_one_or_none()
    
    if not delivery:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Delivery not found")
    
    # Check authorization
    order_stmt = select(Order).where(Order.id == order_id)
    order_result = await db.execute(order_stmt)
    order = order_result.scalar_one_or_none()
    
    if not order:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Order not found")
    
    if (
        current_user.role not in (UserRole.ADMIN,)
        and order.shop_id != current_user.id
        and order.farmer_id != current_user.id
    ):
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Not authorized")
    
    return DeliveryResponse.model_validate(delivery)


@router.patch("/order/{order_id}", response_model=DeliveryResponse)
async def update_delivery(
    order_id: UUID,
    payload: DeliveryUpdate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> DeliveryResponse:
    """Update delivery status and information."""
    if current_user.role != UserRole.ADMIN:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Only admins can update deliveries")
    
    stmt = select(Delivery).where(Delivery.order_id == order_id)
    result = await db.execute(stmt)
    delivery = result.scalar_one_or_none()
    
    if not delivery:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Delivery not found")
    
    update_data = payload.model_dump(exclude_unset=True)
    
    # Handle status transitions
    if "status" in update_data:
        new_status = update_data["status"]
        if new_status == DeliveryStatus.DELIVERED and delivery.status != DeliveryStatus.DELIVERED:
            from datetime import datetime
            update_data["delivered_at"] = datetime.utcnow()
            # Update order status
            order_stmt = select(Order).where(Order.id == order_id)
            order_result = await db.execute(order_stmt)
            order = order_result.scalar_one_or_none()
            if order:
                from app.models.order import OrderStatus
                order.status = OrderStatus.DELIVERED
    
    for field, value in update_data.items():
        setattr(delivery, field, value)
    
    await db.commit()
    await db.refresh(delivery)
    
    return DeliveryResponse.model_validate(delivery)
