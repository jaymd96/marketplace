# PyJWT v2.9+

Encode and decode JSON Web Tokens (JWT) per RFC 7519.

## Quick Start

```python
import jwt

# Encode
token = jwt.encode({"user_id": 123, "role": "admin"}, "secret", algorithm="HS256")

# Decode
payload = jwt.decode(token, "secret", algorithms=["HS256"])
print(payload)  # {"user_id": 123, "role": "admin"}
```

## Core API

### `jwt.encode(payload, key, algorithm="HS256", headers=None, json_encoder=None)`

Encode a payload dict into a JWT string.

```python
import jwt
import datetime as dt

# Basic HMAC
token = jwt.encode({"sub": "user123"}, "my-secret", algorithm="HS256")

# With standard claims
token = jwt.encode(
    {
        "sub": "user123",
        "iss": "myapp",
        "aud": "myapi",
        "exp": dt.datetime.now(dt.timezone.utc) + dt.timedelta(hours=1),
        "iat": dt.datetime.now(dt.timezone.utc),
        "nbf": dt.datetime.now(dt.timezone.utc),
        "jti": "unique-token-id",
    },
    "secret",
    algorithm="HS256",
)

# With custom headers
token = jwt.encode({"sub": "user123"}, "secret", algorithm="HS256", headers={"kid": "key-1"})
```

### `jwt.decode(jwt_str, key, algorithms, options=None, audience=None, issuer=None, leeway=0, required=None)`

Decode and validate a JWT string. Returns the payload dict.

```python
import jwt

payload = jwt.decode(token, "secret", algorithms=["HS256"])

# With audience and issuer validation
payload = jwt.decode(
    token,
    "secret",
    algorithms=["HS256"],
    audience="myapi",
    issuer="myapp",
)

# Require specific claims
payload = jwt.decode(
    token,
    "secret",
    algorithms=["HS256"],
    required=["exp", "iss", "sub"],
)

# Allow clock skew
payload = jwt.decode(
    token,
    "secret",
    algorithms=["HS256"],
    leeway=dt.timedelta(seconds=30),
)

# Disable specific validations
payload = jwt.decode(
    token,
    "secret",
    algorithms=["HS256"],
    options={
        "verify_exp": False,       # Skip expiration check
        "verify_aud": False,       # Skip audience check
        "verify_iss": False,       # Skip issuer check
        "verify_signature": True,  # Always keep True in production
    },
)

# Decode without verification (e.g., inspect header)
payload = jwt.decode(token, options={"verify_signature": False}, algorithms=["HS256"])
header = jwt.get_unverified_header(token)
```

### Algorithms

```python
# Symmetric (shared secret)
# HS256, HS384, HS512
token = jwt.encode(payload, "shared-secret", algorithm="HS256")

# Asymmetric RSA (requires `pip install pyjwt[crypto]`)
# RS256, RS384, RS512, PS256, PS384, PS512
with open("private.pem") as f:
    private_key = f.read()
with open("public.pem") as f:
    public_key = f.read()

token = jwt.encode(payload, private_key, algorithm="RS256")
decoded = jwt.decode(token, public_key, algorithms=["RS256"])

# Asymmetric EC
# ES256, ES256K, ES384, ES512
token = jwt.encode(payload, ec_private_key, algorithm="ES256")
decoded = jwt.decode(token, ec_public_key, algorithms=["ES256"])

# EdDSA (Ed25519)
token = jwt.encode(payload, ed_private_key, algorithm="EdDSA")
decoded = jwt.decode(token, ed_public_key, algorithms=["EdDSA"])
```

### Error Types

```python
import jwt

try:
    payload = jwt.decode(token, "secret", algorithms=["HS256"])
except jwt.ExpiredSignatureError:
    # Token's exp claim is in the past
    pass
except jwt.InvalidAudienceError:
    # Token's aud claim doesn't match expected audience
    pass
except jwt.InvalidIssuerError:
    # Token's iss claim doesn't match expected issuer
    pass
except jwt.ImmatureSignatureError:
    # Token's nbf claim is in the future
    pass
except jwt.MissingRequiredClaimError:
    # A claim specified in `required` is missing
    pass
except jwt.DecodeError:
    # Token is malformed (bad base64, invalid JSON, etc.)
    pass
except jwt.InvalidSignatureError:
    # Signature verification failed
    pass
except jwt.InvalidTokenError:
    # Base class -- catches ALL of the above
    pass
```

## Examples

### Access Token + Refresh Token Pattern

```python
import jwt
import datetime as dt

SECRET = "app-secret"
REFRESH_SECRET = "refresh-secret"

def create_tokens(user_id: str) -> tuple[str, str]:
    now = dt.datetime.now(dt.timezone.utc)
    access = jwt.encode(
        {"sub": user_id, "exp": now + dt.timedelta(minutes=15), "type": "access"},
        SECRET, algorithm="HS256",
    )
    refresh = jwt.encode(
        {"sub": user_id, "exp": now + dt.timedelta(days=7), "type": "refresh"},
        REFRESH_SECRET, algorithm="HS256",
    )
    return access, refresh

def verify_access(token: str) -> dict:
    return jwt.decode(token, SECRET, algorithms=["HS256"], required=["sub", "exp"])
```

### RS256 with Key Pair

```python
from cryptography.hazmat.primitives.asymmetric import rsa
from cryptography.hazmat.primitives import serialization
import jwt

# Generate keys (once, store securely)
private_key = rsa.generate_private_key(public_exponent=65537, key_size=2048)
public_key = private_key.public_key()

private_pem = private_key.private_bytes(
    serialization.Encoding.PEM,
    serialization.PrivateFormat.PKCS8,
    serialization.NoEncryption(),
)
public_pem = public_key.public_bytes(
    serialization.Encoding.PEM,
    serialization.PublicFormat.SubjectPublicKeyInfo,
)

# Encode with private key
token = jwt.encode({"sub": "user123"}, private_pem, algorithm="RS256")

# Decode with public key
payload = jwt.decode(token, public_pem, algorithms=["RS256"])
```

## Pitfalls

- **Always pass `algorithms` as a list.** Never derive algorithms from the token header itself -- this enables algorithm confusion attacks (CVE-2022-29217).
- **`exp`, `nbf`, `iat` expect `datetime` objects or UTC timestamps (int/float).** Using naive datetimes may cause timezone-related expiry bugs. Always use `datetime.now(timezone.utc)`.
- **`verify_signature=False` is dangerous.** Only use it for debugging or introspection, never for authorization decisions.
- **`HS256` uses a shared secret.** Anyone with the secret can forge tokens. For multi-service architectures, use `RS256` or `ES256` (asymmetric) so only the issuer has the private key.
- **`pip install pyjwt[crypto]` is required for RSA/EC/EdDSA.** Without the `[crypto]` extra (which installs `cryptography`), asymmetric algorithms raise `NotImplementedError`.
- **Do not confuse `PyJWT` with `jwt` on PyPI.** They are different packages with conflicting import names. Ensure `PyJWT` is installed, not `jwt`.
- **Default decode options verify `exp` and `nbf` but do NOT require them.** A token without `exp` is accepted by default. Use `required=["exp"]` to enforce mandatory expiration.
