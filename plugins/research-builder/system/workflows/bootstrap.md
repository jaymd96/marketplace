# Bootstrap

Initialize a new research project.

## Process

1. Ask: "What's your research area or question? A phrase or sentence."
2. Ask: "Where should I store the working files?" (suggest `./research/<name>/`)
3. Create the project directory structure
4. Seed PROJECT_STATE.md
5. Git init and commit
6. Return to ENTRYPOINT.md

## What Gets Created

```
<project>/
  .gitignore
  state/
    PROJECT_STATE.md
    SESSION_LOG.md
    OPEN_QUESTIONS.md
    DECISIONS.md
  researcher/
    thesis.md                    # Research question / thesis statement
    threads/                     # Idea threads (created as they emerge)
  internal/
    CONCEPT_GRAPH.md             # Concepts and relationships
    THREAD_MAP.md                # How threads relate
    CONSISTENCY_LOG.md           # Logical contradictions
    BRAINSTORM.md                # Agent's own ideas
    GAPS.md                      # Known unknowns
    LITERATURE.md                # Papers and sources
  reviews/
  output/                        # Research artifacts
```

## Initial State

```yaml
product_name: <research area>
project_dir: <path>
created: <date>
research_phase: exploring
active_threads: []
last_stance: survey
```
