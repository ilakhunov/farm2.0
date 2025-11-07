from __future__ import annotations

import re

PHONE_CLEANUP_RE = re.compile(r"[^\d]")


def normalize_phone_number(phone_number: str) -> str:
    digits = PHONE_CLEANUP_RE.sub("", phone_number)
    if digits.startswith("998") and len(digits) == 12:
        return "+" + digits
    if digits.startswith("+"):
        return digits
    if digits.startswith("00"):
        return "+" + digits[2:]
    # Assume Uzbekistan default country code if 9 digits provided
    if len(digits) == 9:
        return "+998" + digits
    if len(digits) == 12 and digits.startswith("998"):
        return "+" + digits
    raise ValueError("Unsupported phone number format")
