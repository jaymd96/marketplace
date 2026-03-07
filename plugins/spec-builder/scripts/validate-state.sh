#!/usr/bin/env bash
# Validate that a spec project's state files are structurally sound.
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

# Required directories
check -d "$PROJECT_DIR/state"
check -d "$PROJECT_DIR/human"
check -d "$PROJECT_DIR/human/features"
check -d "$PROJECT_DIR/internal"
check -d "$PROJECT_DIR/reviews"
check -d "$PROJECT_DIR/spec"

# Required files
check -f "$PROJECT_DIR/state/PROJECT_STATE.md"
check -f "$PROJECT_DIR/state/SESSION_LOG.md"
check -f "$PROJECT_DIR/state/OPEN_QUESTIONS.md"
check -f "$PROJECT_DIR/state/DECISIONS.md"
check -f "$PROJECT_DIR/human/vision.md"
check -f "$PROJECT_DIR/internal/PRODUCT_MODEL.md"
check -f "$PROJECT_DIR/internal/CONSISTENCY_LOG.md"
check -f "$PROJECT_DIR/internal/GAPS.md"
check -f "$PROJECT_DIR/spec/SPEC.md"

# Check PROJECT_STATE has key fields
if [ -f "$PROJECT_DIR/state/PROJECT_STATE.md" ]; then
  for field in product_name project_phase journey_stage; do
    if ! grep -q "$field" "$PROJECT_DIR/state/PROJECT_STATE.md" 2>/dev/null; then
      echo "MISSING FIELD: $field in PROJECT_STATE.md"
      ERRORS=$((ERRORS + 1))
    fi
  done

  if ! grep -q "Resumption Prompt" "$PROJECT_DIR/state/PROJECT_STATE.md" 2>/dev/null; then
    echo "WARNING: No Resumption Prompt section in PROJECT_STATE.md"
  fi
fi

# Check git
if [ ! -d "$PROJECT_DIR/.git" ]; then
  echo "WARNING: Git not initialized in $PROJECT_DIR"
else
  COMMITS=$(cd "$PROJECT_DIR" && git rev-list --count HEAD 2>/dev/null || echo 0)
  echo "Git: $COMMITS commits"
fi

# Summary
if [ "$ERRORS" -eq 0 ]; then
  echo "STATE OK: All required files and fields present."
else
  echo "STATE ISSUES: $ERRORS problems found."
fi

exit $ERRORS
