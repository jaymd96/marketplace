# hvac v2.3+

Python client for HashiCorp Vault. Provides typed access to Vault's HTTP API including
KV secrets, transit encryption, PKI certificates, and authentication methods.

**Install:** `pip install hvac`

---

## Quick Start

```python
import hvac

client = hvac.Client(url="http://127.0.0.1:8200", token="hvs.my-root-token")
assert client.is_authenticated()

client.secrets.kv.v2.create_or_update_secret(path="myapp/config", secret={"api_key": "abc123"})
secret = client.secrets.kv.v2.read_secret_version(path="myapp/config")
print(secret["data"]["data"]["api_key"])  # "abc123"
```

---

## Core API

### Client

```python
hvac.Client(
    url: str = "http://localhost:8200",    # Vault server URL
    token: str | None = None,              # Authentication token
    cert: tuple | None = None,             # Client TLS cert (cert_path, key_path)
    verify: bool | str = True,             # TLS verify (True, False, or CA bundle path)
    timeout: int = 30,                     # Request timeout in seconds
    namespace: str | None = None,          # Vault namespace (Enterprise)
    session: requests.Session | None = None,
)

# Properties
client.is_authenticated() -> bool       # Check token validity
client.token                            # Get/set current token
client.sys                              # System backend accessor
client.auth                             # Auth methods accessor
client.secrets                          # Secrets engines accessor
```

### KV v2 (Key-Value Secrets Engine)

```python
kv = client.secrets.kv.v2   # or client.secrets.kv.default_kv_version = 2

# Write / Update
kv.create_or_update_secret(
    path: str,                  # Secret path (e.g. "myapp/config")
    secret: dict,               # Key-value pairs to store
    cas: int | None = None,     # Check-and-Set version (optimistic locking)
    mount_point: str = "secret",
)

# Read
response = kv.read_secret_version(
    path: str,                  # Secret path
    version: int | None = None, # Specific version (None = latest)
    mount_point: str = "secret",
    raise_on_deleted_version: bool = True,
)
# response["data"]["data"]       -> {"api_key": "abc123"}
# response["data"]["metadata"]   -> {"version": 1, "created_time": "...", ...}

# Read metadata (without secret data)
kv.read_secret_metadata(path, mount_point="secret")

# List secrets
kv.list_secrets(path="myapp/", mount_point="secret")
# Returns {"data": {"keys": ["config", "db/"]}}

# Delete (soft delete -- marks version as deleted)
kv.delete_secret_versions(path, versions=[1, 2], mount_point="secret")

# Undelete (restore soft-deleted version)
kv.undelete_secret_versions(path, versions=[1], mount_point="secret")

# Destroy (permanent -- cannot be recovered)
kv.destroy_secret_versions(path, versions=[1], mount_point="secret")

# Patch (merge with existing secret)
kv.patch(path, secret={"new_key": "value"}, mount_point="secret")
```

### Token Authentication

```python
# Already authenticated via Client(token=...)

# Create a new token
client.auth.token.create(
    policies=["my-policy"],
    ttl="1h",
    renewable=True,
)

# Lookup current token
client.auth.token.lookup_self()

# Renew
client.auth.token.renew_self(increment="1h")

# Revoke
client.auth.token.revoke_self()
```

### AppRole Authentication

```python
# Login with AppRole
result = client.auth.approle.login(
    role_id="my-role-id",
    secret_id="my-secret-id",
    mount_point="approle",
)
client.token = result["auth"]["client_token"]

# Manage roles (requires admin)
client.auth.approle.create_or_update_approle(
    role_name="my-app",
    token_policies=["my-policy"],
    token_ttl="1h",
    token_max_ttl="4h",
    mount_point="approle",
)

# Generate credentials
role_id = client.auth.approle.read_role_id("my-app")["data"]["role_id"]
secret_id = client.auth.approle.generate_secret_id("my-app")["data"]["secret_id"]
```

### Transit Engine (Encryption as a Service)

