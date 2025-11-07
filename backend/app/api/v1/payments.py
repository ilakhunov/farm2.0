from __future__ import annotations

from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.dependencies import get_current_user
from app.db.session import get_db
from app.models.order import Order
from app.models.transaction import PaymentProvider, Transaction, TransactionStatus
from app.models.user import User, UserRole
from app.schemas.transaction import PaymentInitRequest, PaymentInitResponse, TransactionResponse
from app.services.payments.factory import get_payment_adapter

router = APIRouter(prefix="/payments", tags=["payments"])


@router.post("/init", response_model=PaymentInitResponse)
async def init_payment(
    payload: PaymentInitRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> PaymentInitResponse:
    """Initialize payment for an order."""
    # Verify order exists and belongs to user
    stmt = select(Order).where(Order.id == payload.order_id)
    result = await db.execute(stmt)
    order = result.scalar_one_or_none()
    
    if not order:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Order not found")
    
    if order.shop_id != current_user.id and current_user.role != UserRole.ADMIN:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Not authorized")
    
    # Check if transaction already exists
    existing_stmt = select(Transaction).where(
        Transaction.order_id == payload.order_id,
        Transaction.status == TransactionStatus.PENDING,
    )
    existing_result = await db.execute(existing_stmt)
    existing = existing_result.scalar_one_or_none()
    
    if existing:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Payment already initiated")
    
    # Create transaction
    transaction = Transaction(
        order_id=payload.order_id,
        amount=float(order.total_amount),
        provider=payload.provider,
        status=TransactionStatus.PENDING,
    )
    db.add(transaction)
    await db.flush()
    
    # Initialize payment with provider
    adapter = get_payment_adapter(payload.provider)
    payment_data = await adapter.create_payment(
        transaction=transaction,
        amount=float(order.total_amount),
        order_id=str(order.id),
    )
    
    # Update transaction with external ID if provided
    if "external_id" in payment_data:
        transaction.external_id = payment_data["external_id"]
    
    await db.commit()
    await db.refresh(transaction)
    
    return PaymentInitResponse(
        transaction_id=transaction.id,
        payment_url=payment_data.get("payment_url"),
        payment_data=payment_data.get("payment_data"),
    )


@router.get("/transactions", response_model=list[TransactionResponse])
async def list_transactions(
    order_id: UUID | None = None,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> list[TransactionResponse]:
    """List transactions for current user."""
    stmt = select(Transaction)
    
    if order_id:
        stmt = stmt.where(Transaction.order_id == order_id)
    
    # Filter by user's orders
    if current_user.role == UserRole.SHOP:
        stmt = stmt.join(Order).where(Order.shop_id == current_user.id)
    elif current_user.role == UserRole.FARMER:
        stmt = stmt.join(Order).where(Order.farmer_id == current_user.id)
    elif current_user.role != UserRole.ADMIN:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Not authorized")
    
    result = await db.execute(stmt.order_by(Transaction.created_at.desc()))
    transactions = result.scalars().all()
    
    return [TransactionResponse.model_validate(t) for t in transactions]


@router.post("/webhooks/{provider}")
async def process_webhook(
    provider: PaymentProvider,
    payload: dict,
    db: AsyncSession = Depends(get_db),
) -> dict:
    """Process webhook from payment provider."""
    adapter = get_payment_adapter(provider)
    webhook_data = await adapter.process_webhook(payload)
    
    # Update transaction status
    if "transaction_id" in webhook_data:
        transaction_id = UUID(webhook_data["transaction_id"])
        stmt = select(Transaction).where(Transaction.id == transaction_id)
        result = await db.execute(stmt)
        transaction = result.scalar_one_or_none()
        
        if transaction:
            if webhook_data.get("status") == "completed":
                transaction.status = TransactionStatus.COMPLETED
                # Update order status if payment successful
                order_stmt = select(Order).where(Order.id == transaction.order_id)
                order_result = await db.execute(order_stmt)
                order = order_result.scalar_one_or_none()
                if order:
                    from app.models.order import OrderStatus
                    if order.status.value == "pending":
                        order.status = OrderStatus.CONFIRMED
            elif webhook_data.get("status") == "failed":
                transaction.status = TransactionStatus.FAILED
            
            await db.commit()
    
    return {"status": "ok"}
