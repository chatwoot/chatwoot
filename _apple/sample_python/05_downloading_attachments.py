# Copyright 2025 Apple, Inc.
# All Rights Reserved.

import base64
import gzip
import json
import requests
from io import BytesIO

from flask import Flask, request

from attachment_cipher import decrypt
from config import BIZ_ID, AMB_SERVER
from jwt_util import get_jwt_token

app = Flask(__name__)


@app.route("/message", methods=["POST"])
def receive_message():
    # read the Gzip data
    fileobj = BytesIO(request.data)
    uncompressed = gzip.GzipFile(fileobj=fileobj, mode="rb")
    payload = json.loads(uncompressed.read())

    message_type = payload.get("type")

    if message_type != "text":
        return "Ignoring other types of messages."

    if "attachments" not in payload:
        return "Did not receive any attachments."

    message_attachments_array = payload.get("attachments")
    print("%s attachments found in the message." % len(message_attachments_array))

    for attachment in message_attachments_array:
        attachment_file_name = attachment.get("name")
        decryption_key = attachment.get("key")
        mmcs_url = attachment.get("url")
        mime_type = attachment.get("mimeType")
        mmcs_owner = attachment.get("owner")
        file_size = attachment.get("size")

        print("File %s is MIME-Type %s" % (attachment_file_name,mime_type ))

        # get hex encoded signature and convert to base64
        hex_encoded_signature = attachment.get("signature")
        signature = base64.b16decode(hex_encoded_signature)
        base64_encoded_signature = base64.b64encode(signature)

        predownload_headers = {
            "Authorization": "Bearer %s" % get_jwt_token(),
            "source-id": BIZ_ID,
            "MMCS-Url": mmcs_url,
            "MMCS-Signature": base64_encoded_signature,
            "MMCS-Owner": mmcs_owner
        }

        r = requests.get("%s/preDownload" % AMB_SERVER,
                         headers=predownload_headers,
                         timeout=10)

        download_url = json.loads(r.content).get("download-url")

        # download the attachment data with GET request
        encrypted_attachment_data = requests.get(download_url).content

        # compare download size with expected file size
        if len(encrypted_attachment_data) != file_size:
            raise Exception("Data downloaded not of expected size! Check preDownload step.")

        # decrypted the downloaded data
        decrypted_attachment_data = decrypt(encrypted_attachment_data, decryption_key)

        print("writing to local file: %s" % attachment_file_name)
        with open(attachment_file_name, "wb") as attachment_local_file:
            attachment_local_file.write(decrypted_attachment_data)

    return "ok"


app.run(host="0.0.0.0", port=8003)

# Expected output:
# 2 attachments found in the message.
# File 52106351067__A31A08AE-A449-4EDD-A735-458D17ADF9EA.JPG is MIME-Type image/jpg
# writing to local file: 52106351067__A31A08AE-A449-4EDD-A735-458D17ADF9EA.JPG
# File 52106351346__8CEE7676-0E8C-4D19-83B5-C680836837CC.JPG is MIME-Type image/jpg
# writing to local file: 52106351346__8CEE7676-0E8C-4D19-83B5-C680836837CC.JPG

# Attachments should have been saved as local files under current path
