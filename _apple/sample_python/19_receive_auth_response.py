# Copyright 2025 Apple, Inc.
# All Rights Reserved.

import base64
import gzip
import json
from io import BytesIO

import jwt

from flask import Flask, request, abort

from config import MSP_ID, SECRET

app = Flask(__name__)


@app.route("/message", methods=["POST"])
def receive_auth_response():

    # Verify the authentication
    try:
        authorization = request.headers.get("Authorization")
    except TypeError:
        print("SYSTEM: jwt_token get error.")
        abort(400)

    try:
        jwt_token = authorization[7:]    # <-- skip the Bearer prefix
    except TypeError:
        print("SYSTEM: jwt_token authorization error.")
        abort(400)

    try:
        jwt.decode(jwt=jwt_token,
                   key=base64.b64decode(SECRET),
                   audience=MSP_ID,
                   algorithms=["HS256"])
    except Exception:
        print("SYSTEM: Authorization failed.")
        abort(403)

    # read the Gzip data
    fileobj = BytesIO(request.data)
    uncompressed = gzip.GzipFile(fileobj=fileobj, mode="rb")
    try:
        payj = uncompressed.read()
    except IOError:
        print("SYSTEM: Payload decompression error.")
        abort(400)

    # decode JSON
    try:
        payload = json.loads(payj)
    except ValueError:
        print("SYSTEM: Payload decode error.")
        abort(400)

    print("payload %s" % payload)
    message_type = payload.get("type")
    if message_type != "interactive":
        print("Received a %s instead of an interactive message." % message_type)
        return "ok"

    try:
        interactive_data = payload["interactiveData"]
    except KeyError:
        interactive_data = payload
    print("interactive_data: %s" % interactive_data)

    try:
        request_id = interactive_data["data"]["requestIdentifier"]
    except KeyError:
        print("SYSTEM: Unable to retrieve the requestIdentifier.")
        return "ok"
    print("request_id: %s" % request_id)

    try:
        auth_status = interactive_data["data"]["authenticate"]["status"]
    except KeyError:
        print("SYSTEM: Unable to retrieve the status.")
        return "ok"
    print("status: %s" % auth_status)

    try:
        encrypted_token = interactive_data["data"]["authenticate"]["token"]
    except KeyError:
        print("SYSTEM: Unable to retrieve the encrypted token.")
        return "ok"
    else:
        print("encrypted_token: %s" % encrypted_token)


    print("Our work is done for this routine.")

    return "ok"


app.run(host="0.0.0.0", port=8003)

# Expected output:
# payload {'type': 'interactive', 'id': '5eb1<REDACTED>, 'replyMessage': {'title': 'You Signed In', 'style': 'icon', 'alternateTitle': 'You Signed In'}, 'version': '1.0'}, 'sessionIdentifier': '6a8a3<REDACTED>'}
# request_id: 6161<REDACTED>
# status: authenticated
# encrypted_token: BPkAIU<REDACTED>==
# Our work is done for this routine.