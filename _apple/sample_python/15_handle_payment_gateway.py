# Copyright 2025 Apple, Inc.
# All Rights Reserved.

import base64
import gzip
import json
from io import BytesIO
from flask import abort, Flask, request
import jwt

from config import MSP_ID, SECRET


app = Flask(__name__)


@app.route("/paymentGateway", methods=["POST"])
def process_payment():
    """Act as payment gateway for Apple Pay and return appropriate response"""
    payment_payload = json.loads(request.data)
    print("Payment received!")
    print("Request Identifier: %s" % payment_payload.get("requestIdentifier"))
    print("Payment Method Dictionary: %s" % str(
        payment_payload.get("payment").get("paymentToken").get("paymentMethod"))
    )

    # This is where the payment would be processed
    # In this example, payments received are approved, but
    # no actual payment is happening here

    response = app.response_class(
        response=json.dumps({
            "status": "STATUS_SUCCESS"
        }),
        status=200,
        mimetype="application/json"
    )
    return response


@app.route("/message", methods=["POST"])
def receive_large_interactive_payload():
    """Handle the interactive payload sent from the user"""

    # Verify the authentication
    try:
        authorization = request.headers.get("Authorization")
    except TypeError as ezero:
        print("SYSTEM: jwt_token get error: %s" % ezero)
        abort(400)

    try:
        jwt_token = authorization[7:]    # <-- skip the Bearer prefix
    except TypeError as eone:
        print("SYSTEM: jwt_token authorization error: %s" % eone)
        abort(400)

    try:
        jwt.decode(jwt=jwt_token,
                   key=base64.b64decode(SECRET),
                   audience=MSP_ID,
                   algorithms=["HS256"])
    except Exception as etwo:
        print("SYSTEM: Authorization failed, error message: %s" % etwo)
        abort(403)

    # read the Gzip data
    fileobj = BytesIO(request.data)
    uncompressed = gzip.GzipFile(fileobj=fileobj, mode="rb")
    try:
        payj = uncompressed.read()
    except IOError as ethree:
        print("SYSTEM: Payload decompression error: %s" % ethree)
        abort(400)

    # decode JSON
    try:
        payload = json.loads(payj)
    except ValueError as efour:
        print("SYSTEM: Payload decode error: %s" % efour)
        abort(400)

    print("payload %s" % payload)
    return "ok"


@app.route("/fallback", methods=['POST'])
def process_fallback():
    print("Fallback received!")
    try:
        fallback_payload = json.loads(request.data)
    except ValueError:
        fallback_payload = None

    print("fallback_payload: %s" % fallback_payload)
    return "ok"


@app.route("/paymentMethodUpdate", methods=['POST'])
def process_paymentmethodupdate():
    # Expected Request Data:
    # {"payment":{"paymentMethod":{"type":"Credit"}},"version":"1.0","requestIdentifier":"77d5a<truncated>"}
    print("paymentMethodUpdate received!")

    try:
        paymentmethodupdate_payload = json.loads(request.data)
    except ValueError:
        # Log Error
        return json.dumps({}), 200

    print("Request Identifier: %s" % paymentmethodupdate_payload["requestIdentifier"])

    # Determines if payment method requires an extra charge
    if paymentmethodupdate_payload["payment"]["paymentMethod"]["type"] == "Credit":
        update = {
            "newLineItems": [{
                    "label": "Adoption fee",
                    "amount": "1.50",
                    "type": "final"
                },{
                    "label": "Required shots",
                    "amount": "1.00",
                    "type": "final"
                },{
                    "label": "Outtake fee",
                    "amount": "2.00",
                    "type": "final"
                },{
                    "label": "Daily discount",
                    "amount": "-1.00",
                    "type": "final"
                },{
                    "label": "Credit card processing fee",
                    "amount": "0.50",
                    "type": "final"
                }],
            "newTotal": {
                "amount": "4.00",
                "label": "Total",
                "type": "final"
                }
            }
    else:
        # Does not update shopping cart if not needed
        update = {}

    return json.dumps(update), 200


@app.route("/orderTracking", methods=['POST'])
def process_ordertracking():
    print("orderTracking received!")
    try:
        ordertracking_payload = json.loads(request.data)
    except ValueError:
        ordertracking_payload = None

    print("ordertracking_payload: %s" % ordertracking_payload)
    return "ok"


