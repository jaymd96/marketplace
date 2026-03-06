# jaymd96-marketplace

Personal Claude Code plugin marketplace maintained by **jaymd96**.

Managed with [guild](https://github.com/jaymd96/guild). Consumed by [psclaude](https://github.com/jaymd96/psclaude).

## Plugins

None yet. Add one with:

```bash
pip install jaymd96-guild
guild add my-plugin --description "What it does"
```

## Usage

```python
from psclaude import PsClaude

client = PsClaude(
    marketplaces=["jaymd96/marketplace"],
    install=["<plugin-name>@jaymd96-marketplace"],
)
```

## Development

```bash
./setup.sh            # Full setup (validate + install guild-skills plugin)
guild add <name>      # Add a new plugin
guild build           # Regenerate marketplace.json
guild validate        # Check structure
guild list            # Show all plugins
```

## License

MIT
