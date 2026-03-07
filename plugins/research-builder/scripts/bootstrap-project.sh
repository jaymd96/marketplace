#!/usr/bin/env bash
# Bootstrap a new research-builder project directory.
# Usage: bootstrap-project.sh <project-path> <research-area>

set -euo pipefail

PROJECT_DIR="$1"
RESEARCH_AREA="$2"
TODAY=$(date +%Y-%m-%d)

if [ -d "$PROJECT_DIR" ]; then
  echo "Error: $PROJECT_DIR already exists" >&2
  exit 1
fi

mkdir -p "$PROJECT_DIR"/{state,researcher/threads,internal,reviews,output}

cat > "$PROJECT_DIR/state/PROJECT_STATE.md" << EOF
# Project State

## Identity

\`\`\`yaml
product_name: ${RESEARCH_AREA}
project_dir: $(cd "$(dirname "$PROJECT_DIR")" && pwd)/$(basename "$PROJECT_DIR")
created: ${TODAY}
\`\`\`

## Position

\`\`\`yaml
research_phase: exploring
last_stance: survey
\`\`\`

## Active Threads

| Thread | Status | Last Touched | Key Question |
|--------|--------|-------------|-------------|

## Pending Actions

1. Capture initial research question and existing intuitions

## Session Count

\`\`\`yaml
total_sessions: 0
last_session: ${TODAY}
\`\`\`

## Resumption Prompt

New research project "${RESEARCH_AREA}" created. No threads yet. Ready to explore.
EOF

cat > "$PROJECT_DIR/state/SESSION_LOG.md" << EOF
# Session Log

## Session 0 — ${TODAY}
**Resumption prompt:** New research project "${RESEARCH_AREA}". Ready to explore.
**What happened:** Project initialized.
**Next:** Capture research question, existing intuitions, known prior work.
EOF

for file in OPEN_QUESTIONS DECISIONS; do
  cat > "$PROJECT_DIR/state/${file}.md" << EOF
# ${file//_/ }
EOF
done

cat > "$PROJECT_DIR/researcher/thesis.md" << EOF
# Research Question

<!-- What is the core question or thesis this research is exploring? -->
EOF

for file in CONCEPT_GRAPH THREAD_MAP CONSISTENCY_LOG BRAINSTORM GAPS LITERATURE; do
  cat > "$PROJECT_DIR/internal/${file}.md" << EOF
# ${file//_/ }
EOF
done

cat > "$PROJECT_DIR/.gitignore" << 'EOF'
.DS_Store
*.swp
*~
EOF

cd "$PROJECT_DIR"
git init -q
git add -A
git commit -q -m "session 0: bootstrap research project '${RESEARCH_AREA}'

Phase: exploring
Progress: project directory created
Next: capture research question and initial intuitions"

echo "Research project '${RESEARCH_AREA}' created at ${PROJECT_DIR}"
