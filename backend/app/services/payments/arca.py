"""Arca payment provider adapter (Uzbekistan)."""

from __future__ import annotations

import logging
from typing import Any

import httpx

from app.core.config import get_settings
from app.models.transaction import PaymentProvider
from app.services.payments.base import PaymentAdapter

logger = logging.getLogger(__name__)


class ArcaAdapter(PaymentAdapter):
    """Arca payment provider implementation for Uzbekistan."""

    def __init__(self) -> None:
        self.settings = get_settings()
        # TODO: Load from settings
        self.merchant_id = ""  # ARCA_MERCHANT_ID
        self.certificate_path = ""  # ARCA_CERTIFICATE_PATH
        self.base_url = "https://arca.uz/api"  # Arca API base URL

    @property
    def provider(self) -> PaymentProvider:
        return PaymentProvider.ARCA

    async def create_payment(
        self,
        transaction: Any,
        amount: float,
        order_id: str,
        **kwargs: Any,
    ) -> dict[str, Any]:
        """Create payment request with Arca."""
        # TODO: Implement Arca InitPayment
        # Reference: Arca API documentation for Uzbekistan
        logger.info(f"Creating Arca payment for order {order_id}, amount {amount}")
        return {
            "payment_url": f"{self.base_url}/payment/{transaction.id}",
            "payment_data": {"merchant_id": self.merchant_id},
        }

    async def verify_payment(self, external_id: str, **kwargs: Any) -> dict[str, Any]:
        """Verify payment status with Arca."""
        # TODO: Implement Arca GetPaymentStatus
        logger.info(f"Verifying Arca payment {external_id}")
        return {"status": "pending", "amount": 0.0}

    async def process_webhook(self, payload: dict[str, Any]) -> dict[str, Any]:
        """Process Arca webhook."""
        # TODO: Implement Arca webhook processing
        # Handle PaymentResult callback
        logger.info(f"Processing Arca webhook: {payload}")
        return {"transaction_id": "", "status": "pending", "amount": 0.0}

    async def refund_payment(self, external_id: str, amount: float | None = None, **kwargs: Any) -> dict[str, Any]:
        """Initiate refund with Arca."""
        # TODO: Implement Arca ReversePayment/RefundPayment
        logger.info(f"Refunding Arca payment {external_id}, amount {amount}")
        return {"status": "pending"}
