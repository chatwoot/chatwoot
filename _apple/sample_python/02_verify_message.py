# Copyright 2025 Apple, Inc.
# All Rights Reserved.

import base64
import jwt
from flask import Flask, request, abort

from config import MSP_ID, SECRET

app = Flask(__name__)


@app.route("/message", methods=["POST"])
def receive_message():
    # skip the Bearer prefix
    jwt_token = request.headers.get("Authorization")[7:]

    # verify the secret and the audience
    try:
        jwt.decode(jwt_token,
                   base64.b64decode(SECRET),
                   audience=MSP_ID,
                   algorithms=["HS256"])
        print("Authorization succeeded.")
    except Exception as e:
        print("Authorization failed, error message: %s" % e)
        abort(403)

    return "ok"


app.run(host="0.0.0.0", port=8003)

# Expected output:
# Authorization succeeded.
# Authorization succeeded.

# By default you will at least receive 2 messages. One is for typing start, and the other is for the actual message.
