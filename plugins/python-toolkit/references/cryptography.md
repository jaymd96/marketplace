# cryptography v44.0+

Cryptographic primitives and recipes for Python. Two layers: high-level recipes (Fernet) and low-level hazmat primitives (RSA, hashing, X.509).

```
pip install cryptography
```

## Quick Start

```python
from cryptography.fernet import Fernet

key = Fernet.generate_key()          # store this securely
f = Fernet(key)
token = f.encrypt(b"secret data")    # -> bytes (URL-safe base64)
plaintext = f.decrypt(token)         # -> b"secret data"
```

## Core API

### Fernet (Symmetric Encryption)

AES-128-CBC + HMAC-SHA256. Authenticated encryption -- tamper-proof.

```python
from cryptography.fernet import Fernet, MultiFernet, InvalidToken

# Generate key (32 bytes, URL-safe base64 encoded)
key = Fernet.generate_key()     # -> bytes like b'ZmDf...'

# Encrypt / decrypt
f = Fernet(key)
token = f.encrypt(b"plaintext")
plaintext = f.decrypt(token)                      # -> bytes
plaintext = f.decrypt(token, ttl=300)             # fail if token older than 300s

# Extract timestamp
f.extract_timestamp(token)                        # -> int (Unix timestamp)

# Key rotation with MultiFernet
old_key = Fernet.generate_key()
new_key = Fernet.generate_key()
mf = MultiFernet([Fernet(new_key), Fernet(old_key)])
mf.decrypt(old_token)                             # tries new_key first, falls back
rotated = mf.rotate(old_token)                    # re-encrypt with new_key

# Error handling
try:
    f.decrypt(token, ttl=60)
except InvalidToken:
    print("Invalid, expired, or tampered token")
```

### RSA (Asymmetric Encryption)

```python
from cryptography.hazmat.primitives.asymmetric import rsa, padding
from cryptography.hazmat.primitives import hashes, serialization

# Generate key pair
private_key = rsa.generate_private_key(
    public_exponent=65537,
    key_size=2048,
)
public_key = private_key.public_key()

# Encrypt with public key
ciphertext = public_key.encrypt(
    b"secret message",
    padding.OAEP(
        mgf=padding.MGF1(algorithm=hashes.SHA256()),
        algorithm=hashes.SHA256(),
        label=None,
    ),
)

# Decrypt with private key
plaintext = private_key.decrypt(
    ciphertext,
    padding.OAEP(
        mgf=padding.MGF1(algorithm=hashes.SHA256()),
        algorithm=hashes.SHA256(),
        label=None,
    ),
)

# Sign
signature = private_key.sign(
    b"data to sign",
    padding.PSS(
        mgf=padding.MGF1(hashes.SHA256()),
        salt_length=padding.PSS.MAX_LENGTH,
    ),
    hashes.SHA256(),
)

# Verify
public_key.verify(
    signature,
    b"data to sign",
    padding.PSS(
        mgf=padding.MGF1(hashes.SHA256()),
        salt_length=padding.PSS.MAX_LENGTH,
    ),
    hashes.SHA256(),
)  # raises InvalidSignature on failure

# Serialize keys
pem_private = private_key.private_bytes(
    encoding=serialization.Encoding.PEM,
    format=serialization.PrivateFormat.PKCS8,
    encryption_algorithm=serialization.BestAvailableEncryption(b"passphrase"),
)
pem_public = public_key.public_bytes(
    encoding=serialization.Encoding.PEM,
    format=serialization.PublicFormat.SubjectPublicKeyInfo,
)

# Load keys
from cryptography.hazmat.primitives.serialization import load_pem_private_key, load_pem_public_key
private_key = load_pem_private_key(pem_private, password=b"passphrase")
public_key = load_pem_public_key(pem_public)
```

### Hashing

```python
from cryptography.hazmat.primitives import hashes

# One-shot hash
digest = hashes.Hash(hashes.SHA256())
digest.update(b"data part 1")
digest.update(b"data part 2")
result = digest.finalize()       # -> bytes (32 bytes for SHA256)

# HMAC
from cryptography.hazmat.primitives.hmac import HMAC
h = HMAC(key=b"secret", algorithm=hashes.SHA256())
h.update(b"message")
signature = h.finalize()

# Verify HMAC
h = HMAC(key=b"secret", algorithm=hashes.SHA256())
h.update(b"message")
h.verify(signature)              # raises InvalidSignature on mismatch

# Available algorithms
# hashes.SHA256(), SHA384(), SHA512(), SHA3_256(), SHA3_512(),
# BLAKE2b(64), BLAKE2s(32), MD5() (insecure), SHA1() (insecure)
```

### Key Derivation

