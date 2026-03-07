#!/usr/bin/env bash
# Validate that an codecraft project has the expected structure and config.
# Usage: validate-state.sh <project-path>

set -euo pipefail

PROJECT_DIR="${1:-.}"
ERRORS=0
WARNINGS=0

error() {
  echo "ERROR: $1"
  ERRORS=$((ERRORS + 1))
}

warn() {
  echo "WARNING: $1"
  WARNINGS=$((WARNINGS + 1))
}

# Check for project config
CONFIG="$PROJECT_DIR/.codecraft.local.md"
if [ ! -f "$CONFIG" ]; then
  warn "No .codecraft.local.md found — using defaults"
else
  # Validate key fields in YAML frontmatter
  for field in tracker test_command; do
    if ! grep -q "$field" "$CONFIG" 2>/dev/null; then
      warn "Missing field '$field' in .codecraft.local.md"
    fi
  done
fi

# Check for tracker
TRACKER=""
if [ -f "$CONFIG" ]; then
  TRACKER=$(grep "^tracker:" "$CONFIG" 2>/dev/null | sed 's/tracker: *//' | tr -d '"' || echo "")
fi
if [ -z "$TRACKER" ]; then
  TRACKER="docs/engineering/tracker.md"
fi

if [ ! -f "$PROJECT_DIR/$TRACKER" ]; then
  error "Tracker not found at $PROJECT_DIR/$TRACKER"
else
  TODO=$(grep -c "todo" "$PROJECT_DIR/$TRACKER" 2>/dev/null || echo 0)
  DONE=$(grep -c "done" "$PROJECT_DIR/$TRACKER" 2>/dev/null || echo 0)
  echo "Tracker: $DONE done, $TODO todo"
fi

# Check for lock files
LOCKS_DIR="$PROJECT_DIR/current_tasks"
if [ -d "$LOCKS_DIR" ]; then
  LOCK_COUNT=$(find "$LOCKS_DIR" -name "*.txt" -type f 2>/dev/null | wc -l | tr -d ' ')
  if [ "$LOCK_COUNT" -gt 0 ]; then
    echo "Active locks: $LOCK_COUNT"
    find "$LOCKS_DIR" -name "*.txt" -type f -exec basename {} \; 2>/dev/null
  fi
fi

# Check for stuck notes
STUCK_DIR="$PROJECT_DIR/stuck_notes"
if [ -d "$STUCK_DIR" ]; then
  STUCK_COUNT=$(find "$STUCK_DIR" -name "*.md" -type f 2>/dev/null | wc -l | tr -d ' ')
  if [ "$STUCK_COUNT" -gt 0 ]; then
    warn "$STUCK_COUNT stuck notes found"
    find "$STUCK_DIR" -name "*.md" -type f -exec basename {} \; 2>/dev/null
  fi
fi

# Check git status
if [ ! -d "$PROJECT_DIR/.git" ]; then
  warn "Git not initialized"
else
  UNCOMMITTED=$(cd "$PROJECT_DIR" && git status --porcelain 2>/dev/null | wc -l | tr -d ' ')
  if [ "$UNCOMMITTED" -gt 0 ]; then
    warn "$UNCOMMITTED uncommitted changes"
  fi
  COMMITS=$(cd "$PROJECT_DIR" && git rev-list --count HEAD 2>/dev/null || echo 0)
  echo "Git: $COMMITS commits"
fi

# Summary
echo ""
if [ "$ERRORS" -eq 0 ] && [ "$WARNINGS" -eq 0 ]; then
  echo "STATE OK: Project ready for execution."
elif [ "$ERRORS" -eq 0 ]; then
  echo "STATE OK with $WARNINGS warnings."
else
  echo "STATE ISSUES: $ERRORS errors, $WARNINGS warnings."
fi

exit $ERRORS
