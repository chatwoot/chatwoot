# Copyright 2025 Apple, Inc.
# All Rights Reserved.

import base64
import time
import jwt

from config import MSP_ID, SECRET


def get_jwt_token():
    alg_headers = {"alg": "HS256"}
    claim_payload = {
        "iss": MSP_ID,
        "iat": int(time.time())  # unit: seconds
    }
    jwt_token_binary = jwt.encode(claim_payload,
                           base64.b64decode(SECRET),
                           algorithm="HS256",
                           headers=alg_headers)
    jwt_token = jwt_token_binary.decode("utf-8")
    return jwt_token

if __name__ == "__main__":
    print(get_jwt_token())
