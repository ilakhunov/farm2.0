from __future__ import annotations

import logging
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.dependencies import get_current_user
from app.db.session import get_db
from app.models.favorite import Favorite
from app.models.product import Product
from app.models.user import User
from app.schemas.favorite import FavoriteCreate, FavoriteResponse
from app.schemas.product import ProductListResponse

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/favorites", tags=["favorites"])


@router.post("", response_model=FavoriteResponse, status_code=status.HTTP_201_CREATED)
async def add_to_favorites(
    payload: FavoriteCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> FavoriteResponse:
    """Добавить товар в избранное"""
    try:
        # Check if product exists
        product_stmt = select(Product).where(Product.id == payload.product_id, Product.is_active == True)
        product_result = await db.execute(product_stmt)
        product = product_result.scalar_one_or_none()
        
        if not product:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Product not found")
        
        # Check if already in favorites
        existing_stmt = select(Favorite).where(
            Favorite.user_id == current_user.id,
            Favorite.product_id == payload.product_id
        )
        existing_result = await db.execute(existing_stmt)
        existing = existing_result.scalar_one_or_none()
        
        if existing:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Product already in favorites")
        
        favorite = Favorite(
            user_id=current_user.id,
            product_id=payload.product_id,
        )
        db.add(favorite)
        await db.commit()
        await db.refresh(favorite)
        
        return FavoriteResponse.model_validate(favorite)
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error adding to favorites: {e}", exc_info=True)
        await db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to add to favorites: {str(e)}"
        ) from e


@router.delete("/{product_id}", status_code=status.HTTP_204_NO_CONTENT)
async def remove_from_favorites(
    product_id: UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Удалить товар из избранного"""
    try:
        stmt = select(Favorite).where(
            Favorite.user_id == current_user.id,
            Favorite.product_id == product_id
        )
        result = await db.execute(stmt)
        favorite = result.scalar_one_or_none()
        
        if not favorite:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Favorite not found")
        
        await db.delete(favorite)
        await db.commit()
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error removing from favorites: {e}", exc_info=True)
        await db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to remove from favorites: {str(e)}"
        ) from e


@router.get("", response_model=ProductListResponse)
async def list_favorites(
    limit: int = Query(20, ge=1, le=100),
    offset: int = Query(0, ge=0),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> ProductListResponse:
    """Получить список избранных товаров"""
    try:
        # Get favorites with products
        stmt = select(Product).join(Favorite).where(
            Favorite.user_id == current_user.id,
            Product.is_active == True
        )
        
        count_stmt = select(func.count()).select_from(stmt.subquery())
        total_result = await db.execute(count_stmt)
        total = total_result.scalar_one()
        
        stmt = stmt.order_by(Favorite.created_at.desc()).limit(limit).offset(offset)
        result = await db.execute(stmt)
        products = result.scalars().all()
        
        from app.schemas.product import ProductResponse
        return ProductListResponse(
            items=[ProductResponse.model_validate(p) for p in products],
            total=total,
        )
    except Exception as e:
        logger.error(f"Error listing favorites: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to list favorites: {str(e)}"
        ) from e


@router.get("/check/{product_id}")
async def check_favorite(
    product_id: UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> dict[str, bool]:
    """Проверить, находится ли товар в избранном"""
    try:
        stmt = select(Favorite).where(
            Favorite.user_id == current_user.id,
            Favorite.product_id == product_id
        )
        result = await db.execute(stmt)
        favorite = result.scalar_one_or_none()
        
        return {"is_favorite": favorite is not None}
    except Exception as e:
        logger.error(f"Error checking favorite: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to check favorite: {str(e)}"
        ) from e

