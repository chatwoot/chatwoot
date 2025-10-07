'''
Large Interactive Messages:

Download the interactive data when a user's reply contains a large attachment or payload.
A user's reply to an interactive message may cause the Interactive Message Dictionaries in the message JSON to grow beyond 10 KB in size. When this happens, the Apple Messages for Business service uploads the original reply message and sends a reference pointer, interactiveDataRef, to the original interactive data response. The keys in the interactiveDataRef contain the pointer to the Messaging service where the payload, or set of large assets, is contained.
As an MSP, your platform must download the reference pointer to obtain the original interactive data response from Apple Messages for Business.



https://register.apple.com/resources/messages/msp-rest-api/type-interactive#interactive-message-types

https://register.apple.com/resources/messages/msp-api-tutorial/advanced-interactive-messaging#large-interactive-messages

'''
import requests
import os
import base64
import json
from Crypto.Cipher import AES
from Crypto.Util import Counter
import gzip
import jwt
from io import BytesIO

from app.config import load_config
from app.utils.jwt_tool import get_jwt_token


'''
    For Crypto libraries use pip3 install pycryptodomeq
'''

def encrypt(data):
    key = os.urandom(32)
    decryption_key = "00%s" % key.hex()

    iv = b""
    iv_vector = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
    for i in iv_vector:
        iv += bytes([i])

    ctr = Counter.new(128, initial_value=int(iv.hex(), 16))
    cipher = AES.new(key, AES.MODE_CTR, counter=ctr)
    encrypted_data = cipher.encrypt(data)

    return encrypted_data, decryption_key


def decrypt(encrypted_data, orig_key):
    key = base64.b16decode(orig_key[2:])

    iv = b""
    iv_vector = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
    for i in iv_vector:
        iv += bytes([i])

    ctr = Counter.new(128, initial_value=int(iv.hex(), 16))
    cipher = AES.new(key, AES.MODE_CTR, counter=ctr)
    decrypted = cipher.decrypt(encrypted_data)

    return decrypted



def predownload_interactiveData(payload):
    # Load configurations
    CONFIG = load_config()

    jdataref = payload["interactiveDataRef"]

    decryption_key = jdataref.get("key").upper()
    mmcs_url = jdataref.get("url")
    mmcs_owner = jdataref.get("owner")
    file_size = jdataref.get("size")
    bid = jdataref.get("bid")

    # get hex encoded signature and convert to base64
    hex_encoded_signature = jdataref.get("signature").upper()
    signature = base64.b16decode(hex_encoded_signature)
    base64_encoded_signature = base64.b64encode(signature)

    predownload_headers = {
            "Authorization": "Bearer %s" % get_jwt_token(),
            "source-id": bid,
            "MMCS-Url": mmcs_url,
            "MMCS-Signature": base64_encoded_signature,
            "MMCS-Owner": mmcs_owner
        }

    r = requests.get("%s/preDownload" % CONFIG["amb_server"],
                         headers=predownload_headers,
                         timeout=10)


    download_url = json.loads(r.content).get("download-url")


    # download the attachment data with GET request
    encrypted_interactive_data = requests.get(download_url).content

    # compare download size with expected file size
    if len(encrypted_interactive_data) != file_size:
        raise Exception("Data downloaded not of expected size! Check preDownload step.")

    # decrypted the downloaded data
    decrypted_interactive_data = decrypt(encrypted_interactive_data, decryption_key)

    decode_headers = {
            "Authorization": "Bearer %s" % get_jwt_token(),
            "source-id": bid,
            "accept": "*/*",
            "accept-encoding": "gzip, deflate",
            "bid": bid
        }
    
    r = requests.post("%s/decodePayload" % CONFIG["amb_server"],
                          headers=decode_headers,
                          data=decrypted_interactive_data,
                          timeout=10)

    # Write out the Messages for Business server response
    print("%d: %s" % (r.status_code, r.text))


def download_message(payload):
    # Load configurations
    CONFIG = load_config()

    message_interactive = payload.get("interactiveDataRef")
    BIZ_ID = payload.get("destinationId")
    if message_interactive:
        bid = message_interactive.get("bid")

        #requestGet variables
        hex_encoded_signature = message_interactive.get("signature").upper()
        mmcs_url = message_interactive.get("url")
        mmcs_owner = message_interactive.get("owner")
        file_size = message_interactive.get("size")
        decryption_key = message_interactive.get("key").upper()

        # send request.get with hex_encoded_signature to retrieve encrypted data
        decrypted_attachment_data = decryptRequest(hex_encoded_signature, mmcs_url, mmcs_owner, file_size, decryption_key, BIZ_ID)

        decode_headers = {
            "Authorization": "Bearer %s" % get_jwt_token(),
            "source-id": BIZ_ID,
            "accept": "*/*",
            "accept-encoding": "gzip, deflate",
            "bid": bid
        }
        r = requests.post("%s/decodePayload" % CONFIG["amb_server"],
                          headers=decode_headers,
                          data=decrypted_attachment_data,
                          timeout=10)

        newj = json.loads(r.text)

        try:
            del newj["images"]  # <-- Remove the image bitmaps to make the payload managable
        except KeyError as ekey:
            print("Error")
            pass

        return newj


def decryptRequest(hex_encoded_signature, mmcs_url, mmcs_owner, file_size, decryption_key, business_id):
    # Load configurations
    CONFIG = load_config()

    signature = base64.b16decode(hex_encoded_signature)
    base64_encoded_signature = base64.b64encode(signature)

    predownload_headers = {
        "authorization": "Bearer %s" % get_jwt_token(),
        "source-id": business_id,
        "mmcs-url": mmcs_url,
        "mmcs-signature": base64_encoded_signature,
        "mmcs-owner": mmcs_owner
    }

    r = requests.get("%s/preDownload" % CONFIG["amb_server"], headers=predownload_headers,
                         timeout=10)

    download_url = json.loads(r.content).get("download-url")

    # download the attachment data with GET request
    encrypted_attachment_data = requests.get(download_url).content

    # compare download size with expected file size
    #if len(encrypted_attachment_data) != file_size:
    #    raise Exception("Data downloaded not of expected size! Check preDownload step.")

    # decrypted the downloaded data
    decrypted_attachment_data = decrypt(encrypted_attachment_data, decryption_key)
    return decrypted_attachment_data
