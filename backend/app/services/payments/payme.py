"""Payme payment provider adapter."""

from __future__ import annotations

import hashlib
import hmac
import logging
from typing import Any

import httpx

from app.core.config import get_settings
from app.models.transaction import PaymentProvider
from app.services.payments.base import PaymentAdapter

logger = logging.getLogger(__name__)


class PaymeAdapter(PaymentAdapter):
    """Payme payment provider implementation."""

    def __init__(self) -> None:
        self.settings = get_settings()
        # TODO: Load from settings
        self.merchant_id = ""  # PAYME_MERCHANT_ID
        self.key = ""  # PAYME_KEY
        self.base_url = "https://checkout.paycom.uz"  # Payme API base URL

    @property
    def provider(self) -> PaymentProvider:
        return PaymentProvider.PAYME

    def _generate_signature(self, data: dict[str, Any]) -> str:
        """Generate HMAC-SHA1 signature for Payme requests."""
        # TODO: Implement Payme signature generation
        return ""

    async def create_payment(
        self,
        transaction: Any,
        amount: float,
        order_id: str,
        **kwargs: Any,
    ) -> dict[str, Any]:
        """Create payment request with Payme."""
        settings = get_settings()
        
        # Use mock mode if configured
        if settings.sms_provider == "dev" or settings.payment_mock_mode:
            from app.services.payments.mock import MockAdapter
            mock = MockAdapter()
            return await mock.create_payment(transaction, amount, order_id, **kwargs)
        
        # TODO: Implement Payme payment creation
        # Reference: https://developer.help.paycom.uz/ru/protokol-merchant-api
        logger.info(f"Creating Payme payment for order {order_id}, amount {amount}")
        return {
            "payment_url": f"{self.base_url}/payment/{transaction.id}",
            "payment_data": {"merchant_id": self.merchant_id},
        }

    async def verify_payment(self, external_id: str, **kwargs: Any) -> dict[str, Any]:
        """Verify payment status with Payme."""
        # TODO: Implement Payme payment verification
        logger.info(f"Verifying Payme payment {external_id}")
        return {"status": "pending", "amount": 0.0}

    async def process_webhook(self, payload: dict[str, Any]) -> dict[str, Any]:
        """Process Payme webhook."""
        # TODO: Implement Payme webhook processing
        # Check signature, extract transaction data
        logger.info(f"Processing Payme webhook: {payload}")
        return {"transaction_id": "", "status": "pending", "amount": 0.0}

    async def refund_payment(self, external_id: str, amount: float | None = None, **kwargs: Any) -> dict[str, Any]:
        """Initiate refund with Payme."""
        # TODO: Implement Payme refund
        logger.info(f"Refunding Payme payment {external_id}, amount {amount}")
        return {"status": "pending"}
