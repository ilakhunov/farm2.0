from __future__ import annotations

import logging
from datetime import datetime, UTC
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.dependencies import get_current_user
from app.db.session import get_db
from app.models.product import Product
from app.models.user import User
from app.models.view_history import ViewHistory
from app.schemas.product import ProductListResponse, ProductResponse

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/view-history", tags=["view-history"])


@router.post("/{product_id}", status_code=status.HTTP_201_CREATED)
async def record_view(
    product_id: UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> dict[str, str]:
    """Записать просмотр товара"""
    try:
        # Check if product exists
        product_stmt = select(Product).where(Product.id == product_id, Product.is_active == True)
        product_result = await db.execute(product_stmt)
        product = product_result.scalar_one_or_none()
        
        if not product:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Product not found")
        
        # Create or update view history (keep only one record per user-product)
        existing_stmt = select(ViewHistory).where(
            ViewHistory.user_id == current_user.id,
            ViewHistory.product_id == product_id
        )
        existing_result = await db.execute(existing_stmt)
        existing = existing_result.scalar_one_or_none()
        
        if existing:
            # Update viewed_at timestamp
            existing.viewed_at = datetime.now(UTC)
            await db.commit()
        else:
            # Create new record
            view_history = ViewHistory(
                user_id=current_user.id,
                product_id=product_id,
            )
            db.add(view_history)
            await db.commit()
        
        return {"message": "View recorded"}
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error recording view: {e}", exc_info=True)
        await db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to record view: {str(e)}"
        ) from e


@router.get("", response_model=ProductListResponse)
async def get_view_history(
    limit: int = Query(20, ge=1, le=100),
    offset: int = Query(0, ge=0),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> ProductListResponse:
    """Получить историю просмотров"""
    try:
        stmt = select(Product).join(ViewHistory).where(
            ViewHistory.user_id == current_user.id,
            Product.is_active == True
        )
        
        count_stmt = select(func.count()).select_from(stmt.subquery())
        total_result = await db.execute(count_stmt)
        total = total_result.scalar_one()
        
        stmt = stmt.order_by(ViewHistory.viewed_at.desc()).limit(limit).offset(offset)
        result = await db.execute(stmt)
        products = result.scalars().all()
        
        return ProductListResponse(
            items=[ProductResponse.model_validate(p) for p in products],
            total=total,
        )
    except Exception as e:
        logger.error(f"Error getting view history: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to get view history: {str(e)}"
        ) from e


@router.delete("", status_code=status.HTTP_204_NO_CONTENT)
async def clear_view_history(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Очистить историю просмотров"""
    try:
        stmt = select(ViewHistory).where(ViewHistory.user_id == current_user.id)
        result = await db.execute(stmt)
        history_items = result.scalars().all()
        
        for item in history_items:
            await db.delete(item)
        
        await db.commit()
    except Exception as e:
        logger.error(f"Error clearing view history: {e}", exc_info=True)
        await db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to clear view history: {str(e)}"
        ) from e

