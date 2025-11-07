"""Payment adapter factory."""

from app.models.transaction import PaymentProvider
from app.services.payments.arca import ArcaAdapter
from app.services.payments.base import PaymentAdapter
from app.services.payments.click import ClickAdapter
from app.services.payments.payme import PaymeAdapter


def get_payment_adapter(provider: PaymentProvider) -> PaymentAdapter:
    """Get payment adapter for the specified provider."""
    adapters = {
        PaymentProvider.PAYME: PaymeAdapter,
        PaymentProvider.CLICK: ClickAdapter,
        PaymentProvider.ARCA: ArcaAdapter,
    }
    adapter_class = adapters.get(provider)
    if not adapter_class:
        raise ValueError(f"Unsupported payment provider: {provider}")
    return adapter_class()
