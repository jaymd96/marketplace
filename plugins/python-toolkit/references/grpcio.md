# grpcio v1.68+

gRPC framework for Python. High-performance RPC using Protocol Buffers. Supports unary, server-streaming, client-streaming, and bidirectional-streaming RPCs.

```
pip install grpcio grpcio-tools
```

## Quick Start

1. Define service in `.proto`, 2. Generate stubs, 3. Implement server, 4. Create client.

```protobuf
// greeter.proto
syntax = "proto3";
package greeter;

service Greeter {
  rpc SayHello (HelloRequest) returns (HelloReply);
}
message HelloRequest { string name = 1; }
message HelloReply { string message = 1; }
```

```bash
python -m grpc_tools.protoc -I. --python_out=. --grpc_python_out=. greeter.proto
# generates: greeter_pb2.py, greeter_pb2_grpc.py
```

## Core API

### Server Setup

```python
import grpc
from concurrent import futures
import greeter_pb2
import greeter_pb2_grpc

class GreeterServicer(greeter_pb2_grpc.GreeterServicer):
    def SayHello(self, request, context):
        return greeter_pb2.HelloReply(message=f"Hello, {request.name}!")

def serve():
    server = grpc.server(
        futures.ThreadPoolExecutor(max_workers=10),
        options=[
            ("grpc.max_receive_message_length", 50 * 1024 * 1024),  # 50 MB
            ("grpc.max_send_message_length", 50 * 1024 * 1024),
        ],
    )
    greeter_pb2_grpc.add_GreeterServicer_to_server(GreeterServicer(), server)
    server.add_insecure_port("[::]:50051")
    server.start()
    server.wait_for_termination()
```

### Client (Stub)

```python
import grpc
import greeter_pb2
import greeter_pb2_grpc

# Insecure
channel = grpc.insecure_channel("localhost:50051")
stub = greeter_pb2_grpc.GreeterStub(channel)
response = stub.SayHello(greeter_pb2.HelloRequest(name="World"))
print(response.message)  # "Hello, World!"

# Secure (TLS)
creds = grpc.ssl_channel_credentials(
    root_certificates=open("ca.pem", "rb").read(),
)
channel = grpc.secure_channel("host:443", creds)

# With metadata (auth headers)
response = stub.SayHello(
    greeter_pb2.HelloRequest(name="World"),
    metadata=[("authorization", "Bearer token123")],
)

# With timeout
response = stub.SayHello(request, timeout=5.0)  # seconds
```

### RPC Types

```protobuf
service MyService {
  rpc Unary(Req) returns (Resp);                          // 1:1
  rpc ServerStream(Req) returns (stream Resp);             // 1:N
  rpc ClientStream(stream Req) returns (Resp);             // N:1
  rpc BidiStream(stream Req) returns (stream Resp);        // N:N
}
```

```python
# Server-side implementations
class MyServicer(my_pb2_grpc.MyServiceServicer):

    # Unary
    def Unary(self, request, context):
        return my_pb2.Resp(value=request.data)

    # Server streaming
    def ServerStream(self, request, context):
        for i in range(request.count):
            yield my_pb2.Resp(value=str(i))

    # Client streaming
    def ClientStream(self, request_iterator, context):
        total = sum(r.value for r in request_iterator)
        return my_pb2.Resp(value=total)

    # Bidirectional streaming
    def BidiStream(self, request_iterator, context):
        for request in request_iterator:
            yield my_pb2.Resp(value=request.data.upper())
```

```python
# Client-side calls

# Server streaming
for resp in stub.ServerStream(my_pb2.Req(count=5)):
    print(resp.value)

# Client streaming
def generate_requests():
    for i in range(5):
        yield my_pb2.Req(value=i)
response = stub.ClientStream(generate_requests())

# Bidi streaming
responses = stub.BidiStream(generate_requests())
for resp in responses:
    print(resp.value)
```

### Error Handling (context)

```python
# Server: set error status
class MyServicer(my_pb2_grpc.MyServiceServicer):
    def Unary(self, request, context):
        if not request.name:
            context.abort(grpc.StatusCode.INVALID_ARGUMENT, "name is required")
        if not authorized(context):
            context.abort(grpc.StatusCode.PERMISSION_DENIED, "unauthorized")
        return my_pb2.Resp(value="ok")

# Client: catch errors
try:
    response = stub.Unary(request)
except grpc.RpcError as e:
    e.code()     # -> grpc.StatusCode.INVALID_ARGUMENT
    e.details()  # -> "name is required"
```

### Interceptors

```python
# Server interceptor
class LoggingInterceptor(grpc.ServerInterceptor):
    def intercept_service(self, continuation, handler_call_details):
        print(f"Method: {handler_call_details.method}")
        return continuation(handler_call_details)

server = grpc.server(
    futures.ThreadPoolExecutor(max_workers=10),
    interceptors=[LoggingInterceptor()],
)

# Client interceptor (unary-unary)
class AuthInterceptor(grpc.UnaryUnaryClientInterceptor):
    def __init__(self, token):
        self.token = token

    def intercept_unary_unary(self, continuation, client_call_details, request):
        metadata = list(client_call_details.metadata or [])
        metadata.append(("authorization", f"Bearer {self.token}"))
        new_details = client_call_details._replace(metadata=metadata)
        return continuation(new_details, request)

channel = grpc.intercept_channel(
    grpc.insecure_channel("localhost:50051"),
    AuthInterceptor("my-token"),
)
```

### Async (asyncio)

```python
import grpc.aio

async def serve():
    server = grpc.aio.server()
    greeter_pb2_grpc.add_GreeterServicer_to_server(GreeterServicer(), server)
    server.add_insecure_port("[::]:50051")
    await server.start()
    await server.wait_for_termination()

async def client():
    async with grpc.aio.insecure_channel("localhost:50051") as channel:
        stub = greeter_pb2_grpc.GreeterStub(channel)
        response = await stub.SayHello(greeter_pb2.HelloRequest(name="World"))
```

## Examples

### Health check service

```python
from grpc_health.v1 import health, health_pb2, health_pb2_grpc

health_servicer = health.HealthServicer()
health_pb2_grpc.add_HealthServicer_to_server(health_servicer, server)
health_servicer.set("myservice", health_pb2.HealthCheckResponse.SERVING)
```

### Reflection (for grpcurl / grpcui)

```python
from grpc_reflection.v1alpha import reflection

SERVICE_NAMES = (
    greeter_pb2.DESCRIPTOR.services_by_name["Greeter"].full_name,
    reflection.SERVICE_NAME,
)
reflection.enable_server_reflection(SERVICE_NAMES, server)
```

## Pitfalls

1. **Proto codegen is required**: You cannot skip `grpc_tools.protoc`. The `_pb2.py` and `_pb2_grpc.py` files must be regenerated whenever `.proto` changes.
2. **Default message size is 4 MB**: Larger payloads fail silently. Set `grpc.max_receive_message_length` and `grpc.max_send_message_length` in server options.
3. **ThreadPoolExecutor sizing**: Default `max_workers` is small. For I/O-heavy services, increase it. For CPU-heavy work, use the async API.
4. **Channel is not a connection**: `grpc.insecure_channel()` is lazy. Connection happens on first RPC. Check connectivity with `channel_ready_future()`.
5. **context.abort() does not return**: After `context.abort()`, execution continues on the server side. Always `return` after abort or use it as the last statement.
6. **Streaming generators must not raise**: If a client-streaming generator raises, the error is swallowed. Validate before yielding.
7. **Import order matters**: Import `_pb2` before `_pb2_grpc` -- the grpc module depends on the protobuf definitions being loaded.
