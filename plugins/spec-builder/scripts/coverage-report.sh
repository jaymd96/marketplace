#!/usr/bin/env bash
# Scan feature dossiers and produce a coverage summary.
# Usage: coverage-report.sh <project-path>

set -euo pipefail

PROJECT_DIR="$1"
FEATURES_DIR="$PROJECT_DIR/human/features"

if [ ! -d "$FEATURES_DIR" ]; then
  echo "No features directory found at $FEATURES_DIR" >&2
  exit 1
fi

echo "FEATURE COVERAGE"
echo ""
printf "| %-20s | %-12s | %5s | %6s | %8s |\n" "Feature" "Status" "Notes" "Open Q" "Resolved"
printf "| %-20s | %-12s | %5s | %6s | %8s |\n" "--------------------" "------------" "-----" "------" "--------"

TOTAL=0
COMPLETE=0
PARTIAL=0
NOT_STARTED=0

for feature_dir in "$FEATURES_DIR"/*/; do
  [ -d "$feature_dir" ] || continue
  TOTAL=$((TOTAL + 1))

  feature=$(basename "$feature_dir")
  notes=0
  open_q=0
  resolved_q=0
  status="NOT_STARTED"

  if [ -f "$feature_dir/raw-notes.md" ]; then
    notes=$(wc -l < "$feature_dir/raw-notes.md" | tr -d ' ')
  fi

  if [ -f "$feature_dir/questions.md" ]; then
    open_q=$(grep -c '^\- \[ \]' "$feature_dir/questions.md" || true)
  fi

  if [ -f "$feature_dir/resolved.md" ]; then
    resolved_q=$(grep -c '^\- \[x\]\|^###' "$feature_dir/resolved.md" || true)
  fi

  if [ "$notes" -gt 0 ]; then
    status="PARTIAL"
    PARTIAL=$((PARTIAL + 1))
  else
    NOT_STARTED=$((NOT_STARTED + 1))
  fi

  # Check for completion markers
  if [ -f "$feature_dir/raw-notes.md" ] && grep -q '\[x\].*Core behavior' "$feature_dir/raw-notes.md" 2>/dev/null; then
    if [ "$open_q" -eq 0 ] && [ "$notes" -gt 20 ]; then
      status="COMPLETE"
      COMPLETE=$((COMPLETE + 1))
      PARTIAL=$((PARTIAL - 1))
    fi
  fi

  printf "| %-20s | %-12s | %5s | %6s | %8s |\n" "$feature" "$status" "$notes" "$open_q" "$resolved_q"
done

echo ""
echo "TOTAL: $TOTAL features — $COMPLETE complete, $PARTIAL partial, $NOT_STARTED not started"
