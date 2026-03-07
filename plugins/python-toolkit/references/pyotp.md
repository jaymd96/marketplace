# pyotp v2.9.0

Python library for generating and verifying TOTP/HOTP one-time passwords (RFC 4226, RFC 6238).

```
pip install pyotp>=2.9
```

## Quick Start

```python
import pyotp

secret = pyotp.random_base32()              # Generate shared secret
totp = pyotp.TOTP(secret)
code = totp.now()                           # e.g. "492039"
assert totp.verify(code)                    # True within time window
uri = totp.provisioning_uri(name="user@example.com", issuer_name="MyApp")
```

## Core API

### Secret Generation

```python
pyotp.random_base32(length: int = 32) -> str
# Returns a random Base32-encoded secret (default 32 chars = 160 bits).
# Use as the shared secret for TOTP/HOTP.

pyotp.random_hex(length: int = 40) -> str
# Returns a random hex-encoded secret (default 40 chars = 160 bits).

# You can also use any Base32-encoded string as a secret:
secret = pyotp.random_base32()  # "JBSWY3DPEHPK3PXP..."
```

### TOTP -- Time-Based One-Time Passwords

```python
pyotp.TOTP(
    s: str,                          # Base32-encoded secret
    digits: int = 6,                 # OTP length (6 or 8)
    digest: Any = hashlib.sha1,      # Hash algorithm (sha1, sha256, sha512)
    name: str = None,                # Account name for provisioning URI
    issuer: str = None,              # Issuer name for provisioning URI
    interval: int = 30,              # Time step in seconds
)

# Generate current OTP
totp.now() -> str                    # Current time-based code

# Generate OTP for specific time
totp.at(for_time: datetime | int) -> str
# for_time: datetime object or Unix timestamp

# Verify OTP
totp.verify(
    otp: str,                        # Code to verify
    for_time: datetime | int = None, # Time to verify against (default: now)
    valid_window: int = 0,           # Number of periods before/after to accept
) -> bool
# valid_window=1 accepts codes from [t-30s, t, t+30s]

# Provisioning URI (for QR code generation)
totp.provisioning_uri(
    name: str = None,                # Account name (user@example.com)
    issuer_name: str = None,         # Service name
    image: str = None,               # Logo URL
) -> str
# Returns: otpauth://totp/MyApp:user@example.com?secret=...&issuer=MyApp
```

### HOTP -- Counter-Based One-Time Passwords

```python
pyotp.HOTP(
    s: str,                          # Base32-encoded secret
    digits: int = 6,                 # OTP length
    digest: Any = hashlib.sha1,      # Hash algorithm
    name: str = None,
    issuer: str = None,
    initial_count: int = 0,          # Starting counter value
)

# Generate OTP at counter value
hotp.at(count: int) -> str          # Code for given counter

# Verify OTP
hotp.verify(
    otp: str,                        # Code to verify
    counter: int,                    # Expected counter value
) -> bool

# Provisioning URI
hotp.provisioning_uri(
    name: str = None,
    issuer_name: str = None,
    initial_count: int = 0,
    image: str = None,
) -> str
# Returns: otpauth://hotp/MyApp:user@example.com?secret=...&counter=0
```

### parse_uri()

```python
pyotp.parse_uri(uri: str) -> TOTP | HOTP
# Parse an otpauth:// URI back into a TOTP or HOTP object.
# Raises ValueError for invalid URIs.

otp = pyotp.parse_uri("otpauth://totp/MyApp:user?secret=JBSWY3DPEHPK3PXP&issuer=MyApp")
assert isinstance(otp, pyotp.TOTP)
```

## Examples

### 1. TOTP with QR Code (using qrcode library)

```python
import pyotp
import qrcode

secret = pyotp.random_base32()
totp = pyotp.TOTP(secret)
uri = totp.provisioning_uri(name="alice@corp.com", issuer_name="CorpAuth")

# Generate QR image for authenticator app scanning
img = qrcode.make(uri)
img.save("totp_qr.png")

# Server-side verification with clock drift tolerance
user_code = "123456"
is_valid = totp.verify(user_code, valid_window=1)  # Accept +/- 30s
```

### 2. HOTP Counter-Based Flow

```python
import pyotp

secret = pyotp.random_base32()
hotp = pyotp.HOTP(secret)

# Server stores counter per user, increments on each successful verify
server_counter = 0
code = hotp.at(server_counter)   # Generate code for current counter
print(f"Your code: {code}")

# Verify -- look ahead a small window to handle desync
for offset in range(5):
    if hotp.verify(code, server_counter + offset):
        server_counter = server_counter + offset + 1  # Advance past used counter
        break
```

### 3. SHA-256 with 8-Digit Codes

```python
import pyotp
import hashlib

secret = pyotp.random_base32()
totp = pyotp.TOTP(secret, digits=8, digest=hashlib.sha256, interval=60)
code = totp.now()  # e.g. "49203916"
assert len(code) == 8
```

## Pitfalls

- **Secrets must be Base32-encoded.** Passing a raw string or hex without encoding
  produces wrong codes. Use `pyotp.random_base32()` or `base64.b32encode()`.
- **Clock skew breaks TOTP.** Server and client clocks must be reasonably synchronized.
  Use `valid_window=1` (or 2) to tolerate +/- 30-60 seconds of drift.
- **`verify()` does not prevent replay.** The same code is valid for the entire
  `interval` window. You must track the last-used timestamp/counter server-side to
  reject replayed codes.
- **Default interval is 30s.** Most authenticator apps (Google Authenticator, Authy)
  expect 30s intervals. Changing `interval` without matching the client app produces
  code mismatches.
- **`valid_window` is symmetric.** `valid_window=2` accepts codes from `t-60s` to
  `t+60s` (5 intervals total), not just 2 intervals forward.
- **HOTP counter desync.** If the user generates codes without verifying, the
  counter advances on their device but not the server. Implement a look-ahead window
  (typically 5-10 attempts) when verifying.
