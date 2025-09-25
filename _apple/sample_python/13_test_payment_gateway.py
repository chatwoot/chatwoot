# Copyright 2025 Apple, Inc.
# All Rights Reserved.

import base64
import gzip
import json

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
def receive_payload():
    """Handle the interactive payload sent from the user"""
    print("Response received.")
    return "ok"


app.run(host="0.0.0.0", port=8003)

# Expected output:
# Payment received!
# Request Identifier: <request identifier in message payload>
# Payment Method Dictionary: {'displayName': 'Visa 1234', 'type': 'Credit', 'network': 'Visa'}
