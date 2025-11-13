from __future__ import annotations

import json
import logging
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import select, func, and_, case
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.dependencies import get_current_user
from app.db.session import get_db
from app.models.product import Product
from app.models.rating import Rating, RatingType
from app.models.user import User, UserRole
from app.schemas.rating import RatingCreate, RatingResponse, RatingReply, RatingStats, RatingUpdate

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/ratings", tags=["ratings"])


@router.post("", response_model=RatingResponse, status_code=status.HTTP_201_CREATED)
async def create_rating(
    payload: RatingCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> RatingResponse:
    """Создать рейтинг/отзыв"""
    try:
        # Validate rating type and IDs
        if payload.rating_type == RatingType.PRODUCT:
            if not payload.product_id:
                raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="product_id required for product rating")
            
            # Check if product exists
            product_stmt = select(Product).where(Product.id == payload.product_id, Product.is_active == True)
            product_result = await db.execute(product_stmt)
            product = product_result.scalar_one_or_none()
            
            if not product:
                raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Product not found")
            
            # Check if user already rated this product
            existing_stmt = select(Rating).where(
                Rating.user_id == current_user.id,
                Rating.rating_type == RatingType.PRODUCT,
                Rating.product_id == payload.product_id
            )
            existing_result = await db.execute(existing_stmt)
            existing = existing_result.scalar_one_or_none()
            
            if existing:
                raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="You have already rated this product")
        
        elif payload.rating_type == RatingType.SELLER:
            if not payload.seller_id:
                raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="seller_id required for seller rating")
            
            # Check if seller exists and is a farmer
            seller_stmt = select(User).where(User.id == payload.seller_id, User.role == UserRole.FARMER)
            seller_result = await db.execute(seller_stmt)
            seller = seller_result.scalar_one_or_none()
            
            if not seller:
                raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Seller not found")
            
            if seller.id == current_user.id:
                raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="You cannot rate yourself")
            
            # Check if user already rated this seller
            existing_stmt = select(Rating).where(
                Rating.user_id == current_user.id,
                Rating.rating_type == RatingType.SELLER,
                Rating.seller_id == payload.seller_id
            )
            existing_result = await db.execute(existing_stmt)
            existing = existing_result.scalar_one_or_none()
            
            if existing:
                raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="You have already rated this seller")
        
        # Serialize images to JSON
        images_json = json.dumps(payload.images) if payload.images else None
        
        rating = Rating(
            user_id=current_user.id,
            rating_type=payload.rating_type,
            product_id=payload.product_id,
            seller_id=payload.seller_id,
            rating=payload.rating,
            comment=payload.comment,
            images=images_json,
            is_approved=False,  # Requires moderation
        )
        
        db.add(rating)
        await db.commit()
        await db.refresh(rating)
        
        # Parse images back from JSON
        response = RatingResponse.model_validate(rating)
        if rating.images:
            response.images = json.loads(rating.images)
        
        return response
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error creating rating: {e}", exc_info=True)
        await db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to create rating: {str(e)}"
        ) from e


@router.get("/product/{product_id}", response_model=list[RatingResponse])
async def get_product_ratings(
    product_id: UUID,
    limit: int = Query(20, ge=1, le=100),
    offset: int = Query(0, ge=0),
    approved_only: bool = Query(True),
    db: AsyncSession = Depends(get_db),
) -> list[RatingResponse]:
    """Получить рейтинги товара"""
    try:
        stmt = select(Rating).where(
            Rating.rating_type == RatingType.PRODUCT,
            Rating.product_id == product_id
        )
        
        if approved_only:
            stmt = stmt.where(Rating.is_approved == True)
        
        stmt = stmt.order_by(Rating.created_at.desc()).limit(limit).offset(offset)
        result = await db.execute(stmt)
        ratings = result.scalars().all()
        
        import json
        response_list = []
        for rating in ratings:
            resp = RatingResponse.model_validate(rating)
            if rating.images:
                resp.images = json.loads(rating.images)
            response_list.append(resp)
        
        return response_list
    except Exception as e:
        logger.error(f"Error getting product ratings: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to get product ratings: {str(e)}"
        ) from e