```python
# PBKDF2 (password hashing)
from cryptography.hazmat.primitives.kdf.pbkdf2 import PBKDF2HMAC
import os

salt = os.urandom(16)
kdf = PBKDF2HMAC(
    algorithm=hashes.SHA256(),
    length=32,
    salt=salt,
    iterations=600_000,            # OWASP 2023 recommendation
)
key = kdf.derive(b"my password")   # -> 32 bytes

# Verify (separate instance required)
kdf2 = PBKDF2HMAC(algorithm=hashes.SHA256(), length=32, salt=salt, iterations=600_000)
kdf2.verify(b"my password", key)   # raises InvalidKey on mismatch

# Scrypt
from cryptography.hazmat.primitives.kdf.scrypt import Scrypt
kdf = Scrypt(salt=salt, length=32, n=2**14, r=8, p=1)
key = kdf.derive(b"password")

# HKDF (key expansion)
from cryptography.hazmat.primitives.kdf.hkdf import HKDF
hkdf = HKDF(algorithm=hashes.SHA256(), length=32, salt=salt, info=b"context")
derived = hkdf.derive(b"input key material")
```

### X.509 Certificates

```python
from cryptography import x509
from cryptography.x509.oid import NameOID
from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives.asymmetric import rsa
import datetime

# Generate self-signed certificate
private_key = rsa.generate_private_key(public_exponent=65537, key_size=2048)
subject = issuer = x509.Name([
    x509.NameAttribute(NameOID.COMMON_NAME, "example.com"),
    x509.NameAttribute(NameOID.ORGANIZATION_NAME, "My Org"),
])
cert = (
    x509.CertificateBuilder()
    .subject_name(subject)
    .issuer_name(issuer)
    .public_key(private_key.public_key())
    .serial_number(x509.random_serial_number())
    .not_valid_before(datetime.datetime.now(datetime.timezone.utc))
    .not_valid_after(datetime.datetime.now(datetime.timezone.utc) + datetime.timedelta(days=365))
    .add_extension(
        x509.SubjectAlternativeName([x509.DNSName("example.com")]),
        critical=False,
    )
    .sign(private_key, hashes.SHA256())
)

# Serialize
cert_pem = cert.public_bytes(serialization.Encoding.PEM)

# Load and inspect
cert = x509.load_pem_x509_certificate(cert_pem)
cert.subject                          # -> Name
cert.issuer
cert.not_valid_before_utc             # -> datetime (v44+, timezone-aware)
cert.not_valid_after_utc
cert.serial_number
cert.public_key()
```

## Examples

### Encrypt file with Fernet

```python
from cryptography.fernet import Fernet

def encrypt_file(key: bytes, src: str, dst: str):
    f = Fernet(key)
    with open(src, "rb") as fin:
        with open(dst, "wb") as fout:
            fout.write(f.encrypt(fin.read()))
```

### Password verification with PBKDF2

```python
import os
from cryptography.hazmat.primitives.kdf.pbkdf2 import PBKDF2HMAC
from cryptography.hazmat.primitives import hashes

def hash_password(password: str) -> tuple[bytes, bytes]:
    salt = os.urandom(16)
    kdf = PBKDF2HMAC(algorithm=hashes.SHA256(), length=32, salt=salt, iterations=600_000)
    return salt, kdf.derive(password.encode())

def verify_password(password: str, salt: bytes, hash_: bytes) -> bool:
    kdf = PBKDF2HMAC(algorithm=hashes.SHA256(), length=32, salt=salt, iterations=600_000)
    try:
        kdf.verify(password.encode(), hash_)
        return True
    except Exception:
        return False
```

## Pitfalls

1. **KDF instances are single-use**: After `derive()` or `verify()`, the KDF object cannot be reused. Create a new instance for each operation.
2. **Fernet key must be 32 bytes base64**: Passing a random string as a Fernet key raises `ValueError`. Always use `Fernet.generate_key()` or derive with HKDF/PBKDF2 and base64-encode.
3. **RSA max plaintext size**: RSA-OAEP with 2048-bit key can encrypt at most ~190 bytes. For larger data, encrypt a symmetric key with RSA, then encrypt data with that key (hybrid encryption).
4. **hazmat means hazardous**: The `hazmat` primitives require correct usage. Wrong padding, nonce reuse, or weak parameters create silent vulnerabilities.
5. **Hash.finalize() is terminal**: After `finalize()`, the Hash object cannot be updated. Use `.copy()` before finalizing if you need to continue hashing.
6. **not_valid_before vs not_valid_before_utc**: In v44+, prefer `cert.not_valid_before_utc` (timezone-aware). The non-`_utc` variant returns a naive datetime.
7. **Iteration count for PBKDF2**: Use at least 600,000 iterations for SHA256 (OWASP 2023). Lower values are vulnerable to brute force.
