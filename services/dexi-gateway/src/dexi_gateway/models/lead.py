"""Modelo canônico de lead – forma normalizada que trafega entre Gateway e workers."""

from __future__ import annotations

from datetime import UTC, datetime
from enum import StrEnum
from typing import Any

from pydantic import BaseModel, EmailStr, Field


class LeadChannel(StrEnum):
    META = "meta"
    GOOGLE = "google"
    SITE = "site"
    WHATSAPP = "whatsapp"
    PORTAL = "portal"
    CALL = "call"


class LeadPhone(BaseModel):
    number: str
    country_code: str | None = None


class LeadCustomer(BaseModel):
    external_id: str = Field(..., description="Chave natural para dedup (CPF/CNPJ, tel, email)")
    first_name: str | None = None
    last_name: str | None = None
    document_number: str | None = None
    phones: list[LeadPhone] = Field(default_factory=list)
    emails: list[EmailStr] = Field(default_factory=list)


class LeadAttribution(BaseModel):
    gclid: str | None = None
    fbclid: str | None = None
    utm_source: str | None = None
    utm_medium: str | None = None
    utm_campaign: str | None = None
    utm_term: str | None = None
    utm_content: str | None = None


class LeadIntent(BaseModel):
    brand: str | None = None
    model: str | None = None
    price_range: str | None = None
    observations: str | None = None
    score: float | None = Field(default=None, ge=0.0, le=1.0)


class NormalizedLead(BaseModel):
    lead_id: str
    tenant_id: str
    channel: LeadChannel
    received_at: datetime = Field(default_factory=lambda: datetime.now(UTC))
    customer: LeadCustomer
    attribution: LeadAttribution = Field(default_factory=LeadAttribution)
    intent: LeadIntent = Field(default_factory=LeadIntent)
    raw_payload: dict[str, Any] = Field(default_factory=dict, repr=False)
