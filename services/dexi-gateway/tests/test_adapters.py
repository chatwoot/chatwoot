from dexi_gateway.adapters import google, meta, site, whatsapp


def test_meta_normalize_minimal():
    body = {
        "object": "page",
        "entry": [
            {
                "changes": [
                    {
                        "value": {
                            "leadgen_id": "999",
                            "ad_id": "camp_1",
                            "field_data": [
                                {"name": "full_name", "values": ["Lorrayne Paraiso"]},
                                {"name": "email", "values": ["l@example.com"]},
                                {"name": "phone_number", "values": ["+5541999999999"]},
                                {"name": "vehicle", "values": ["Toro"]},
                            ],
                        }
                    }
                ]
            }
        ],
    }
    lead = meta.normalize(body, tenant_id="t1")
    assert lead.channel == "meta"
    assert lead.customer.first_name == "Lorrayne"
    assert lead.customer.last_name == "Paraiso"
    assert lead.customer.emails == ["l@example.com"]
    assert lead.customer.phones[0].number == "+5541999999999"
    assert lead.intent.model == "Toro"
    assert lead.attribution.utm_source == "facebook"


def test_google_normalize_with_gclid():
    body = {
        "lead_id": "abc",
        "form_id": "f1",
        "gcl_id": "gclid-xyz",
        "campaign_id": "c1",
        "user_column_data": [
            {"column_id": "FULL_NAME", "string_value": "João Silva"},
            {"column_id": "EMAIL", "string_value": "joao@example.com"},
            {"column_id": "PHONE_NUMBER", "string_value": "+5541988888888"},
            {"column_id": "vehicle", "string_value": "Hilux"},
        ],
    }
    lead = google.normalize(body, tenant_id="t1")
    assert lead.attribution.gclid == "gclid-xyz"
    assert lead.intent.model == "Hilux"
    assert lead.customer.external_id == "abc"


def test_site_normalize_portuguese_fields():
    body = {
        "nome": "Maria",
        "sobrenome": "Souza",
        "telefone": "+554199",
        "email": "m@x.com",
        "marca": "Jeep",
        "modelo": "Compass",
        "gclid": "g1",
        "fbclid": "f1",
    }
    lead = site.normalize(body, tenant_id="t1")
    assert lead.customer.first_name == "Maria"
    assert lead.intent.brand == "Jeep"
    assert lead.attribution.gclid == "g1"
    assert lead.attribution.fbclid == "f1"


def test_whatsapp_normalize():
    body = {
        "entry": [
            {
                "changes": [
                    {
                        "value": {
                            "contacts": [{"wa_id": "5541999", "profile": {"name": "Ana"}}],
                            "messages": [{"from": "5541999", "text": {"body": "tenho interesse na Toro"}}],
                        }
                    }
                ]
            }
        ]
    }
    lead = whatsapp.normalize(body, tenant_id="t1")
    assert lead.channel == "whatsapp"
    assert lead.customer.external_id == "5541999"
    assert "Toro" in (lead.intent.observations or "")
