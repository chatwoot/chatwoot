"""KeyCRM tools exposed to the agents.

KeyCRM OpenAPI: base https://openapi.keycrm.app/v1, Bearer auth, 60 req/min per IP per key.
List endpoints use Laravel-style `filter[...]` query params and return `{"data": [...]}`.
Calls are cached/limited to respect the rate limit, and resilient: any non-200 or shape
mismatch yields None/empty so the agent grounds on "not found" and escalates rather than crashing.
"""
from __future__ import annotations

import time

import httpx
from pydantic import BaseModel

from .. import settings_service

# KeyCRM caps at 60 req/min per IP per key (CLAUDE.md rule #7). A short TTL cache absorbs the
# common case of several agents/turns asking about the same order within a minute.
_TTL_SECONDS = 60.0
_cache: dict[int, tuple[float, "Order | None"]] = {}


class Order(BaseModel):
    id: int
    status: str | None = None
    grand_total: float | None = None
    buyer_name: str | None = None


class Buyer(BaseModel):
    id: int
    full_name: str | None = None
    phone: str | None = None
    email: str | None = None


class Product(BaseModel):
    id: int
    name: str
    price: float | None = None
    in_stock: bool | None = None


def _headers() -> dict[str, str]:
    return {"Authorization": f"Bearer {settings_service.get('keycrm.api_key')}"}


def _base() -> str:
    return settings_service.get("keycrm.base_url").rstrip("/")


async def _get(path: str, params: dict | None = None) -> dict | None:
    if not settings_service.get("keycrm.api_key"):
        return None
    try:
        async with httpx.AsyncClient(timeout=20) as client:
            resp = await client.get(f"{_base()}{path}", headers=_headers(), params=params or {})
    except httpx.HTTPError:
        return None
    if resp.status_code != 200:
        return None
    try:
        return resp.json()
    except ValueError:
        return None


def _status_name(raw) -> str | None:
    if isinstance(raw, dict):
        return raw.get("name")
    return str(raw) if raw is not None else None


def _parse_order(data: dict) -> Order:
    buyer = (data.get("buyer") or {}).get("full_name")
    return Order(
        id=data["id"],
        status=_status_name(data.get("status") or data.get("status_id")),
        grand_total=data.get("grand_total"),
        buyer_name=buyer,
    )


async def get_order(order_id: int) -> Order | None:
    """Fetch a single order by id, including payment/delivery via the `include` param."""
    now = time.monotonic()
    cached = _cache.get(order_id)
    if cached and now - cached[0] < _TTL_SECONDS:
        return cached[1]

    data = await _get(f"/order/{order_id}", {"include": "buyer,payments"})
    order = _parse_order(data) if data else None
    _cache[order_id] = (now, order)
    return order


async def find_buyer(phone: str | None = None, email: str | None = None) -> Buyer | None:
    """Look a customer up in KeyCRM by phone (preferred) or email."""
    for key, value in (("buyer_phone", phone), ("email", email)):
        if not value:
            continue
        payload = await _get("/buyer", {f"filter[{key}]": value, "limit": 1})
        rows = (payload or {}).get("data") or []
        if rows:
            b = rows[0]
            return Buyer(id=b["id"], full_name=b.get("full_name"),
                         phone=b.get("phone"), email=b.get("email"))
    return None


async def list_orders_by_buyer(buyer_id: int, limit: int = 5) -> list[Order]:
    """Return a buyer's most recent orders."""
    payload = await _get("/order", {"filter[buyer_id]": buyer_id, "limit": limit,
                                     "include": "buyer", "sort": "-id"})
    rows = (payload or {}).get("data") or []
    return [_parse_order(r) for r in rows]


async def search_products(query: str, limit: int = 5) -> list[Product]:
    """Search the catalogue by name for availability/price grounding."""
    payload = await _get("/products", {"filter[name]": query, "limit": limit})
    rows = (payload or {}).get("data") or []
    products: list[Product] = []
    for r in rows:
        qty = r.get("quantity")
        products.append(Product(
            id=r["id"], name=r.get("name") or f"#{r['id']}",
            price=r.get("price") or r.get("min_price"),
            in_stock=(qty > 0) if isinstance(qty, (int, float)) else None,
        ))
    return products
