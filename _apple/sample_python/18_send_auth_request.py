# Copyright 2025 Apple, Inc.
# All Rights Reserved.

import uuid

import requests

from auth_util import generate_pair, generate_nonce
from config import BIZ_ID, AMB_SERVER, IMESSAGE_EXTENSION_BID
from jwt_util import get_jwt_token


def authenticate_user(opaque_id):
    """Form an authenticate JSON payload using the parameters for the service and send the request
    to the user."""

    # Set all of the parameters specific to this particular Auth provider
    # For this example, we use LinkedIn OAuth2 API
    #
    # LinkedIn authentication parameters
    # Manage your application here: https://www.linkedin.com/developers/apps
    #
    # OAUTH URL in Register = https://www.linkedin.com/oauth/v2/authorization
    # TOKEN URL in Register = https://www.linkedin.com/oauth/v2/accessToken
    title_to_user = "LinkedIn"
    response_type = "code"
    scope = ["openid", "email", "profile"]

    message_id = str(uuid.uuid4())
    request_id = str(uuid.uuid4())

    # Generate a private and public key, save them to the database with request_id as the
    # index, keep the public key to use in the payload
    (response_encryption_key, privkey_b64) = generate_pair()
    print("Save private key for use later, base 64: %s" % privkey_b64)

    # Also generate a nonce for this request
    state = generate_nonce()

    headers = {
        "Content-Type": "application/json",
        "Authorization": "Bearer %s" % get_jwt_token(),
        "id": message_id,
        "Source-Id": BIZ_ID,
        "Destination-Id": destination_id
    }

    interactive_data = {
        "data": {
            "version": "1.0",
            "requestIdentifier": request_id,
            "authenticate" : {
                "oauth2": {
                    "responseType": response_type,
                    "scope": scope,
                    "state": state,
                   "redirectURI": "<YOUR MSP SERVER ENDPOINT CALLBACK>"
                }
            },
            "images": []
        },
        "bid": IMESSAGE_EXTENSION_BID,
        "receivedMessage": {
            "title": ("Sign In to %s" % title_to_user)
        },
        "replyMessage": {
            "title": "You Signed In"
        }
    }

    payload = {
        "type": "interactive",
        "interactiveData": interactive_data,
        "sourceId": BIZ_ID,
        "destinationId": opaque_id,
        "v": 1,
        "id": message_id
    }

    print(headers)
    print(payload)

    r = requests.post("%s/authenticate" % AMB_SERVER,
                      json=payload,
                      headers=headers,
                      timeout=30)
    print("Messages for Business server return code: %s" % r.status_code)

    print("Send authentication request with parameters")
    print("request_id: %s" % request_id)
    print("responseEncryptionKey: %s" % response_encryption_key)
    print("nonce (aka state): %s" % state)
    print("private key, base64: %s" % privkey_b64)
    return "ok"


if __name__ == "__main__":
    destination_id = "<source_id from previously received message>"
    authenticate_user(destination_id)
