# Copyright 2025 Apple, Inc.
# All Rights Reserved.

import requests
import uuid

from config import BIZ_ID, AMB_SERVER
from jwt_util import get_jwt_token


def send_list_picker_with_data_ref(destination_id, interactive_data_ref):
    message_id = str(uuid.uuid4())  # generate a unique message id

    payload = {
        "v": 1,
        "type": "interactive",
        "id": message_id,
        "sourceId": BIZ_ID,
        "destinationId": destination_id,
        "interactiveDataRef": interactive_data_ref
    }

    headers = {
        "Content-Type": "application/json",
        "Authorization": "Bearer %s" % get_jwt_token(),
        "id": message_id,
        "Source-Id": BIZ_ID,
        "Destination-Id": destination_id
    }

    r = requests.post("%s/message" % AMB_SERVER,
                      json=payload,
                      headers=headers, timeout=10)

    print("Messages for Business server return code: %s" % r.status_code)


if __name__ == "__main__":
    destination_id = "<source_id from previously received message>"
    interactive_data_ref = {}  # Use the dataRef field values returned from previous List Picker message

    send_list_picker_with_data_ref(destination_id, interactive_data_ref)

# Expected output:
# Messages for Business server return code: 200
