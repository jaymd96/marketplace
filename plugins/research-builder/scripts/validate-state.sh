#!/usr/bin/env bash
# Validate research project state files.
# Usage: validate-state.sh <project-path>

set -euo pipefail

PROJECT_DIR="$1"
ERRORS=0

check() {
  if [ ! "$1" "$2" ]; then
    echo "MISSING: $2"
    ERRORS=$((ERRORS + 1))
  fi
}

check -d "$PROJECT_DIR/state"
check -d "$PROJECT_DIR/researcher"
check -d "$PROJECT_DIR/researcher/threads"
check -d "$PROJECT_DIR/internal"
check -d "$PROJECT_DIR/reviews"
check -d "$PROJECT_DIR/output"

check -f "$PROJECT_DIR/state/PROJECT_STATE.md"
check -f "$PROJECT_DIR/state/SESSION_LOG.md"
check -f "$PROJECT_DIR/researcher/thesis.md"
check -f "$PROJECT_DIR/internal/CONCEPT_GRAPH.md"
check -f "$PROJECT_DIR/internal/THREAD_MAP.md"
check -f "$PROJECT_DIR/internal/LITERATURE.md"
check -f "$PROJECT_DIR/internal/CONSISTENCY_LOG.md"

if [ -f "$PROJECT_DIR/state/PROJECT_STATE.md" ]; then
  for field in product_name research_phase last_stance; do
    if ! grep -q "$field" "$PROJECT_DIR/state/PROJECT_STATE.md" 2>/dev/null; then
      echo "MISSING FIELD: $field in PROJECT_STATE.md"
      ERRORS=$((ERRORS + 1))
    fi
  done
fi

if [ ! -d "$PROJECT_DIR/.git" ]; then
  echo "WARNING: Git not initialized"
else
  COMMITS=$(cd "$PROJECT_DIR" && git rev-list --count HEAD 2>/dev/null || echo 0)
  echo "Git: $COMMITS commits"
fi

if [ "$ERRORS" -eq 0 ]; then
  echo "STATE OK"
else
  echo "STATE ISSUES: $ERRORS problems found"
fi
exit $ERRORS
