"""Verificação HMAC dos webhooks de entrada (Meta, Google, Site, WhatsApp)."""

import hashlib
import hmac


def verify_sha256(secret: str, raw_body: bytes, signature_header: str | None) -> bool:
    """Header do tipo `sha256=<hex>` (convenção Meta / WhatsApp / Stripe-like)."""
    if not signature_header:
        return False
    expected = hmac.new(secret.encode("utf-8"), raw_body, hashlib.sha256).hexdigest()
    provided = signature_header.removeprefix("sha256=").strip()
    return hmac.compare_digest(expected, provided)