@app.route("/shippingContactUpdate", methods=['POST'])
def process_shippingcontactupdate():
    # Expected Request Data:
    # {"payment":{"shippingContact":{"postalCode":"90210","phoneticFamilyName":"","country":"United States","phoneticGivenName":"","addressLines":[""],"countryCode":"US","locality":"Beverly Hills","administrativeArea":"CA","familyName":"","givenName":"","subLocality":""}},"requestIdentifier":"77d5a<truncated>","version":"1.0"}
    print("shippingContactUpdate received!")
    try:
        shippingcontactupdate_payload = json.loads(request.data)
    except ValueError:
        # Log Error
        return json.dumps({}), 200

    print("Request Identifier: %s" % shippingcontactupdate_payload["requestIdentifier"])

    # Determines the shipping price or tax depending on the location of the customer
    # In a production system, we would compute the total with a shopping cart program
    #    For illustration here, we hard code these amounts, assuming the payment type
    #    is credit card, as added above
    if shippingcontactupdate_payload["payment"]["shippingContact"]["postalCode"] == "90210":
        update = {
            "newLineItems": [{
                    "label": "Adoption fee",
                    "amount": "1.50",
                    "type": "final"
                },{
                    "label": "Required shots",
                    "amount": "1.00",
                    "type": "final"
                },{
                    "label": "Outtake fee",
                    "amount": "2.00",
                    "type": "final"
                },{
                    "label": "Daily discount",
                    "amount": "-1.00",
                    "type": "final"
                },{
                    "label": "Special Processing Fee",
                    "amount": "0.50",
                    "type": "final"
                },{
                    "label": "FedEx Priority Mail",
                    "amount": "3.99",
                    "type": "final"
                }],
            "newTotal": {
                "amount": "7.99",
                "label": "Total",
                "type": "final"
                }
            }
    else:
        # For other ZIP codes, we set these items to zero
        # Alternatively, you can set the newLineItems to a null array
        update = {
            "newLineItems": [{
                    "label": "Adoption fee",
                    "amount": "1.50",
                    "type": "final"
                },{
                    "label": "Required shots",
                    "amount": "1.00",
                    "type": "final"
                },{
                    "label": "Outtake fee",
                    "amount": "2.00",
                    "type": "final"
                },{
                    "label": "Daily discount",
                    "amount": "-1.00",
                    "type": "final"
                },{
                    "amount": "0.00",
                    "label": "Special Processing Fee",
                    "type": "final"
                },{
                    "amount": "0.00",
                    "label": "FedEx Priority Mail",
                    "type": "final"
                }],
            "newTotal": {
                "amount": "3.50",
                "label": "Total",
                "type": "final"
                }
            }

    return json.dumps(update), 200


@app.route("/shippingMethodUpdate", methods=['POST'])
def process_shippingmethodupdate():
    # Expected Request Data:
    # {"payment":{"shippingMethod":{"label":"UPS Ground $2.19","amount":"0.19","type":"Final","detail":"2 Business Days","identifier":"flat_rate_shipping_id_2"}},"version":"1.0","requestIdentifier":"77d5a<truncated>"}
    print("shippingMethodUpdate received!")
    try:
        shippingmethodupdate_payload = json.loads(request.data)
    except ValueError:
        # Log Error
        return json.dumps({}), 200

    print("Request Identifier: %s" % shippingmethodupdate_payload["requestIdentifier"])

    # Determines which shipping method the user selected
    # For illustration, we assume the credit card adder but not the zip code adder
    shipping_type = shippingmethodupdate_payload["payment"]["shippingMethod"]["identifier"]
    if shipping_type == "flat_rate_shipping_id_2":
        shipping_amount = "0.28"
        shipping_label = "UPS Ground $0.28"
        total_payment = "3.78"
    elif shipping_type == "flat_rate_shipping_id_3":
        shipping_amount = "2.19"
        shipping_label = "UPS 1 Day $2.19"
        total_payment = "5.69"
    else:
        shipping_amount = "0.00"
        shipping_label = "Free Shipping"
        total_payment = "3.50"

    # Updates the shipping price depending on the select shipping method
    # In a production environment, we would check the requestIdentifier against a database
    #     of shopping cart data. For illustration here, we simply check that it is defined
    if shippingmethodupdate_payload["requestIdentifier"] is not None:
        update = {
            "newLineItems": [{
                    "label": "Adoption fee",
                    "amount": "1.50",
                    "type": "final"
                },{
                    "label": "Required shots",
                    "amount": "1.00",
                    "type": "final"
                },{
                    "label": "Outtake fee",
                    "amount": "2.00",
                    "type": "final"
                },{
                    "label": "Daily discount",
                    "amount": "-1.00",
                    "type": "final"
                },{
                    "label": "Handling fee waived",
                    "amount": "0.00",
                    "type": "final"
                }, {
                    "label": shipping_label,
                    "amount": shipping_amount,
                    "type": "final"
                }],
            "newTotal": {
                    "label": "Total",
                    "amount": total_payment,
                    "type": "final"
                }
            }
    else:
        # Does not update shopping cart if shipping method was not changed
        update = {}

    return json.dumps(update), 200

app.run(host="0.0.0.0", port=8003)

# Expected output:
# Payment received!
# Request Identifier: <request identifier in message payload>
# Payment Method Dictionary: {'displayName': 'Visa 1234', 'type': 'Credit', 'network': 'Visa'}
