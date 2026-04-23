"""Payload Syonet conforme `POST /api/lead` (PDF oficial)."""

from __future__ import annotations

from pydantic import BaseModel, Field


class SyonetPhone(BaseModel):
    number: str
    type: str | None = None


class SyonetCustomer(BaseModel):
    externalId: str
    firstName: str | None = None
    lastName: str | None = None
    documentNumber: str | None = None
    phones: list[SyonetPhone] = Field(default_factory=list)
    emails: list[str] = Field(default_factory=list)


class SyonetLeadInfo(BaseModel):
    gclid: str | None = None
    fbclid: str | None = None
    utmSource: str | None = None
    utmMedium: str | None = None
    utmCampaign: str | None = None
    utmTerm: str | None = None
    utmContent: str | None = None


class SyonetEvent(BaseModel):
    eventGroup: str
    eventType: str
    leadInfo: SyonetLeadInfo = Field(default_factory=SyonetLeadInfo)


class SyonetNegotiationRecord(BaseModel):
    modelVersionId: int | None = None
    priceRange: str | None = None
    observations: str | None = None


class SyonetLeadRequest(BaseModel):
    companyId: str
    customer: SyonetCustomer
    event: SyonetEvent
    negotiationRecord: SyonetNegotiationRecord | None = None
    additionalFields: dict[str, str] = Field(default_factory=dict)
    daysToUpdateOpenEvent: int = 30


class SyonetLeadResponse(BaseModel):
    leadId: str | int | None = None
    status: str | None = None
    message: str | None = None
