"""KeyCRM tool functions: buyer lookup, orders-by-buyer, product search (HTTP mocked)."""
from __future__ import annotations

import pytest

from app.tools import keycrm


@pytest.fixture(autouse=True)
def _api_key(monkeypatch):
    from app import settings_service

    monkeypatch.setattr(settings_service, "get",
                        lambda k: "key" if k == "keycrm.api_key" else "https://api/v1")


async def test_find_buyer_by_phone(monkeypatch):
    calls = {}

    async def fake_get(path, params=None):
        calls["path"], calls["params"] = path, params
        return {"data": [{"id": 9, "full_name": "Olena", "phone": "+380...", "email": "o@x.ua"}]}

    monkeypatch.setattr(keycrm, "_get", fake_get)
    buyer = await keycrm.find_buyer(phone="+380...")
    assert buyer.id == 9 and buyer.full_name == "Olena"
    assert calls["path"] == "/buyer"
    assert calls["params"]["filter[buyer_phone]"] == "+380..."


async def test_find_buyer_returns_none_when_empty(monkeypatch):
    async def fake_get(path, params=None):
        return {"data": []}

    monkeypatch.setattr(keycrm, "_get", fake_get)
    assert await keycrm.find_buyer(phone="x", email="y@z") is None


async def test_list_orders_by_buyer(monkeypatch):
    async def fake_get(path, params=None):
        assert params["filter[buyer_id]"] == 9
        return {"data": [
            {"id": 101, "status": {"name": "shipped"}, "grand_total": 250.0},
            {"id": 100, "status": "new", "grand_total": 99.0},
        ]}

    monkeypatch.setattr(keycrm, "_get", fake_get)
    orders = await keycrm.list_orders_by_buyer(9)
    assert [o.id for o in orders] == [101, 100]
    assert orders[0].status == "shipped" and orders[1].status == "new"


async def test_search_products_parses_stock(monkeypatch):
    async def fake_get(path, params=None):
        return {"data": [
            {"id": 1, "name": "Kettle", "price": 30.0, "quantity": 5},
            {"id": 2, "name": "Toaster", "price": 45.0, "quantity": 0},
        ]}

    monkeypatch.setattr(keycrm, "_get", fake_get)
    products = await keycrm.search_products("kitchen")
    assert products[0].in_stock is True
    assert products[1].in_stock is False


async def test_get_returns_none_without_api_key(monkeypatch):
    from app import settings_service

    monkeypatch.setattr(settings_service, "get", lambda k: "")
    assert await keycrm._get("/buyer") is None
