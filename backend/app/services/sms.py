from __future__ import annotations

import logging

from app.core.config import get_settings

logger = logging.getLogger(__name__)


class SMSProvider:
    def __init__(self) -> None:
        self.settings = get_settings()

    async def send_code(self, *, phone_number: str, code: str) -> None:
        if self.settings.sms_provider in {"mock", "dev"}:
            logger.info("Sending OTP %s to %s", code, phone_number)
            return
        # TODO: integrate with real SMS providers (Infobip, Beeline, etc.)
        raise NotImplementedError("Real SMS provider integration is not configured")


def get_sms_provider() -> SMSProvider:
    return SMSProvider()
