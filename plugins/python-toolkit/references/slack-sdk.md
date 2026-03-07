# slack-sdk v3.33+

Official Slack SDK for Python. Covers Web API, Block Kit UI, Events API,
slash commands, and Socket Mode for real-time communication.

**Install:** `pip install slack-sdk`

---

## Quick Start

```python
from slack_sdk import WebClient

client = WebClient(token="xoxb-your-bot-token")
response = client.chat_postMessage(channel="#general", text="Hello from Python!")
print(response["ts"])  # Message timestamp (unique ID)
```

---

## Core API

### WebClient

```python
from slack_sdk import WebClient
from slack_sdk.errors import SlackApiError

client = WebClient(
    token: str = None,           # Bot or user token (xoxb-* or xoxp-*)
    base_url: str = "https://slack.com/api/",
    timeout: int = 30,
    ssl: ssl.SSLContext | None = None,
    proxy: str | None = None,
    headers: dict | None = None,
)

# Async variant
from slack_sdk.web.async_client import AsyncWebClient
async_client = AsyncWebClient(token="xoxb-...")
```

### Messaging

```python
# Post a message
client.chat_postMessage(
    channel="#general",            # Channel name, ID, or user ID for DM
    text="Fallback text",         # Required (used in notifications)
    blocks=[...],                 # Block Kit blocks (optional)
    thread_ts="1234567890.123456",# Reply in thread
    reply_broadcast=False,        # Also post to channel
    unfurl_links=True,            # Expand URL previews
    unfurl_media=True,            # Expand media previews
    mrkdwn=True,                  # Parse markdown
    metadata=None,                # Message metadata (event payload)
)

# Update a message
client.chat_update(
    channel="C0123456",
    ts="1234567890.123456",       # Timestamp of message to update
    text="Updated text",
    blocks=[...],
)

# Delete a message
client.chat_delete(channel="C0123456", ts="1234567890.123456")

# Schedule a message
client.chat_scheduleMessage(
    channel="#general",
    text="Scheduled message",
    post_at=1700000000,           # Unix timestamp
)

# Ephemeral message (only visible to one user)
client.chat_postEphemeral(
    channel="#general",
    user="U0123456",
    text="Only you can see this",
)
```

### File Uploads

```python
# Upload a file (v2 API -- preferred)
client.files_upload_v2(
    channel="C0123456",
    file="./report.pdf",                # Local file path
    # or: content="raw string content", # String content
    # or: file=io.BytesIO(b"..."),      # File-like object
    title="Monthly Report",
    initial_comment="Here's the report",
    filename="report.pdf",
)

# Multiple files
client.files_upload_v2(
    channel="C0123456",
    file_uploads=[
        {"file": "./data.csv", "title": "Data"},
        {"file": "./chart.png", "title": "Chart"},
    ],
    initial_comment="Data and visualization",
)
```

### Block Kit

```python
blocks = [
    {
        "type": "header",
        "text": {"type": "plain_text", "text": "Deployment Alert"}
    },
    {
        "type": "section",
        "text": {"type": "mrkdwn", "text": "*Service:* api-gateway\n*Status:* Deployed"},
        "accessory": {
            "type": "button",
            "text": {"type": "plain_text", "text": "View Logs"},
            "action_id": "view_logs",
            "url": "https://logs.example.com",
        },
    },
    {"type": "divider"},
    {
        "type": "actions",
        "elements": [
            {
                "type": "button",
                "text": {"type": "plain_text", "text": "Approve"},
                "style": "primary",
                "action_id": "approve_deploy",
                "value": "deploy-123",
            },
            {
                "type": "button",
                "text": {"type": "plain_text", "text": "Rollback"},
                "style": "danger",
                "action_id": "rollback_deploy",
                "value": "deploy-123",
            },
        ],
    },
    {
        "type": "context",
        "elements": [
            {"type": "mrkdwn", "text": "Deployed by <@U0123456> at <!date^1700000000^{date_short} {time}|2023-11-14>"}
        ],
    },
]

client.chat_postMessage(channel="#deploys", text="Deployment Alert", blocks=blocks)
```

### Block Kit Models (Type-Safe)

```python
from slack_sdk.models.blocks import SectionBlock, ActionsBlock, ButtonElement
from slack_sdk.models.blocks import MarkdownTextObject, PlainTextObject

blocks = [
    SectionBlock(text=MarkdownTextObject(text="*Hello* world")),
    ActionsBlock(elements=[
        ButtonElement(text=PlainTextObject(text="Click me"), action_id="btn_click"),
    ]),
]
```

### Conversations & Channels

```python
# List channels
result = client.conversations_list(types="public_channel,private_channel", limit=200)
channels = result["channels"]

# Get channel info
client.conversations_info(channel="C0123456")

# List members
client.conversations_members(channel="C0123456", limit=200)

# Channel history
client.conversations_history(channel="C0123456", limit=100)

# Replies in a thread
client.conversations_replies(channel="C0123456", ts="1234567890.123456")
```

### Slash Commands (Server-Side Handler)

```python
# Slash commands send POST to your URL. Parse the payload:
from flask import Flask, request, jsonify

app = Flask(__name__)

@app.route("/slack/commands", methods=["POST"])
def handle_command():
    command = request.form["command"]        # "/deploy"
    text = request.form["text"]              # "api-gateway production"
    user_id = request.form["user_id"]        # "U0123456"
    response_url = request.form["response_url"]

    # Immediate response (must reply within 3 seconds)
    return jsonify({
        "response_type": "in_channel",      # or "ephemeral"
        "text": f"Deploying {text}...",
    })
```

