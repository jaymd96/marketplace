#!/usr/bin/env bash
# Bootstrap a new spec-builder project directory.
# Usage: bootstrap-project.sh <project-path> <product-name>

set -euo pipefail

PROJECT_DIR="$1"
PRODUCT_NAME="$2"
TODAY=$(date +%Y-%m-%d)

if [ -d "$PROJECT_DIR" ]; then
  echo "Error: $PROJECT_DIR already exists" >&2
  exit 1
fi

# Create directory structure
mkdir -p "$PROJECT_DIR"/{state,human/features,internal,reviews,spec}

# State files
cat > "$PROJECT_DIR/state/PROJECT_STATE.md" << EOF
# Project State

## Identity

\`\`\`yaml
product_name: ${PRODUCT_NAME}
project_dir: $(cd "$(dirname "$PROJECT_DIR")" && pwd)/$(basename "$PROJECT_DIR")
created: ${TODAY}
spec_version: 0.0.0
\`\`\`

## Position

\`\`\`yaml
project_phase: shaping
journey_stage: intake
last_stance: understand
\`\`\`

## Pending Actions

1. Run intake — capture initial product vision

## Feature Coverage

| Feature | Status | Dossier Path | Spec Section |
|---------|--------|-------------|-------------|

## Session Count

\`\`\`yaml
total_sessions: 0
last_session: ${TODAY}
\`\`\`

## Resumption Prompt

New project "${PRODUCT_NAME}" bootstrapped. No vision captured yet. Ready for intake.
EOF

cat > "$PROJECT_DIR/state/SESSION_LOG.md" << EOF
# Session Log

## Session 0 — ${TODAY}
**Resumption prompt:** New project "${PRODUCT_NAME}" bootstrapped. Ready for intake.
**What happened:** Project initialized.
**Next:** Capture initial product vision.
EOF

cat > "$PROJECT_DIR/state/OPEN_QUESTIONS.md" << 'EOF'
# Open Questions

<!-- Questions that need answers. Add context and source. Mark answered with [x]. -->
EOF

cat > "$PROJECT_DIR/state/DECISIONS.md" << 'EOF'
# Decisions

<!-- Design decisions with rationale. Format: DEC-N: Title -->
EOF

# Human input files
cat > "$PROJECT_DIR/human/vision.md" << 'EOF'
# Product Vision

<!-- Raw notes from intake conversations. Organized by section. -->
EOF

# Internal files
for file in PRODUCT_MODEL CONSISTENCY_LOG BRAINSTORM GAPS RISK_REGISTER; do
  cat > "$PROJECT_DIR/internal/${file}.md" << EOF
# ${file//_/ }

<!-- Agent's internal notes. Not shown to the human directly. -->
EOF
done

# Spec skeleton
cat > "$PROJECT_DIR/spec/SPEC.md" << EOF
# ${PRODUCT_NAME} Specification

Status: Draft v0.0.0
Last updated: ${TODAY}

---

<!-- Sections will be added as the spec takes shape. -->
EOF

# Git setup
cat > "$PROJECT_DIR/.gitignore" << 'EOF'
.DS_Store
*.swp
*~
EOF

cd "$PROJECT_DIR"
git init -q
git add -A
git commit -q -m "session 0: bootstrap project '${PRODUCT_NAME}'

Phase: shaping
Progress: project directory created, all state files initialized
Next: intake — capture initial product vision"

echo "Project '${PRODUCT_NAME}' created at ${PROJECT_DIR}"
echo "Git initialized with initial commit."
