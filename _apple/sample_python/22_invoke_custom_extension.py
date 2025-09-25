# Copyright 2025 Apple, Inc.
# All Rights Reserved.

import requests
import uuid

from config import BIZ_ID, AMB_SERVER
from jwt_util import get_jwt_token


def invoke_custom_extension(destination_id):
    message_id = str(uuid.uuid4())

    headers = {
        "Content-Type": "application/json",
        "Authorization": "Bearer %s" % get_jwt_token(),
        "id": message_id,
        "Source-Id": BIZ_ID,
        "Destination-Id": destination_id
    }

    payload = {
        "type": "interactive",
        "interactiveData": {
            "appId": 123456789,
            "appName": "Package Delivery",
            "bid": "com.apple.messages.MSMessageExtensionBalloonPlugin"
                   ":<team-identifier>"
                   ":com.example.apple-samplecode.PackageDelivery<team-identifier>.MessagesExtension",
            "URL": "?name=samplepackage"
                   "&extraCharge=1.5"
                   "&deliveryDate=27-01-2017"
                   "&destinationName=Home"
                   "&street=1infiniteloop"
                   "&state=CA"
                   "&city=Cupertino"
                   "&country=USA"
                   "&postalCode=12345"
                   "&latitude=37.331686"
                   "&longitude=-122.030656"
                   "&isMyLocation=true"
                   "&isFinalDestination=true",
            "receivedMessage": {
                "title": "Package Delivery",
                "subtitle": "Location of Package"
            },
            "useLiveLayout": True
        },
        "attachments": [],
        "id": message_id,
        "sourceId": BIZ_ID,
        "destinationId": destination_id,
        "v": 1
    }

    r = requests.post("%s/message" % AMB_SERVER,
                      json=payload,
                      headers=headers,
                      timeout=10)

    print("Messages for Business server return code: %s" % r.status_code)


if __name__ == "__main__":
    destination_id = "<source_id from previously received message>"
    invoke_custom_extension(destination_id)

# Expected output:
# Messages for Business server return code: 200
