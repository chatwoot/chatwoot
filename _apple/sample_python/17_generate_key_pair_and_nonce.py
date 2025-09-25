# Copyright 2025 Apple, Inc.
# All Rights Reserved.

import base64
import os
import uuid

from cryptography.hazmat.backends import default_backend
from cryptography.hazmat.primitives.asymmetric import ec
from cryptography import utils


class BCAuthCrypto:
    """A class containing handlers for ECC algorithm in Python"""

    curve = ec.SECP384R1()
    cipher_key_size = 32
    mac_size = 16
    backend = default_backend()

    def generate(self):
        """Generate a public/private key pair and return the byte array versions of each in
        a tuple."""

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


def generate_pair():
    """Generates a public/private key pair using the crypto library, the returns them as
    base64 strings."""
    bc_crypto = BCAuthCrypto()
    (pubbin, pribin) = bc_crypto.generate()

    privkey_b64 = base64.b64encode(pribin)
    pubkey_b64 = base64.b64encode(pubbin)

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


def main():
    """Generate the parameters needed for the authentication request JSON payload."""
    request_id = str(uuid.uuid4())

    # Generate a private and public key, keep the public key to use in the payload
    (response_encryption_key, privkey_b64) = generate_pair()

    # Also generate a nonce for this request
    state = generate_nonce()

    print("Ready to generate authentication request with parameters")
    print("request_id: %s" % request_id)
    print("responseEncryptionKey: %s" % response_encryption_key)
    print("nonce (aka state): %s" % state)
    print("private key, base64: %s" % privkey_b64)


if __name__ == "__main__":
    main()
