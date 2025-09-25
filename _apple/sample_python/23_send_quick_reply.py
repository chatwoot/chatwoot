# Copyright 2025 Apple, Inc.
# All Rights Reserved.

import requests
import uuid

from config import BIZ_ID, AMB_SERVER
from jwt_util import get_jwt_token

def send_quick_reply(destination_id):
    message_id = str(uuid.uuid4())
    request_id = str(uuid.uuid4())

    headers ={
       "Content-Type": "application/json",
       "Authorization": "Bearer %s" % get_jwt_token(),
       "id": message_id,
       "Source-Id": BIZ_ID,
       "Destination-Id": destination_id
    }

    payload ={
       "sourceId": BIZ_ID,
       "destinationId": destination_id,
       "v": 1,
       "type": "interactive",
       "id": message_id,
       "interactiveData": {
          "bid": "com.apple.messages.MSMessageExtensionBalloonPlugin:0000000000:com.apple.icloud.apps.messages.business.extension",
          "data": {
             "quick-reply": {
                "summaryText":" What can I help you with?",
                "items": [
                   {
                      "identifier": "1",
                      "title": "Watch our video"
                   },
                   {
                      "identifier": "2",
                      "title": "Ask for office hours"
                   },
                   {
                      "identifier": "3",
                      "title": "Find more about pet adoption"
                   },
                   {
                      "identifier": "4",
                      "title": "Talk to an agent"
                   }
                ]
             },
             "version": "1.0",
             "requestIdentifier": request_id
          }
       }
    }

    r = requests.post("%s/message" % AMB_SERVER,json=payload,headers=headers,timeout=10)
    print("Messages for Business server return code: %s" % r.status_code)

if __name__ == "__main__":
    destination_id = "<use-value-from-previous-exercises>"
    send_quick_reply(destination_id)

# Expected output:
# Messages for Business server return code: 200