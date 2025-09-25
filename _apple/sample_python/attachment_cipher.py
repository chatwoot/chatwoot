# Copyright 2025 Apple, Inc.
# All Rights Reserved.

import os
import base64
from Crypto.Cipher import AES
from Crypto.Util import Counter


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
