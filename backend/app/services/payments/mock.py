"""Mock payment provider for development and testing."""

from __future__ import annotations

import logging
from typing import Any

from app.models.transaction import PaymentProvider, Transaction, TransactionStatus
from app.services.payments.base import PaymentAdapter

logger = logging.getLogger(__name__)


class MockAdapter(PaymentAdapter):
    """Mock payment provider for development/testing."""

    @property
    def provider(self) -> PaymentProvider:
        return PaymentProvider.PAYME  # Use PAYME as default for mock

    async def create_payment(
        self,
        transaction: Transaction,
        amount: float,
        order_id: str,
        **kwargs: Any,
    ) -> dict[str, Any]:
        """Create mock payment - returns success immediately."""
        logger.info(f"Mock payment created for order {order_id}, amount {amount}")
        return {
            "payment_url": f"http://localhost:8000/mock-payment/{transaction.id}",
            "payment_data": {
                "transaction_id": str(transaction.id),
                "amount": amount,
                "status": "success",
            },
            "external_id": f"mock_{transaction.id}",
        }

    async def verify_payment(self, external_id: str, **kwargs: Any) -> dict[str, Any]:
        """Verify mock payment - always returns success."""
        logger.info(f"Mock payment verification for {external_id}")
        return {
            "status": "completed",
            "amount": 0.0,  # Will be updated from transaction
            "external_id": external_id,
        }

    async def process_webhook(self, payload: dict[str, Any]) -> dict[str, Any]:
        """Process mock webhook - simulates successful payment."""
        transaction_id = payload.get("transaction_id") or payload.get("id")
        logger.info(f"Mock webhook processed for transaction {transaction_id}")
        return {
            "transaction_id": transaction_id or "",
            "status": "completed",
            "amount": payload.get("amount", 0.0),
        }

    async def refund_payment(self, external_id: str, amount: float | None = None, **kwargs: Any) -> dict[str, Any]:
        """Process mock refund."""
        logger.info(f"Mock refund for {external_id}, amount: {amount}")
        return {
            "status": "refunded",
            "amount": amount or 0.0,
            "external_id": external_id,
        }

