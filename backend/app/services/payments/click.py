"""Click payment provider adapter."""

from __future__ import annotations

import hashlib
import logging
from typing import Any

import httpx

from app.core.config import get_settings
from app.models.transaction import PaymentProvider
from app.services.payments.base import PaymentAdapter

logger = logging.getLogger(__name__)


class ClickAdapter(PaymentAdapter):
    """Click payment provider implementation."""

    def __init__(self) -> None:
        self.settings = get_settings()
        # TODO: Load from settings
        self.merchant_id = ""  # CLICK_MERCHANT_ID
        self.service_id = ""  # CLICK_SERVICE_ID
        self.secret_key = ""  # CLICK_SECRET_KEY
        self.base_url = "https://api.click.uz"  # Click API base URL

    @property
    def provider(self) -> PaymentProvider:
        return PaymentProvider.CLICK

    def _generate_signature(self, data: dict[str, Any]) -> str:
        """Generate signature for Click requests."""
        # TODO: Implement Click signature generation (sign_time)
        return ""

    async def create_payment(
        self,
        transaction: Any,
        amount: float,
        order_id: str,
        **kwargs: Any,
    ) -> dict[str, Any]:
        """Create payment request with Click."""
        from app.core.config import get_settings
        settings = get_settings()
        
        # Use mock mode if configured
        if settings.sms_provider == "dev" or settings.payment_mock_mode:
            from app.services.payments.mock import MockAdapter
            mock = MockAdapter()
            return await mock.create_payment(transaction, amount, order_id, **kwargs)
        
        # TODO: Implement Click merchant/prepare endpoint
        # Reference: Click merchant API documentation
        logger.info(f"Creating Click payment for order {order_id}, amount {amount}")
        return {
            "payment_url": f"{self.base_url}/payment/{transaction.id}",
            "payment_data": {"merchant_id": self.merchant_id, "service_id": self.service_id},
        }

    async def verify_payment(self, external_id: str, **kwargs: Any) -> dict[str, Any]:
        """Verify payment status with Click."""
        # TODO: Implement Click payment status check
        logger.info(f"Verifying Click payment {external_id}")
        return {"status": "pending", "amount": 0.0}

    async def process_webhook(self, payload: dict[str, Any]) -> dict[str, Any]:
        """Process Click webhook."""
        # TODO: Implement Click webhook processing (merchant/complete callback)
        logger.info(f"Processing Click webhook: {payload}")
        return {"transaction_id": "", "status": "pending", "amount": 0.0}

    async def refund_payment(self, external_id: str, amount: float | None = None, **kwargs: Any) -> dict[str, Any]:
        """Initiate refund with Click."""
        # TODO: Implement Click refund
        logger.info(f"Refunding Click payment {external_id}, amount {amount}")
        return {"status": "pending"}
