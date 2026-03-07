# kubernetes v31.0+

Official Python client for the Kubernetes API. Auto-generated from the OpenAPI spec, covers every K8s resource.

```
pip install kubernetes
```

## Quick Start

```python
from kubernetes import client, config

config.load_kube_config()  # from ~/.kube/config
v1 = client.CoreV1Api()
pods = v1.list_namespaced_pod("default")
for pod in pods.items:
    print(f"{pod.metadata.name}: {pod.status.phase}")
```

## Core API

### Configuration

```python
from kubernetes import client, config

# From kubeconfig (~/.kube/config)
config.load_kube_config()
config.load_kube_config(config_file="/path/to/config", context="my-context")

# In-cluster (ServiceAccount)
config.load_incluster_config()

# Custom API client
configuration = client.Configuration()
configuration.host = "https://k8s.example.com:6443"
configuration.api_key["authorization"] = "Bearer <token>"
configuration.verify_ssl = True
api_client = client.ApiClient(configuration)
v1 = client.CoreV1Api(api_client=api_client)
```

### CoreV1Api (Pods, Services, ConfigMaps, Secrets, Namespaces)

```python
v1 = client.CoreV1Api()

# --- Pods ---
# List
pods = v1.list_namespaced_pod("default")
pods = v1.list_pod_for_all_namespaces()
pods = v1.list_namespaced_pod("default", label_selector="app=web")

# Get
pod = v1.read_namespaced_pod("my-pod", "default")
pod.metadata.name
pod.status.phase         # "Running", "Pending", etc.
pod.status.pod_ip

# Create
pod_manifest = client.V1Pod(
    metadata=client.V1ObjectMeta(name="my-pod", labels={"app": "web"}),
    spec=client.V1PodSpec(
        containers=[client.V1Container(
            name="web",
            image="nginx:1.27",
            ports=[client.V1ContainerPort(container_port=80)],
        )]
    ),
)
v1.create_namespaced_pod("default", pod_manifest)

# Delete
v1.delete_namespaced_pod("my-pod", "default")

# --- Services ---
v1.list_namespaced_service("default")
v1.read_namespaced_service("my-svc", "default")

# --- ConfigMaps ---
cm = client.V1ConfigMap(
    metadata=client.V1ObjectMeta(name="my-config"),
    data={"key": "value", "config.yaml": "foo: bar"},
)
v1.create_namespaced_config_map("default", cm)

# --- Secrets ---
import base64
secret = client.V1Secret(
    metadata=client.V1ObjectMeta(name="my-secret"),
    type="Opaque",
    data={"password": base64.b64encode(b"s3cret").decode()},
)
v1.create_namespaced_secret("default", secret)

# --- Namespaces ---
v1.list_namespace()
v1.create_namespace(client.V1Namespace(
    metadata=client.V1ObjectMeta(name="my-ns"),
))
```

### AppsV1Api (Deployments, StatefulSets, DaemonSets)

```python
apps = client.AppsV1Api()

# List deployments
deps = apps.list_namespaced_deployment("default")
for d in deps.items:
    print(f"{d.metadata.name}: {d.status.ready_replicas}/{d.spec.replicas}")

# Create deployment
deployment = client.V1Deployment(
    metadata=client.V1ObjectMeta(name="web", labels={"app": "web"}),
    spec=client.V1DeploymentSpec(
        replicas=3,
        selector=client.V1LabelSelector(match_labels={"app": "web"}),
        template=client.V1PodTemplateSpec(
            metadata=client.V1ObjectMeta(labels={"app": "web"}),
            spec=client.V1PodSpec(containers=[
                client.V1Container(name="web", image="nginx:1.27",
                    ports=[client.V1ContainerPort(container_port=80)]),
            ]),
        ),
    ),
)
apps.create_namespaced_deployment("default", deployment)

# Patch (scale)
apps.patch_namespaced_deployment_scale(
    "web", "default",
    body={"spec": {"replicas": 5}},
)

# Update image (patch)
apps.patch_namespaced_deployment(
    "web", "default",
    body={"spec": {"template": {"spec": {"containers": [
        {"name": "web", "image": "nginx:1.28"}
    ]}}}},
)

# Delete
apps.delete_namespaced_deployment("web", "default")
```

