# Copyright 2025 Apple, Inc.
# All Rights Reserved.

import base64
import requests
import uuid

from config import BIZ_ID, AMB_SERVER, IMESSAGE_EXTENSION_BID
from jwt_util import get_jwt_token


def send_list_picker_with_images(destination_id, image_file_path_dict):
    # Array of JSON elements, starts empty
    images_descriptor = []

    # generate a unique message id
    message_id = str(uuid.uuid4())

    # a unique request id that will be sent back with response
    request_id = str(uuid.uuid4())

    for this_image in image_file_path_dict:
        image_full_path = image_file_path_dict[this_image]
        with open(image_full_path, "rb") as image_file:
            image_data_encoded_bytes = base64.b64encode(image_file.read())
            image_data_encoded = image_data_encoded_bytes.decode("utf-8")

        print("%s encoded!" % image_full_path)

        images_descriptor.append(
                    {
                        "data": image_data_encoded,
                        "identifier": this_image
                    }
            )

    headers = {
        "Content-Type": "application/json",
        "Authorization": "Bearer %s" % get_jwt_token(),
        "id": message_id,
        "Source-Id": BIZ_ID,
        "Destination-Id": destination_id,
        "include-data-ref": "true"  # <--- Small bug in the Python requests library requires
                                    #      a string here. In other languages, a Boolean type
                                    #      will suffice
    }

    interactive_data = {
        "bid": IMESSAGE_EXTENSION_BID,
        "data": {
            "images": images_descriptor,
            "listPicker": {
                "sections": [
                    {
                        "items": [
                            {
                                "identifier": "1",
                                "imageIdentifier": "<imageIdentifier 0>",
                                "order": 0,
                                "style": "default",
                                "subtitle": "Red and delicious",
                                "title": "Apple"
                            }
                        ],
                        "order": 0,
                        "title": "Fruit",
                        "multipleSelection": True
                    },
                    {
                        "items": [
                            {
                                "identifier": "2",
                                "imageIdentifier": "<imageIdentifier 1>",
                                "order": 0,
                                "style": "default",
                                "subtitle": "Crispy red",
                                "title": "another apple"
                            }
                        ],
                        "order": 1,
                        "title": "Veggies",
                        "multipleSelection": True
                    }
                ]
            },
            "mspVersion": "1.0",
            "requestIdentifier": request_id
        },
        "receivedMessage": {
            "imageIdentifier": "<imageIdentifier 2>",
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
        "v": 1,
        "type": "interactive",
        "interactiveData": interactive_data,
        "id": message_id,
        "sourceId": BIZ_ID,
        "destinationId": destination_id
    }

    r = requests.post("%s/message" % AMB_SERVER,
                      json=payload,
                      headers=headers, timeout=10)

    print("Messages for Business server return code: %s" % r.status_code)
    print("Messages for Business server response body: %s" % r.text)


if __name__ == "__main__":
    destination_id = "<source_id from previously received message>"

    image_file_path_dict = {
        "<imageIdentifier 0>": "<filesystem path to image 0>",
        "<imageIdentifier 1>": "<filesystem path to image 1>",
        "<imageIdentifier 2>": "<filesystem path to image 2>"
        }

    send_list_picker_with_images(destination_id, image_file_path_dict)

# Expected output:
# Messages for Business server return code: 200
# Messages for Business server response body:
# {
#     "dataRef": {
#         "bid":"<bid save for next exercise>",
#         "owner":"<owner save for next exercise>",
#         "url":"<url save for next exercise>",
#         "size":<size save for next exercise>,
#         "signature":"<signature save for next exercise>",
#         "signature-base64":"<signature-base64 save for next exercise>",
#         "title":"Select Produce",
#         "dataRefSig":"<dataRefSig save for next exercise>"
#     }
# }
