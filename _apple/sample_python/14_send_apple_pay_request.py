# Copyright 2025 Apple, Inc.
# All Rights Reserved.

import hashlib
import json
import requests
import uuid

from config import BIZ_ID, AMB_SERVER, IMESSAGE_EXTENSION_BID
from jwt_util import get_jwt_token

APPLE_PAY_MERCHANT_SESSION_GATEWAY = "https://apple-pay-gateway.apple.com/paymentservices/paymentSession"

MY_MERCHANT_ID = "<your.merchant.id>"
MY_DOMAIN_NAME = "<your.verified.domain.name>"
MY_MERCHANT_NAME = "<your merchant name>"

MY_PEM_FILE_PATH = "<local path to your .pem file>"
MY_PAYMENT_GATEWAY_URL = "https://<your.payment.gateway.domain>/paymentGateway"

def get_apple_pay_merchant_session():
    payload = json.dumps({
        "merchantIdentifier": MY_MERCHANT_ID,
        "domainName": MY_DOMAIN_NAME,
        "displayName": MY_MERCHANT_NAME,
        "initiative": "messaging",
        "initiativeContext": MY_PAYMENT_GATEWAY_URL
    })

    headers = {"content-type": "application/json"}

    response = requests.request("POST",
                                APPLE_PAY_MERCHANT_SESSION_GATEWAY,
                                data=payload,
                                headers=headers,
                                cert=MY_PEM_FILE_PATH)

    merchant_session = json.loads(response.text)
    return merchant_session


def send_apple_pay_request(destination_id):
    message_id = str(uuid.uuid4())  # generate unique message id
    request_id = str(uuid.uuid4())  # generate unique request id

    headers = {
        "Content-Type": "application/json",
        "Authorization": "Bearer %s" % get_jwt_token(),
        "id": message_id,
        "Source-Id": BIZ_ID,
        "Destination-Id": destination_id
    }

    interactive_data = {
        "receivedMessage": {
            "style": "icon",
            "title": "Payment Title",
            "subtitle": "Payment Subtitle"
        },
        "bid": IMESSAGE_EXTENSION_BID,
        "data": {
            "requestIdentifier": request_id,
            "mspVersion": "1.0",
            "payment": {
                "paymentRequest": {
                    "lineItems": [
                        {
                            "label": "Item 1",
                            "amount": "10.00",
                            "type": "final"
                        }
                    ],
                    "total": {
                        "label": "Your Total",
                        "amount": "10.00",
                        "type": "final"
                    },
                    "applePay": {
                        "merchantIdentifier": MY_MERCHANT_ID,
                        "supportedNetworks": [
                            "amex",
                            "visa",
                            "discover",
                            "masterCard",
                            "chinaUnionPay",
                            "interac",
                            "privateLabel"
                        ],
                        "merchantCapabilities": [
                            "supportsDebit",
                            "supportsCredit",
                            "supportsEMV",
                            "supports3DS"
                        ]
                    },
                    "merchantName": MY_MERCHANT_NAME,
                    "countryCode": "US",
                    "currencyCode": "USD",
                    "requiredBillingContactFields": [],
                    "requiredShippingContactFields": []
                },
                "merchantSession": get_apple_pay_merchant_session(),
                "endpoints": {
                    "paymentGatewayUrl": MY_PAYMENT_GATEWAY_URL
                }
            }
        }
    }

    payload = {
        "v": 1,
        "type": "interactive",
        "interactiveData": interactive_data,
        "id": message_id,
        "sourceId": BIZ_ID,
        "destinationId": destination_id
    }

    r = requests.post("%s/message" % AMB_SERVER,
                      json=payload,
                      headers=headers,
                      timeout=10)

    print("Messages for Business server return code: %s" % r.status_code)


if __name__ == "__main__":
    destination_id = "<source_id from previously received message>"
    send_apple_pay_request(destination_id)

# Expected output:
# Messages for Business server return code: 200