### Watch (Event Streaming)

```python
from kubernetes import watch

w = watch.Watch()

# Watch pods (blocking generator)
for event in w.stream(v1.list_namespaced_pod, "default", timeout_seconds=60):
    evt_type = event["type"]      # ADDED, MODIFIED, DELETED
    pod = event["object"]         # V1Pod
    print(f"{evt_type}: {pod.metadata.name} -> {pod.status.phase}")

# Watch with resource version (resume from where you left off)
pods = v1.list_namespaced_pod("default")
rv = pods.metadata.resource_version
for event in w.stream(v1.list_namespaced_pod, "default", resource_version=rv):
    pass

# Stop the watch
w.stop()
```

### Custom Resources (CRDs)

```python
api = client.CustomObjectsApi()

# List custom resources
resources = api.list_namespaced_custom_object(
    group="mygroup.io",
    version="v1",
    namespace="default",
    plural="myresources",
)

# Create
body = {
    "apiVersion": "mygroup.io/v1",
    "kind": "MyResource",
    "metadata": {"name": "test", "namespace": "default"},
    "spec": {"key": "value"},
}
api.create_namespaced_custom_object("mygroup.io", "v1", "default", "myresources", body)

# Patch
api.patch_namespaced_custom_object(
    "mygroup.io", "v1", "default", "myresources", "test",
    body={"spec": {"key": "new-value"}},
)

# Delete
api.delete_namespaced_custom_object("mygroup.io", "v1", "default", "myresources", "test")
```

## Examples

### Wait for deployment rollout

```python
from kubernetes import client, config, watch
import time

config.load_kube_config()
apps = client.AppsV1Api()

def wait_for_rollout(name, namespace, timeout=120):
    start = time.time()
    while time.time() - start < timeout:
        dep = apps.read_namespaced_deployment(name, namespace)
        if (dep.status.ready_replicas or 0) == dep.spec.replicas:
            return True
        time.sleep(2)
    raise TimeoutError(f"Deployment {name} not ready after {timeout}s")
```

### Exec into a pod

```python
from kubernetes.stream import stream

resp = stream(
    v1.connect_get_namespaced_pod_exec,
    "my-pod", "default",
    command=["sh", "-c", "ls -la /app"],
    stderr=True, stdin=False, stdout=True, tty=False,
)
print(resp)
```

### Port forward

```python
from kubernetes.stream import portforward

pf = portforward(
    v1.connect_get_namespaced_pod_portforward,
    "my-pod", "default", ports="8080",
)
# pf.socket(8080) -> socket connected to pod:8080
```

## Pitfalls

1. **load_kube_config vs load_incluster_config**: Use `load_kube_config()` for local dev, `load_incluster_config()` inside pods. Calling the wrong one raises `ConfigException`.
2. **API group matters**: Pods are `CoreV1Api`, Deployments are `AppsV1Api`, Ingress is `NetworkingV1Api`. Using the wrong API class gives 404s.
3. **Verbose object construction**: Creating resources requires deeply nested client objects. For simple cases, pass a dict via `body=` parameter instead.
4. **Watch timeout**: Without `timeout_seconds`, `watch.Watch().stream()` blocks forever. Always set a timeout or handle graceful shutdown.
5. **resource_version for watches**: Without `resource_version`, watches replay all existing resources as ADDED events. Track the version to resume efficiently.
6. **Secret data is base64**: `V1Secret.data` values must be base64-encoded strings. Forgetting to encode causes API errors.
7. **API exceptions**: Failed API calls raise `kubernetes.client.exceptions.ApiException` with `.status` (int), `.reason` (str), and `.body` (JSON string). Always catch and inspect.
