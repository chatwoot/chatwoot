"""KeyCRM tools exposed to the agents.

KeyCRM OpenAPI: base https://openapi.keycrm.app/v1, Bearer auth, 60 req/min per IP per key.
Keep calls cached/batched to respect the rate limit.
"""
from __future__ import annotations

import httpx
from pydantic import BaseModel

from ..config import settings


class Order(BaseModel):
    id: int
    status: str | None = None
    grand_total: float | None = None
    buyer_name: str | None = None


def _headers() -> dict[str, str]:
    return {"Authorization": f"Bearer {settings.keycrm_api_key}"}


async def get_order(order_id: int) -> Order | None:
    """Fetch a single order by id, including payment/delivery via the `include` param."""
    url = f"{settings.keycrm_base_url.rstrip('/')}/order/{order_id}"
    async with httpx.AsyncClient(timeout=20) as client:
        resp = await client.get(url, headers=_headers(), params={"include": "buyer,payments"})
    if resp.status_code != 200:
        return None
    data = resp.json()
    buyer = (data.get("buyer") or {}).get("full_name")
    return Order(
        id=data["id"],
        status=(data.get("status") or {}).get("name") if isinstance(data.get("status"), dict) else data.get("status_id"),
        grand_total=data.get("grand_total"),
        buyer_name=buyer,
    )
