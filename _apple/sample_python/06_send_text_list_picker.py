# Copyright 2025 Apple, Inc.
# All Rights Reserved.

import requests
import uuid

from config import BIZ_ID, AMB_SERVER, IMESSAGE_EXTENSION_BID
from jwt_util import get_jwt_token


def send_text_list_picker(destination_id):
    message_id = str(uuid.uuid4())  # generate unique message id

    # a unique request id that will be sent back with response
    request_id = str(uuid.uuid4())

    headers = {
        "Content-Type": "application/json",
        "Authorization": "Bearer %s" % get_jwt_token(),
        "id": message_id,
        "Source-Id": BIZ_ID,
        "Destination-Id": destination_id
    }

    interactive_data = {
        "bid": IMESSAGE_EXTENSION_BID,
        "data": {
            "listPicker": {
                "sections": [
                    {
                        "items": [
                            {
                                "identifier": "1",
                                "order": 0,
                                "style": "default",
                                "subtitle": "Red and delicious",
                                "title": "Apple"
                            },
                            {
                                "identifier": "2",
                                "order": 1,
                                "style": "default",
                                "subtitle": "Vitamin C boost",
                                "title": "Orange"
                            }
                        ],
                        "order": 0,
                        "title": "Fruit",
                        "multipleSelection": True
                    },
                    {
                        "items": [
                            {
                                "identifier": "3",
                                "order": 0,
                                "style": "default",
                                "subtitle": "Crispy greens",
                                "title": "Lettuce"
                            },
                            {
                                "identifier": "4",
                                "order": 1,
                                "style": "default",
                                "subtitle": "Not just for your eye lids",
                                "title": "Cucumber"
                            }
                        ],
                        "order": 1,
                        "title": "Veggies",
                        "multipleSelection": False
                    }
                ]
            },
            "mspVersion": "1.0",
            "requestIdentifier": request_id
        },
        "receivedMessage": {
            "style": "small",
            "subtitle": "Farm fresh to you",
            "title": "Select Produce"
        },
        "replyMessage": {
            "style": "small",
            "title": "Selected Produce",
            "subtitle": "Selected Produce"
        }
    }

    payload = {
        "type": "interactive",
        "interactiveData": interactive_data,
        "sourceId": BIZ_ID,
        "destinationId": destination_id,
        "v": 1,
        "id": message_id
    }

    r = requests.post("%s/message" % AMB_SERVER,
                      json=payload,
                      headers=headers,
                      timeout=10)

    print("Messages for Business server return code: %s" % r.status_code)


if __name__ == "__main__":
    destination_id = "<source_id from previously received message>"
    send_text_list_picker(destination_id)

# Expected output:
# Messages for Business server return code: 200