### Events API

```python
# Events come as POST to your endpoint. Verify with signing secret.
from slack_sdk.signature import SignatureVerifier

verifier = SignatureVerifier(signing_secret="your-signing-secret")

def handle_event(request):
    if not verifier.is_valid_request(request.body, request.headers):
        return 403

    payload = request.json()

    # URL verification challenge (one-time setup)
    if payload.get("type") == "url_verification":
        return {"challenge": payload["challenge"]}

    # Event dispatch
    event = payload.get("event", {})
    if event.get("type") == "message" and "subtype" not in event:
        handle_message(event)

    return 200
```

### Socket Mode (No Public URL Required)

```python
from slack_sdk.socket_mode import SocketModeClient
from slack_sdk.socket_mode.request import SocketModeRequest
from slack_sdk.socket_mode.response import SocketModeResponse

client = SocketModeClient(
    app_token="xapp-...",               # App-level token
    web_client=WebClient(token="xoxb-..."),
)

def handle(client: SocketModeClient, req: SocketModeRequest):
    # Acknowledge within 3 seconds
    client.send_socket_mode_response(SocketModeResponse(envelope_id=req.envelope_id))

    if req.type == "events_api":
        event = req.payload["event"]
        if event["type"] == "message":
            client.web_client.chat_postMessage(
                channel=event["channel"],
                text=f"Echo: {event['text']}",
                thread_ts=event["ts"],
            )
    elif req.type == "slash_commands":
        command_payload = req.payload
        # Handle slash command
    elif req.type == "interactive":
        action_payload = req.payload
        # Handle button clicks, modals, etc.

client.socket_mode_request_listeners.append(handle)
client.connect()

# Async variant
from slack_sdk.socket_mode.async_client import AsyncSocketModeClient
from slack_sdk.socket_mode.aiohttp import SocketModeClient as AiohttpSocketModeClient
```

### Rate Limiting

```python
from slack_sdk import WebClient
from slack_sdk.errors import SlackApiError
import time

client = WebClient(token="xoxb-...")

def send_with_retry(channel: str, text: str, max_retries: int = 3):
    for attempt in range(max_retries):
        try:
            return client.chat_postMessage(channel=channel, text=text)
        except SlackApiError as e:
            if e.response.status_code == 429:
                retry_after = int(e.response.headers.get("Retry-After", 1))
                time.sleep(retry_after)
            else:
                raise

# WebClient has built-in rate limit handling via RetryHandler
from slack_sdk.http_retry.builtin_handlers import RateLimitErrorRetryHandler

client = WebClient(token="xoxb-...")
client.retry_handlers.append(RateLimitErrorRetryHandler(max_retry_count=3))
```

---

## Examples

### Interactive Notification with Follow-Up

```python
def notify_deploy(client: WebClient, channel: str, service: str, version: str):
    result = client.chat_postMessage(
        channel=channel,
        text=f"Deploying {service} {version}",
        blocks=[
            {"type": "section", "text": {"type": "mrkdwn",
                "text": f":rocket: *{service}* `{version}` deploying..."}},
            {"type": "actions", "elements": [
                {"type": "button", "text": {"type": "plain_text", "text": "Cancel"},
                 "style": "danger", "action_id": "cancel_deploy", "value": service},
            ]},
        ],
    )
    return result["ts"]

def update_deploy_status(client: WebClient, channel: str, ts: str, service: str, status: str):
    emoji = ":white_check_mark:" if status == "success" else ":x:"
    client.chat_update(
        channel=channel, ts=ts,
        text=f"{service} deploy {status}",
        blocks=[
            {"type": "section", "text": {"type": "mrkdwn",
                "text": f"{emoji} *{service}* deploy *{status}*"}},
        ],
    )
```

### Paginating Results

```python
def get_all_channels(client: WebClient) -> list[dict]:
    channels = []
    cursor = None
    while True:
        result = client.conversations_list(
            types="public_channel",
            limit=200,
            cursor=cursor,
        )
        channels.extend(result["channels"])
        cursor = result.get("response_metadata", {}).get("next_cursor")
        if not cursor:
            break
    return channels
```

---

## Pitfalls

1. **`text` is always required.** Even when using `blocks`, you must provide `text` as
   a fallback for notifications, accessibility, and clients that don't render blocks.

2. **3-second response deadline.** Slash commands and interactive actions must be
   acknowledged within 3 seconds. Do heavy work asynchronously and use `response_url`
   for delayed responses.

3. **Bot token vs user token.** Bot tokens (`xoxb-*`) have bot scopes; user tokens
   (`xoxp-*`) act as a user. Most apps need bot tokens. Some APIs (e.g., `admin.*`)
   require user tokens.

4. **Rate limits are per-method and per-workspace.** Different API methods have
   different limits (e.g., `chat.postMessage` is ~1/sec per channel). Use the built-in
   `RateLimitErrorRetryHandler` instead of manual retry logic.

5. **Socket Mode requires app-level token.** The `xapp-*` token is separate from the
   bot token. Generate it in your app's settings under "Basic Information".

6. **`files_upload_v2` replaces `files_upload`.** The v1 upload API is deprecated.
   Use `files_upload_v2` which uses a more efficient upload mechanism.

7. **Cursor-based pagination.** Most list methods return paginated results. Always check
   `response_metadata.next_cursor` and loop until it's empty.
