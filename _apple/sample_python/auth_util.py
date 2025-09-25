# Copyright 2025 Apple, Inc.
# All Rights Reserved.

import base64
import binascii
import json
import os

from cryptography.hazmat.backends import default_backend
from cryptography.hazmat.primitives.asymmetric import ec
from cryptography.hazmat.primitives.ciphers import algorithms, Cipher, modes
from cryptography import utils
from hashlib import sha256
from math import ceil


class BCAuthCrypto:
    """A class containing a number of handlers for the secp384r1 ECC algorithm in Python"""

    curve = ec.SECP384R1()
    cipher_key_size = 32
    mac_size = 16
    backend = default_backend()

    def ITOSP(self, longint, length):
        """ITOSP, short for Integer-to-Octet-String Primitive, converts a non-negative integer
        to an octet string of a specified length. This particular function is defined in the
        PKCS #1 v2.1: RSA Cryptography Standard (June 14, 2002)
        https://www.cryptrec.go.jp/cryptrec_03_spec_cypherlist_files/PDF/pkcs-1v2-12.pdf"""

        hex_string = "%X" % longint
        assert len(hex_string) <= 2 * length, "ITOSP function: Insufficient length for encoding"
        return binascii.a2b_hex(hex_string.zfill(2 * length))

    def KDFX963(self, inbyte_x, shared_data, key_length, hashfunct=sha256, hash_len=32):
        """KDFX963 is a key derivation function (KDF) that takes as input byte sequence inbyte_x
        and additional shared data shared_data and outputs a byte sequence key of length
        key_length. This function is defined in ANSI-X9.63-KDF, and this particular flavor of
        KDF is known as X9.63. You can read more about it from:
        http://www.secg.org/sec1-v2.pdf"""

        assert key_length >= 0, "KDFX963 function: key_length should be positive integer"
        k = key_length / float(hash_len)
        k = int(ceil(k))

        acc_str = ""
        for i in range(1, k+1):
            h = hashfunct()
            h.update(inbyte_x)
            h.update(self.ITOSP(i, 4))
            h.update(shared_data)
            acc_str = acc_str + h.hexdigest()

        return acc_str[:key_length * 2]

    def decrypt(self, cipher_text_b64, private_key):
        """Decrypt takes input base64-encoded data input cipher_text_b64 and private key
        private_key and outputs plain text data, throws exception on error"""
        cipher = base64.b64decode(cipher_text_b64)

        ephemeral_key_len = ((self.curve.key_size + 7) // 8) * 2 + 1
        ephemeral_key_numbers = ec.EllipticCurvePublicNumbers.from_encoded_point(self.curve, cipher[:ephemeral_key_len])
        ephemeral_key = ephemeral_key_numbers.public_key(self.backend)

        shared_key = private_key.exchange(ec.ECDH(), ephemeral_key)

        V = cipher[:ephemeral_key_len]
        K = binascii.unhexlify(self.KDFX963(shared_key, V, self.cipher_key_size + self.mac_size))
        K1 = K[:self.cipher_key_size]
        K2 = K[self.cipher_key_size:]

        T = cipher[ephemeral_key_len:]
        enc_data = T[:len(T) - self.mac_size]
        tag = T[-self.mac_size:]

        decryptor = Cipher(algorithms.AES(K1), modes.GCM(K2, tag), backend=self.backend).decryptor()
        plain_text = decryptor.update(enc_data) + decryptor.finalize()
        return plain_text

    def generate(self):
        """Generate a public/private key pair and return the byte array verions of each in a tuple."""

        privbase = ec.generate_private_key(self.curve, self.backend)
        pub = privbase.public_key()

        # Derive the private key as byte array
        prinum = privbase.private_numbers()
        prival = prinum.private_value
        pribin = utils.int_to_bytes(prival)

        # Derive the public key as byte array
        pubnum = pub.public_numbers()
        pubpoint = pubnum.encode_point()

        return (pubpoint, pribin)

    def public_key_from_private(self, pribin):
        """Generate the public key from a private key."""

        pub = pribin.public_key()
        pubnum = pub.private_numbers()
        pubpoint = pubnum.encode_point()

        return pubpoint

    def private_key_from_strings(self, public_key_b64, private_key_b64):
        """Generates the private key object from the base64 encoded public and private key strings."""

        public_number = ec.EllipticCurvePublicNumbers.from_encoded_point(self.curve, base64.b64decode(public_key_b64))
        private_number = ec.EllipticCurvePrivateNumbers(utils.int_from_bytes(base64.b64decode(private_key_b64), "big"), public_number)

        private_key = private_number.private_key(self.backend)
        return private_key


def generate_pair():
    """Generates a public/private key pair using the crypto library, the returns them as
    base64 strings."""
    bc_crypto = BCAuthCrypto()
    (pubbin, pribin) = bc_crypto.generate()

    privkey_b64_bytes = base64.b64encode(pribin)
    privkey_b64 = privkey_b64_bytes.decode("utf-8")
    pubkey_b64_bytes = base64.b64encode(pubbin)
    pubkey_b64 = pubkey_b64_bytes.decode("utf-8")

    return (pubkey_b64, privkey_b64)


def generate_binary_key(b64size):
    """Generates a random binary key given the length of the base64 encoded string that
    will be produced."""
    binarysize = b64size * 6 // 8
    binaryrand = os.urandom(binarysize)
    return binaryrand


def generate_nonce():
    """Generates a nonce for the authentication process."""
    nonce_str_bytes = base64.b64encode(generate_binary_key(32))
    nonce_str = nonce_str_bytes.decode("utf-8")
    return nonce_str


def decrypt_auth_token(tokenFromPayload, public_key_str, private_key_str):
    """Retrive the auth token and decrypt it, in a way that does not specify the name of the service."""
    bc_crypto = BCAuthCrypto()

    public_number = ec.EllipticCurvePublicNumbers.from_encoded_point(bc_crypto.curve, base64.b64decode(public_key_str))
    private_number = ec.EllipticCurvePrivateNumbers(utils.int_from_bytes(base64.b64decode(private_key_str), "big"), public_number)

    private_key = private_number.private_key(bc_crypto.backend)
    token_bytes = bc_crypto.decrypt(tokenFromPayload, private_key)
    token = token_bytes.decode("utf-8")

    print("token (decrypted): %s" % token)

    return token
