"""Base payment provider interface."""

from __future__ import annotations

from abc import ABC, abstractmethod
from typing import Any

from app.models.transaction import PaymentProvider, Transaction


class PaymentAdapter(ABC):
    """Abstract base class for payment providers."""

    @property
    @abstractmethod
    def provider(self) -> PaymentProvider:
        """Return the payment provider type."""
        pass

    @abstractmethod
    async def create_payment(
        self,
        transaction: Transaction,
        amount: float,
        order_id: str,
        **kwargs: Any,
    ) -> dict[str, Any]:
        """
        Create a payment request with the provider.
        
        Returns:
            dict with payment_url, payment_data, or other provider-specific fields
        """
        pass

    @abstractmethod
    async def verify_payment(self, external_id: str, **kwargs: Any) -> dict[str, Any]:
        """
        Verify payment status with the provider.
        
        Returns:
            dict with status, amount, and other verification data
        """
        pass

    @abstractmethod
    async def process_webhook(self, payload: dict[str, Any]) -> dict[str, Any]:
        """
        Process webhook from payment provider.
        
        Returns:
            dict with transaction_id, status, amount, etc.
        """
        pass

    @abstractmethod
    async def refund_payment(self, external_id: str, amount: float | None = None, **kwargs: Any) -> dict[str, Any]:
        """
        Initiate a refund.
        
        Returns:
            dict with refund status and details
        """
        pass
