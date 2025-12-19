import os
import base64
import secrets
from typing import Tuple
from cryptography.hazmat.primitives.ciphers.aead import AESGCM

_KEY_ENV = "VOTE_ENCRYPTION_KEY"


def get_key() -> bytes:
    key_b64 = os.getenv(_KEY_ENV, "")
    if not key_b64:
        raise RuntimeError("VOTE_ENCRYPTION_KEY is not set")
    try:
        key = base64.b64decode(key_b64)
    except Exception as exc:
        raise RuntimeError("Invalid base64 for VOTE_ENCRYPTION_KEY") from exc
    if len(key) != 32:
        raise RuntimeError("VOTE_ENCRYPTION_KEY must be 32 bytes (base64 of 256-bit key)")
    return key


def encrypt_text(plaintext: str) -> str:
    key = get_key()
    aesgcm = AESGCM(key)
    nonce = secrets.token_bytes(12)
    ct = aesgcm.encrypt(nonce, plaintext.encode("utf-8"), associated_data=None)
    return base64.b64encode(nonce + ct).decode("ascii")


def decrypt_text(ciphertext_b64: str) -> str:
    key = get_key()
    data = base64.b64decode(ciphertext_b64)
    nonce, ct = data[:12], data[12:]
    aesgcm = AESGCM(key)
    pt = aesgcm.decrypt(nonce, ct, associated_data=None)
    return pt.decode("utf-8")
