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
MY_BASE_DOMAIN_URL = "https://<your.base.handler.domain>"

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

    merch = get_apple_pay_merchant_session()

    fallback_url = MY_BASE_DOMAIN_URL + "/fallback"
    order_tracking_url = MY_BASE_DOMAIN_URL + "/orderTracking"
    payment_method_url = MY_BASE_DOMAIN_URL + "/paymentMethodUpdate"
    shipping_contact_url = MY_BASE_DOMAIN_URL + "/shippingContactUpdate"
    shipping_method_url = MY_BASE_DOMAIN_URL + "/shippingMethodUpdate"

    headers = {
        "Content-Type": "application/json",
        "Authorization": "Bearer %s" % get_jwt_token(),
        "id": message_id,
        "Source-Id": BIZ_ID,
        "Destination-Id": destination_id
    }

    interactive_data = {
        "receivedMessage": {
            "imageIdentifier": "1",
            "style": "large",
            "subtitle": "We'll see you there!",
            "title": "Adopt a Pet with Apple Pay"
        },
        "replyMessage": {
            "imageIdentifier": "1",
            "style": "large",
            "title": "Pet Adoption Fee"
        },
        "bid": IMESSAGE_EXTENSION_BID,
        "data": {
            "images": [
                {
                    "data": "/9j/4AAQSkZ <truncated>",
                    "identifier": "1"
                }
            ],
            "requestIdentifier": request_id,
            "version": "1.0",
            "payment": {
                "paymentRequest": {
                    "lineItems": [
                        {
                            "label": "Adoption fee",
                            "amount": "1.50",
                            "type": "final"
                        },
                        {
                            "label": "Required shots",
                            "amount": "1.00",
                            "type": "final"
                        },
                        {
                            "label": "Outtake fee",
                            "amount": "2.00",
                            "type": "final"
                        },
                        {
                            "label": "Daily discount",
                            "amount": "-1.00",
                            "type": "final"
                        }
                    ],
                    "total": {
                        "label": "Your Total",
                        "amount": "3.50",
                        "type": "final"
                    },
                    "applePay": {
                        "merchantIdentifier": MY_MERCHANT_ID,
                        "supportedNetworks": [
                            "amex",
                            "visa",
                            "discover",
                            "masterCard"
                        ],
                        "merchantCapabilities": [
                            "supportsDebit",
                            "supportsCredit",
                            "supports3DS"
                        ]
                    },
                    "countryCode": "US",
                    "currencyCode": "USD",
                    "requiredBillingContactFields": [ "post" ],
                    "requiredShippingContactFields": [ "post", "name", "phone", "email" ],
                    "shippingMethods": [{
                            "label": "Free Shipping",
                            "detail": "Arrives in 8 to 10 days",
                            "amount": "0.00",
                            "identifier": "flat_rate_shipping_id_1"
                        }, {
                            "label": "UPS Ground $0.28",
                            "detail": "Arrives in 5 to 7 days",
                            "amount": "0.28",
                            "identifier": "flat_rate_shipping_id_2"
                        }, {
                            "label": "UPS 1 Day $2.19",
                            "detail": "Arrives in 1 to 2 days",
                            "amount": "2.19",
                            "identifier": "flat_rate_shipping_id_3"
                        }]
                },
                "merchantSession": merch,
                "endpoints": {
                    "paymentGatewayUrl": MY_PAYMENT_GATEWAY_URL,
                    "fallbackUrl": fallback_url,
                    "orderTrackingUrl": order_tracking_url,
                    "paymentMethodUpdateUrl": payment_method_url,
                    "shippingContactUpdateUrl": shipping_contact_url,
                    "shippingMethodUpdateUrl": shipping_method_url
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