```python
transit = client.secrets.transit

# Create encryption key
transit.create_key(name="my-key", key_type="aes256-gcm96", mount_point="transit")

# Encrypt (plaintext must be base64-encoded)
import base64
plaintext = base64.b64encode(b"sensitive data").decode()
result = transit.encrypt_data(name="my-key", plaintext=plaintext, mount_point="transit")
ciphertext = result["data"]["ciphertext"]  # "vault:v1:..."

# Decrypt
result = transit.decrypt_data(name="my-key", ciphertext=ciphertext, mount_point="transit")
decoded = base64.b64decode(result["data"]["plaintext"]).decode()  # "sensitive data"

# Rotate key (old ciphertexts still decryptable)
transit.rotate_key(name="my-key", mount_point="transit")

# Rewrap (re-encrypt with latest key version without exposing plaintext)
transit.rewrap_data(name="my-key", ciphertext=ciphertext, mount_point="transit")
```

### PKI Engine (Certificate Authority)

```python
pki = client.secrets.pki

# Generate root CA
pki.generate_root(
    type="internal",
    common_name="My Root CA",
    ttl="87600h",          # 10 years
    mount_point="pki",
)

# Create role for issuing certs
pki.create_or_update_role(
    name="web-server",
    allowed_domains=["example.com"],
    allow_subdomains=True,
    max_ttl="720h",
    mount_point="pki",
)

# Issue certificate
cert = pki.generate_certificate(
    name="web-server",
    common_name="app.example.com",
    ttl="168h",            # 7 days
    mount_point="pki",
)
# cert["data"]["certificate"], cert["data"]["private_key"]

# Read CA certificate
ca = pki.read_ca_certificate(mount_point="pki")

# List certificates
pki.list_certificates(mount_point="pki")
```

### Lease Management

```python
# Renew a lease
client.sys.renew_lease(lease_id="pki/issue/web-server/abc123", increment=3600)

# Revoke a lease
client.sys.revoke_lease(lease_id="pki/issue/web-server/abc123")

# Lookup lease
client.sys.read_lease(lease_id="pki/issue/web-server/abc123")
```

---

## Examples

### Application Bootstrap Pattern

```python
import hvac
import os

def get_vault_client() -> hvac.Client:
    client = hvac.Client(url=os.environ["VAULT_ADDR"])

    # Try AppRole first, fall back to token
    role_id = os.environ.get("VAULT_ROLE_ID")
    secret_id = os.environ.get("VAULT_SECRET_ID")
    if role_id and secret_id:
        result = client.auth.approle.login(role_id=role_id, secret_id=secret_id)
        client.token = result["auth"]["client_token"]
    else:
        client.token = os.environ["VAULT_TOKEN"]

    assert client.is_authenticated(), "Vault authentication failed"
    return client

def load_config(client: hvac.Client) -> dict:
    response = client.secrets.kv.v2.read_secret_version(path="myapp/config")
    return response["data"]["data"]
```

### Encrypt/Decrypt Helper

```python
import base64, hvac

class VaultCrypto:
    def __init__(self, client: hvac.Client, key_name: str):
        self.transit = client.secrets.transit
        self.key = key_name

    def encrypt(self, plaintext: str) -> str:
        b64 = base64.b64encode(plaintext.encode()).decode()
        resp = self.transit.encrypt_data(name=self.key, plaintext=b64)
        return resp["data"]["ciphertext"]

    def decrypt(self, ciphertext: str) -> str:
        resp = self.transit.decrypt_data(name=self.key, ciphertext=ciphertext)
        return base64.b64decode(resp["data"]["plaintext"]).decode()
```

---

## Pitfalls

1. **KV v2 response nesting.** Secret data is at `response["data"]["data"]`, not
   `response["data"]`. The outer "data" is the Vault response wrapper; the inner
   "data" contains your key-value pairs.

2. **Transit plaintext must be base64.** The transit engine expects base64-encoded
   plaintext. Passing raw strings silently produces garbage or errors.

3. **mount_point defaults vary.** KV defaults to `"secret"`, Transit to `"transit"`,
   PKI to `"pki"`. If you mounted an engine at a custom path, you must specify it.

4. **Token expiry.** Tokens expire silently. Check `client.is_authenticated()` before
   operations, and implement token renewal for long-running services.

5. **CAS (Check-and-Set).** Without `cas=<version>`, concurrent writes overwrite each
   other silently. Use CAS for safe concurrent updates.

6. **`hvac.exceptions.Forbidden` vs `InvalidRequest`.** A 403 usually means a policy
   issue (the token lacks permission), not that the path is wrong. Check Vault policies
   first.

7. **Soft delete vs destroy.** `delete_secret_versions` is recoverable (soft delete).
   `destroy_secret_versions` is permanent. Know which one you need.
