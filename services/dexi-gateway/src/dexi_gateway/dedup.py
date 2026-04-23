"""Dedup por `tenant_id + external_id` em Redis. Janela configurável."""

from __future__ import annotations

import contextlib
import threading

import redis

from .config import get_settings

_client: redis.Redis | None = None
_client_lock = threading.Lock()


def _get_redis() -> redis.Redis:
    """Retorna um cliente Redis singleton (pool de conexões reaproveitado)."""
    global _client
    if _client is None:
        with _client_lock:
            if _client is None:
                _client = redis.from_url(get_settings().redis_url, decode_responses=True)
    return _client


def _key(tenant_id: str, external_id: str) -> str:
    return f"dedup:{tenant_id}:{external_id}"


def seen_recently(tenant_id: str, external_id: str) -> bool:
    """Marca o par `tenant_id + external_id` como visto usando SET NX EX, atômico.

    Se o SET NX não cria a chave (já existia), o lead é duplicado.
    Isso evita TOCTOU entre múltiplos workers/replicas e reaproveita a conexão.
    """
    s = get_settings()
    r = _get_redis()
    was_set = r.set(_key(tenant_id, external_id), "1", ex=s.dedup_window_hours * 3600, nx=True)
    return not was_set


def reset_client_for_tests() -> None:
    """Permite invalidar o singleton entre testes que trocam `REDIS_URL`."""
    global _client
    with _client_lock:
        if _client is not None:
            with contextlib.suppress(Exception):
                _client.close()
        _client = None
