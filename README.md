# jaymd96-marketplace

Personal Claude Code plugin marketplace.

A Claude Code plugin marketplace maintained by **jaymd96**.

## Plugins

| Plugin | Version | Source | Description |
|--------|---------|--------|-------------|
| codecraft | 0.1.0 | local | The craft of turning specs into working code. Iterative, verification-gated software development through disciplined state machines. The execution counterpart to spec-builder. |
| pytest-testing | 0.1.0 | local | Write, run, and optimise Python test suites with pytest. Speed-first defaults, structured LLM output via pytest-verdict, progressive guidance from first test to CI pipeline. |
| python-toolkit | 1.0.0 | local | Opinionated Python development toolkit. Architecture rules for large codebases, 48 pinned library references, testing patterns, and project scaffolding. Python 3.12+ / uv / ruff / mypy. |
| research-builder | 1.0.0 | local | Refine research ideas through extended conversation. A harness for navigating the random walk of ideas, linking to prior work, and progressively tightening arguments into formal results. |
| spec-builder | 1.0.0 | local | Build product specifications through extended human conversation. A harness for turning noisy, non-linear human input into coherent, implementable specs (Symphony-style). |

## Usage

```python
from psclaude import PsClaude

client = PsClaude(
    marketplaces=["<owner>/jaymd96-marketplace"],
    install=["codecraft@jaymd96-marketplace"],
)
```
