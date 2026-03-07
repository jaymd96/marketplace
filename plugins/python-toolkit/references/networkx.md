# NetworkX v3.4

## Quick Start

```python
import networkx as nx

G = nx.DiGraph()
G.add_edges_from([("A", "B"), ("A", "C"), ("B", "D"), ("C", "D")])
list(nx.topological_sort(G))        # dependency order
nx.is_directed_acyclic_graph(G)     # True
```

## Core API

```python
# Graph types
nx.Graph()          # undirected
nx.DiGraph()        # directed
nx.MultiGraph()     # undirected, parallel edges
nx.MultiDiGraph()   # directed, parallel edges

# Nodes and edges
G.add_node("A", color="red")
G.add_nodes_from(["B", "C"])
G.add_edge("A", "B", weight=1.5)
G.add_edges_from([("A", "C"), ("B", "C")])
G.add_weighted_edges_from([("A", "B", 1.0)])
G.remove_node("A")                              # also removes edges
G.remove_edge("A", "B")

# Properties
G.number_of_nodes() / G.number_of_edges()
G.has_node("A") / G.has_edge("A", "B")
G.nodes["A"]["color"]                           # node attrs
G.edges["A", "B"]["weight"]                     # edge attrs
list(G.neighbors("A"))
G.degree("A") / G.in_degree("A") / G.out_degree("A")  # DiGraph

# DAG operations (most common)
nx.topological_sort(G)                          # generator, dependency order
nx.topological_generations(G)                   # groups for parallel execution
nx.ancestors(G, "D")                            # transitive predecessors
nx.descendants(G, "A")                          # transitive successors
nx.dag_longest_path(G)                          # critical path
nx.is_directed_acyclic_graph(G)

# Shortest paths
nx.shortest_path(G, "A", "D")                  # unweighted
nx.dijkstra_path(G, "A", "D", weight="cost")   # weighted

# Cycles
nx.is_directed_acyclic_graph(G)
list(nx.simple_cycles(G))                       # all cycles (DiGraph)
nx.find_cycle(G)                                # raises NetworkXNoCycle if none

# Subgraphs
H = G.subgraph(["A", "B", "C"])                # read-only view
H_mut = G.subgraph(["A", "B"]).copy()           # mutable copy

# Serialization
from networkx.readwrite import json_graph
data = json_graph.node_link_data(G)             # JSON-serializable dict
G = json_graph.node_link_graph(data)            # restore
```

## Examples

### Dependency resolution with topological sort

```python
G = nx.DiGraph()
G.add_edges_from([("install", "build"), ("build", "test"), ("test", "deploy")])
order = list(nx.topological_sort(G))  # ["install", "build", "test", "deploy"]
```

### Parallel execution groups

```python
G = nx.DiGraph()
G.add_edges_from([("A", "C"), ("B", "C"), ("C", "D")])
for gen in nx.topological_generations(G):
    print(gen)  # ["A", "B"] (parallel), ["C"], ["D"]
```

### Weighted shortest path

```python
G = nx.Graph()
G.add_weighted_edges_from([("A", "B", 1), ("B", "C", 3), ("A", "C", 10)])
path = nx.dijkstra_path(G, "A", "C", weight="weight")  # ["A", "B", "C"]
```

## Pitfalls

- **Nodes are auto-created**: `G.add_edge("X", "Y")` creates both nodes if they do not exist.
- **Subgraph views are read-only**: call `.copy()` for a mutable subgraph.
- **Removing a node removes all its edges**: by design, but can be surprising.
- **DiGraph edge direction**: `G.has_edge("A", "B")` != `G.has_edge("B", "A")`.
- **Node types**: any hashable object works as a node (str, int, tuple). Be consistent.
- **Cycle detection in DAGs**: `topological_sort()` raises `NetworkXUnfeasible` if cycles exist.
