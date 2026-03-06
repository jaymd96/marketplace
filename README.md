# jaymd96-marketplace

Personal Claude Code plugin marketplace.

A Claude Code plugin marketplace maintained by **jaymd96**.

## Plugins

| Plugin | Version | Source | Description |
|--------|---------|--------|-------------|
| pytest-testing | 0.1.0 | local | Write, run, and optimise Python test suites with pytest. Speed-first defaults, structured LLM output via pytest-verdict, progressive guidance from first test to CI pipeline. |

## Usage

```python
from psclaude import PsClaude

client = PsClaude(
    marketplaces=["<owner>/jaymd96-marketplace"],
    install=["pytest-testing@jaymd96-marketplace"],
)
```
