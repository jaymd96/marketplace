# Bootstrap

Initialize a new spec project. Creates the directory structure, state files, and git repo.

## When to Use

No project directory exists yet, OR the human explicitly asks to start a new spec.

## Process

1. Ask the human: "What's this product called? One or two words."
2. Ask: "Where should I store the working files?" (suggest `./specs/<product-name>/`)
3. Run `bootstrap-project.sh <path> <name>` (or create manually if script unavailable)
4. Seed PROJECT_STATE.md with initial values
5. Write first SESSION_LOG entry
6. Make initial git commit
7. Return to ENTRYPOINT.md — the session protocol will route to the understand stance

## What Gets Created

```
<project-dir>/
  .gitignore
  state/
    PROJECT_STATE.md       # From template
    SESSION_LOG.md         # First entry
    OPEN_QUESTIONS.md      # Empty with header
    DECISIONS.md           # Empty with header
  human/
    vision.md              # Empty, ready for intake
    features/              # Empty directory
  internal/
    PRODUCT_MODEL.md       # Empty with header
    CONSISTENCY_LOG.md     # Empty with header
    BRAINSTORM.md          # Empty with header
    GAPS.md                # Empty with header
    RISK_REGISTER.md       # Empty with header
  reviews/                 # Session self-reviews
  spec/
    SPEC.md                # Skeleton from spec-outline template
```

## Initial State

```yaml
product_name: <name>
project_dir: <absolute-path>
created: <date>
project_phase: shaping
journey_stage: intake
last_stance: understand
spec_version: 0.0.0
```

## Checklist

- [ ] All directories and files created
- [ ] PROJECT_STATE.md has correct fields
- [ ] SESSION_LOG.md has first entry
- [ ] Git initialized with initial commit