@router.get("/product/{product_id}/stats", response_model=RatingStats)
async def get_product_rating_stats(
    product_id: UUID,
    db: AsyncSession = Depends(get_db),
) -> RatingStats:
    """Получить статистику рейтингов товара"""
    try:
        stmt = select(
            func.avg(Rating.rating).label('avg_rating'),
            func.count(Rating.id).label('total'),
            func.sum(case((Rating.rating == 1, 1), else_=0)).label('count_1'),
            func.sum(case((Rating.rating == 2, 1), else_=0)).label('count_2'),
            func.sum(case((Rating.rating == 3, 1), else_=0)).label('count_3'),
            func.sum(case((Rating.rating == 4, 1), else_=0)).label('count_4'),
            func.sum(case((Rating.rating == 5, 1), else_=0)).label('count_5'),
        ).where(
            Rating.rating_type == RatingType.PRODUCT,
            Rating.product_id == product_id,
            Rating.is_approved == True
        )
        
        result = await db.execute(stmt)
        stats = result.first()
        
        if stats and stats.total > 0:
            return RatingStats(
                average_rating=float(stats.avg_rating or 0),
                total_ratings=int(stats.total),
                rating_distribution={
                    1: int(stats.count_1 or 0),
                    2: int(stats.count_2 or 0),
                    3: int(stats.count_3 or 0),
                    4: int(stats.count_4 or 0),
                    5: int(stats.count_5 or 0),
                }
            )
        else:
            return RatingStats(
                average_rating=0.0,
                total_ratings=0,
                rating_distribution={1: 0, 2: 0, 3: 0, 4: 0, 5: 0}
            )
    except Exception as e:
        logger.error(f"Error getting product rating stats: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to get product rating stats: {str(e)}"
        ) from e


@router.get("/seller/{seller_id}/stats", response_model=RatingStats)
async def get_seller_rating_stats(
    seller_id: UUID,
    db: AsyncSession = Depends(get_db),
) -> RatingStats:
    """Получить статистику рейтингов продавца"""
    try:
        stmt = select(
            func.avg(Rating.rating).label('avg_rating'),
            func.count(Rating.id).label('total'),
            func.sum(case((Rating.rating == 1, 1), else_=0)).label('count_1'),
            func.sum(case((Rating.rating == 2, 1), else_=0)).label('count_2'),
            func.sum(case((Rating.rating == 3, 1), else_=0)).label('count_3'),
            func.sum(case((Rating.rating == 4, 1), else_=0)).label('count_4'),
            func.sum(case((Rating.rating == 5, 1), else_=0)).label('count_5'),
        ).where(
            Rating.rating_type == RatingType.SELLER,
            Rating.seller_id == seller_id,
            Rating.is_approved == True
        )
        
        result = await db.execute(stmt)
        stats = result.first()
        
        if stats and stats.total > 0:
            return RatingStats(
                average_rating=float(stats.avg_rating or 0),
                total_ratings=int(stats.total),
                rating_distribution={
                    1: int(stats.count_1 or 0),
                    2: int(stats.count_2 or 0),
                    3: int(stats.count_3 or 0),
                    4: int(stats.count_4 or 0),
                    5: int(stats.count_5 or 0),
                }
            )
        else:
            return RatingStats(
                average_rating=0.0,
                total_ratings=0,
                rating_distribution={1: 0, 2: 0, 3: 0, 4: 0, 5: 0}
            )
    except Exception as e:
        logger.error(f"Error getting seller rating stats: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to get seller rating stats: {str(e)}"
        ) from e


@router.patch("/{rating_id}/reply", response_model=RatingResponse)
async def reply_to_rating(
    rating_id: UUID,
    payload: RatingReply,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> RatingResponse:
    """Ответить на отзыв (только продавец/фермер)"""
    try:
        stmt = select(Rating).where(Rating.id == rating_id)
        result = await db.execute(stmt)
        rating = result.scalar_one_or_none()
        
        if not rating:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Rating not found")
        
        # Check if current user is the seller/farmer
        if rating.rating_type == RatingType.PRODUCT:
            product_stmt = select(Product).where(Product.id == rating.product_id)
            product_result = await db.execute(product_stmt)
            product = product_result.scalar_one_or_none()
            
            if not product or product.farmer_id != current_user.id:
                raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Only the product owner can reply")
        
        elif rating.rating_type == RatingType.SELLER:
            if rating.seller_id != current_user.id:
                raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Only the seller can reply")
        
        rating.reply = payload.reply
        rating.replied_at = datetime.now(UTC)
        
        await db.commit()
        await db.refresh(rating)
        
        import json
        response = RatingResponse.model_validate(rating)
        if rating.images:
            response.images = json.loads(rating.images)
        
        return response
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error replying to rating: {e}", exc_info=True)
        await db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to reply to rating: {str(e)}"
        ) from e

