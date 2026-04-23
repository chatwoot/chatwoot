"""Dedup por `tenant_id + external_id` em Redis. Janela configurável."""

from __future__ import annotations

import redis

from .config import get_settings


def _key(tenant_id: str, external_id: str) -> str:
    return f"dedup:{tenant_id}:{external_id}"


def seen_recently(tenant_id: str, external_id: str) -> bool:
    """Marca o par `tenant_id + external_id` como visto usando SET NX EX, atômico.

    Se o SET NX não cria a chave (já existia), o lead é duplicado.
    Isso evita TOCTOU entre múltiplos workers/replicas.
    """
    s = get_settings()
    r = redis.from_url(s.redis_url, decode_responses=True)
    key = _key(tenant_id, external_id)
    was_set = r.set(key, "1", ex=s.dedup_window_hours * 3600, nx=True)
    return not was_set
