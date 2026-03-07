# boto3

**AWS SDK for Python** | v1.35+ (latest 1.42.x) | `pip install boto3`

Official AWS SDK. Provides low-level client API and high-level resource API for interacting with AWS services.

## Quick Start

```python
import boto3

# Low-level client
s3 = boto3.client("s3")
s3.upload_file("local.txt", "my-bucket", "remote.txt")

# High-level resource
s3_res = boto3.resource("s3")
bucket = s3_res.Bucket("my-bucket")
for obj in bucket.objects.all():
    print(obj.key)
```

## Core Concepts

### Session

```python
import boto3

session = boto3.Session()                          # Default (~/.aws/credentials, env, instance profile)
session = boto3.Session(region_name="us-east-1", profile_name="dev")  # Explicit
s3 = session.client("s3")                          # Create client from session
dynamo = session.resource("dynamodb")              # Create resource from session
```

### Client vs Resource

| | Client | Resource |
|---|--------|----------|
| API | 1:1 mapping to AWS HTTP API | Object-oriented abstraction |
| Coverage | All services, all operations | S3, EC2, DynamoDB, SQS, SNS, IAM, etc. |
| Return type | Dict | Objects with attributes and methods |
| Recommended | Complex/newer APIs | Common CRUD patterns |

**Note:** AWS has stopped adding new Resource interfaces. Client is the future-proof choice.

## S3

### Upload and Download

```python
s3 = boto3.client("s3")

# Upload
s3.upload_file("local.csv", "my-bucket", "data/file.csv")
s3.upload_fileobj(file_obj, "my-bucket", "data/file.csv")  # From file-like object
s3.put_object(Bucket="my-bucket", Key="data/msg.txt", Body=b"hello")

# Download
s3.download_file("my-bucket", "data/file.csv", "local.csv")
s3.download_fileobj("my-bucket", "data/file.csv", file_obj)
response = s3.get_object(Bucket="my-bucket", Key="data/msg.txt")
body = response["Body"].read()
```

### List Objects

```python
# Simple (max 1000 keys)
response = s3.list_objects_v2(Bucket="my-bucket", Prefix="data/")
for obj in response.get("Contents", []):
    print(obj["Key"], obj["Size"])

# Paginated (handles any number of keys)
paginator = s3.get_paginator("list_objects_v2")
for page in paginator.paginate(Bucket="my-bucket", Prefix="data/"):
    for obj in page.get("Contents", []):
        print(obj["Key"])
```

### Presigned URLs

```python
url = s3.generate_presigned_url(
    "get_object",
    Params={"Bucket": "my-bucket", "Key": "secret.pdf"},
    ExpiresIn=3600,  # seconds
)
```

## SQS

```python
sqs = boto3.client("sqs", region_name="us-east-1")
queue_url = "https://sqs.us-east-1.amazonaws.com/123456789/my-queue"

# Send
sqs.send_message(QueueUrl=queue_url, MessageBody='{"event": "order_placed"}')

# Receive (long polling) and delete
response = sqs.receive_message(QueueUrl=queue_url, MaxNumberOfMessages=10,
                               WaitTimeSeconds=20, MessageAttributeNames=["All"])
for msg in response.get("Messages", []):
    print(msg["Body"])
    sqs.delete_message(QueueUrl=queue_url, ReceiptHandle=msg["ReceiptHandle"])
```

## DynamoDB

```python
# Resource interface (recommended for DynamoDB)
dynamodb = boto3.resource("dynamodb", region_name="us-east-1")
table = dynamodb.Table("Users")

# Put item
table.put_item(Item={"user_id": "u123", "name": "Alice", "age": 30})

# Get item
response = table.get_item(Key={"user_id": "u123"})
item = response.get("Item")

# Query (partition key required, sort key optional)
from boto3.dynamodb.conditions import Key, Attr
response = table.query(
    KeyConditionExpression=Key("user_id").eq("u123"),
    FilterExpression=Attr("age").gt(25),
)

# Scan (full table -- expensive)
response = table.scan(FilterExpression=Attr("age").between(20, 40))

# Batch write
with table.batch_writer() as batch:
    for item in items:
        batch.put_item(Item=item)
```

## IAM and STS

```python
iam = boto3.client("iam")
paginator = iam.get_paginator("list_users")
for page in paginator.paginate():
    for user in page["Users"]:
        print(user["UserName"])

# Assume role
sts = boto3.client("sts")
creds = sts.assume_role(RoleArn="arn:aws:iam::123456789:role/MyRole",
                        RoleSessionName="my-session")["Credentials"]
s3 = boto3.client("s3", aws_access_key_id=creds["AccessKeyId"],
                   aws_secret_access_key=creds["SecretAccessKey"],
                   aws_session_token=creds["SessionToken"])
```

## Pagination

```python
# Generic pattern -- works for any paginated API
paginator = boto3.client("s3").get_paginator("list_objects_v2")
pages = paginator.paginate(Bucket="my-bucket",
                           PaginationConfig={"MaxItems": 1000, "PageSize": 100})
# Filter with JMESPath
for obj in pages.search("Contents[?Size > `1000`]"):
    print(obj["Key"], obj["Size"])
```

## Examples

### 1. Copy all objects between buckets

```python
s3 = boto3.client("s3")
for page in s3.get_paginator("list_objects_v2").paginate(Bucket="source-bucket"):
    for obj in page.get("Contents", []):
        s3.copy_object(CopySource={"Bucket": "source-bucket", "Key": obj["Key"]},
                       Bucket="dest-bucket", Key=obj["Key"])
```

### 2. SQS consumer loop

```python
sqs = boto3.client("sqs")
while True:
    resp = sqs.receive_message(QueueUrl=url, WaitTimeSeconds=20, MaxNumberOfMessages=10)
    for msg in resp.get("Messages", []):
        process(msg["Body"])
        sqs.delete_message(QueueUrl=url, ReceiptHandle=msg["ReceiptHandle"])
```

## Pitfalls

- **Default region** -- boto3 uses `us-east-1` by default only if configured. Always set `region_name` explicitly or via `AWS_DEFAULT_REGION`.
- **Pagination required** -- Most list APIs return max 1000 items. Always use paginators for production code.
- **Resource deprecation** -- AWS is not adding new Resource interfaces. Use Client for newer services (Lambda, ECS, etc.).
- **SQS at-least-once** -- Messages can be delivered more than once. Your consumer must be idempotent. Use FIFO queues for exactly-once.
- **SQS delete after processing** -- Always delete messages after successful processing, or they reappear after visibility timeout.
- **DynamoDB types** -- DynamoDB stores numbers as `Decimal`, not `float`/`int`. Use `boto3.dynamodb.types.TypeDeserializer` or the resource interface (which handles this).
- **Credentials chain** -- boto3 checks: explicit params > env vars > `~/.aws/credentials` > instance metadata. Misconfigured chains cause confusing auth errors.
- **Thread safety** -- Clients are thread-safe. Sessions and Resources are NOT. Create per-thread sessions in multi-threaded code.
