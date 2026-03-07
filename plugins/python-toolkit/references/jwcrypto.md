# jwcrypto v1.5.6

JWT/JWE/JWS cryptography library implementing JOSE Web Standards (RFC 7515-7519).

```
pip install jwcrypto>=1.5
```

## Quick Start

```python
from jwcrypto import jwk, jws, jwe, jwt
import json

key = jwk.JWK.generate(kty="RSA", size=2048)
token = jwt.JWT(header={"alg": "RS256", "kid": key.key_id},
                claims={"sub": "user123", "iss": "myapp"})
token.make_signed_token(key)
signed = token.serialize()
```

## Core API

### JWK -- Key Management

```python
# Generate keys
jwk.JWK.generate(kty="RSA", size=2048)          # RSA key pair
jwk.JWK.generate(kty="EC", crv="P-256")         # EC key pair (P-256, P-384, P-521)
jwk.JWK.generate(kty="OKP", crv="Ed25519")      # EdDSA key pair
jwk.JWK.generate(kty="oct", size=256)            # Symmetric key (HMAC/AES)

# Import keys
jwk.JWK(**json.loads(jwk_json))                  # From JWK JSON dict
jwk.JWK.from_json(jwk_json_string)               # From JWK JSON string
jwk.JWK.from_pem(pem_data)                       # From PEM bytes
jwk.JWK.from_password(password)                  # Derive from password

# Export keys
key.export()                                      # Full JWK JSON (private)
key.export_public()                               # Public-only JWK JSON
key.export_to_pem(private_key=True, password=None)  # PEM bytes
key.export_to_pem(private_key=False)              # Public PEM
key.thumbprint()                                  # RFC 7638 thumbprint

# Key properties
key.key_id                                        # kid header value
key.key_type                                      # "RSA", "EC", "oct", "OKP"
key.has_private                                   # bool
key.has_public                                    # bool

# Key sets
keyset = jwk.JWKSet()
keyset.add(key)
keyset.export()                                   # {"keys": [...]}
jwk.JWKSet.from_json(keyset_json)                 # Import key set
keyset.get_key(kid)                               # Lookup by kid
```

### JWS -- Signing and Verification

```python
from jwcrypto.common import json_encode

# Sign
payload = b"message to sign"
jwsobj = jws.JWS(payload)
jwsobj.add_signature(
    key,                                          # JWK signing key
    alg=None,                                     # Override algorithm (optional)
    protected=json_encode({"alg": "RS256"}),      # Protected header (JSON string)
    header=json_encode({"kid": key.key_id}),      # Unprotected header (optional)
)
signed = jwsobj.serialize()                       # Default: JSON serialization
signed_compact = jwsobj.serialize(compact=True)   # Compact serialization (single sig)

# Verify
jwsobj = jws.JWS()
jwsobj.deserialize(signed)                        # or signed_compact
jwsobj.verify(key)                                # Raises InvalidJWSSignature on failure
payload = jwsobj.payload                          # bytes
jwsobj.jose_header                                # Merged JOSE header dict
```

### JWE -- Encryption and Decryption

```python
# Encrypt
plaintext = b"secret data"
jweobj = jwe.JWE(plaintext, protected=json_encode({"alg": "RSA-OAEP", "enc": "A256GCM"}))
jweobj.add_recipient(key)                         # Public key of recipient
encrypted = jweobj.serialize(compact=True)        # Compact serialization

# Decrypt
jweobj = jwe.JWE()
jweobj.deserialize(encrypted)
jweobj.decrypt(key)                               # Private key; raises InvalidJWEData
plaintext = jweobj.payload                        # bytes
```

### JWT -- JSON Web Tokens

```python
# Signed JWT
token = jwt.JWT(
    header={"alg": "RS256", "kid": key.key_id},
    claims={"sub": "user123", "iss": "myapp", "exp": 1700000000},
)
token.make_signed_token(key)
serialized = token.serialize()                    # Compact JWS string

# Encrypted JWT
token = jwt.JWT(
    header={"alg": "RSA-OAEP", "enc": "A256GCM"},
    claims={"sub": "user123"},
)
token.make_encrypted_token(key)
serialized = token.serialize()

# Nested JWT: sign first, then encrypt with cty="JWT" in outer header

# Validate and parse
received = jwt.JWT(
    key=verification_key,                         # Key or JWKSet for validation
    jwt=serialized,                               # Serialized token string
    check_claims={                                # Claims validation
        "iss": "myapp",                           # Exact match
        "exp": None,                              # Check expiration (current time)
        "nbf": None,                              # Check not-before
    },
    expected_type="JWS",                          # "JWS" or "JWE"
)
claims = json.loads(received.claims)              # Parsed claims dict
header = received.header                          # Header dict
```

## Examples

### 1. ES256 Sign and Verify

```python
from jwcrypto import jwk, jwt
import json, time

key = jwk.JWK.generate(kty="EC", crv="P-256")
pub = jwk.JWK.from_json(key.export_public())

claims = {
    "sub": "user@example.com",
    "iat": int(time.time()),
    "exp": int(time.time()) + 3600,
}
token = jwt.JWT(header={"alg": "ES256", "kid": key.key_id}, claims=claims)
token.make_signed_token(key)
wire = token.serialize()

# Recipient verifies with public key
verified = jwt.JWT(key=pub, jwt=wire, check_claims={"exp": None})
print(json.loads(verified.claims))
```

### 2. A256GCM Symmetric Encryption

```python
from jwcrypto import jwk, jwe
from jwcrypto.common import json_encode

sym_key = jwk.JWK.generate(kty="oct", size=256)
payload = b'{"account": "12345", "balance": 1000}'

jweobj = jwe.JWE(payload, protected=json_encode({"alg": "dir", "enc": "A256GCM"}))
jweobj.add_recipient(sym_key)
token = jweobj.serialize(compact=True)

jweobj2 = jwe.JWE()
jweobj2.deserialize(token)
jweobj2.decrypt(sym_key)
assert jweobj2.payload == payload
```

## Supported Algorithms

**Sign:** HS256/384/512, RS256/384/512, ES256/384/512, PS256/384/512, EdDSA
**KEK:** RSA-OAEP, RSA-OAEP-256, A128/192/256KW, dir, ECDH-ES (+A128/192/256KW)
**Enc:** A128/192/256CBC-HS256/384/512, A128/192/256GCM

## Pitfalls

- **Export leaks private keys.** `key.export()` includes the private key by default.
  Use `key.export_public()` or `export(private_keys=False)` for public distribution.
- **Compact serialization requires exactly one signature/recipient.** Multi-recipient
  JWE or multi-signature JWS must use JSON serialization.
- **Claims are strings.** `jwt.claims` returns a JSON string, not a dict. Always
  `json.loads(token.claims)` to get the dict.
- **No automatic exp/nbf checking unless you opt in.** Pass `check_claims={"exp": None}`
  to enable expiration validation. Without it, expired tokens parse without error.
- **JWKSet.get_key() returns None silently** if the kid is not found. Always check
  the return value before using it.
- **Thread safety.** JWS/JWE objects are not thread-safe. Create new instances per operation.
