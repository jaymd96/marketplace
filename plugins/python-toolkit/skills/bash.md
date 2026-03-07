---
name: bash
description: "Production bash scripting patterns. Use when writing shell scripts, deployment automation, or when the user asks about bash best practices, shell pipelines, trap patterns, or 'when should I use bash vs Python'."
---

# bash

Production shell scripting for Python developers. The pipeline IS the program.

## Core Principle: Gain Merit by Not Coding

Bash provides scaffolding. Transformation belongs to specialized tools.
Don't write algorithms in bash. Pipe data through tools that do one thing well.

## When to Use Bash vs Python

**Use bash when:**
- Orchestrating other programs (build, deploy, CI)
- Simple file/directory operations
- Piping between existing tools (jq, grep, awk, curl)
- Script is <100 lines with no complex logic

**Use Python when:**
- Script >200 lines
- Need data structures beyond arrays
- Need error handling with recovery
- Need unit tests
- Need complex string manipulation
- Need to maintain state across operations

## Infrastructure Tiers

### Tier 1: Quick Script
```bash
#!/usr/bin/env bash
# Quick, disposable, for your own use
echo "doing the thing"
```

### Tier 2: Team Script
```bash
#!/usr/bin/env bash
set -euo pipefail

# Shared with teammates, needs to be reliable
main() {
    echo "doing the thing reliably"
}

main "$@"
```

### Tier 3: Production Script
```bash
#!/usr/bin/env bash
set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly LOG_FILE="/var/log/$(basename "$0" .sh).log"

cleanup() {
    local exit_code=$?
    # cleanup logic here
    exit "$exit_code"
}
trap cleanup EXIT

log() { echo "[$(date -Iseconds)] $*" | tee -a "$LOG_FILE"; }
die() { log "FATAL: $*" >&2; exit 1; }

main() {
    log "starting"
    # production logic with logging, error handling
    log "done"
}

main "$@"
```

## Tool Selection

| Data Format | Tool | Example |
|-------------|------|---------|
| JSON | jq | `curl api \| jq '.data[] \| .name'` |
| CSV | mlr (Miller) | `mlr --csv filter '$age > 30' data.csv` |
| Multi-pass / joins | sqlite3 | `sqlite3 :memory: '.import data.csv t' 'SELECT ...'` |
| Line-oriented text | grep/sed/awk | `grep -c ERROR log.txt` |
| YAML | yq | `yq '.services[].name' docker-compose.yml` |

## Critical Patterns

**Always quote variables:** `"$var"` not `$var`
**Use `[[ ]]` not `[ ]`:** safer, supports `&&`, `||`, regex
**Use `$(command)` not backticks:** nestable, readable
**Use `readonly` for constants:** `readonly DB_HOST="localhost"`
**Use `local` in functions:** `local result; result=$(compute)`

## Trap Patterns

```bash
# Cleanup on exit (always runs)
trap 'rm -f "$tmpfile"' EXIT

# Handle signals gracefully
trap 'echo "interrupted"; exit 130' INT TERM

# Lock file (prevent concurrent runs)
readonly LOCK="/var/run/$(basename "$0").lock"
exec 9>"$LOCK"
flock -n 9 || die "already running"
```

## Pipeline Composition

```bash
# Linear pipeline
cat data.json | jq '.items[]' | grep -v null | sort -u > output.txt

# Parallel execution
command1 &
command2 &
wait  # wait for all background jobs

# Process substitution (compare two commands)
diff <(sort file1) <(sort file2)
```

## Red Flags (Time to Switch to Python)

- Script exceeds 200 lines
- Need associative arrays or complex data structures
- Need to parse command output with regex
- Need retry logic with backoff
- Need unit tests for the script logic
- Multiple levels of string escaping
