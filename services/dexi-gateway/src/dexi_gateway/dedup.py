"""Dedup por `tenant_id + external_id` em Redis. Janela configurável."""

from __future__ import annotations

import redis

from .config import get_settings


def _key(tenant_id: str, external_id: str) -> str:
    return f"dedup:{tenant_id}:{external_id}"


def seen_recently(tenant_id: str, external_id: str) -> bool:
    s = get_settings()
    r = redis.from_url(s.redis_url, decode_responses=True)
    key = _key(tenant_id, external_id)
    if r.exists(key):
        return True
    r.setex(key, s.dedup_window_hours * 3600, "1")
    return False
