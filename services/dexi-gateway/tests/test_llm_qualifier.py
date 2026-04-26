from dexi_gateway.llm.qualifier import qualify
from dexi_gateway.models.lead import (
    LeadAttribution,
    LeadChannel,
    LeadCustomer,
    LeadIntent,
    NormalizedLead,
)


def _lead(obs: str, gclid: str | None = None) -> NormalizedLead:
    return NormalizedLead(
        lead_id="l",
        tenant_id="t",
        channel=LeadChannel.SITE,
        customer=LeadCustomer(external_id="x"),
        attribution=LeadAttribution(gclid=gclid),
        intent=LeadIntent(observations=obs),
    )


def test_mock_detects_toro_and_fiat():
    out = qualify(_lead("Quero saber sobre a Toro"))
    assert out.brand == "Fiat"
    assert out.model == "Toro"
    assert out.score is not None and out.score > 0.5


def test_mock_boosts_when_has_gclid():
    out = qualify(_lead("Interessado na Hilux", gclid="g1"))
    assert out.brand == "Toyota"
    assert out.model == "Hilux"
    assert out.score is not None and out.score >= 0.75
