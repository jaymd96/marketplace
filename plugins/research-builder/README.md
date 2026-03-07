# Research Builder

A harness for refining research ideas through extended conversation.

## What This Is

Research Builder is an operational environment for an AI agent acting as a
thought partner for a researcher. It handles the environmental challenges of
long-running intellectual work:

1. **Context loss.** The agent's memory resets between sessions. The concept
   graph, thread status, and accumulated understanding must survive in files.
2. **Non-linear exploration.** Research is a random walk. Ideas fork, merge,
   dead-end, and resurface. The tool tracks threads without forcing linearity.
3. **External knowledge.** Papers, theorems, and prior work are primary inputs
   that need tracking, linking, and reasoning about alongside the researcher's
   own ideas.
4. **Logical consistency.** Unlike product specs where contradictions are
   preferences to reconcile, research contradictions are logical errors to
   resolve or understand.

## Harness Architecture

| Component | How It Manifests |
|-----------|-----------------|
| **Context** | ENTRYPOINT.md (map) → concept graph → thread dossiers → literature links |
| **Capabilities** | Survey tools (literature search), connection mapping, logical critique, thread status |
| **Constraints** | Session protocol, logical consistency checking, self-review |
| **Maintenance** | Self-review per session, git history, concept graph gardening |

## How It Differs from Spec-Builder

| Aspect | Spec-Builder | Research-Builder |
|--------|-------------|-----------------|
| Process shape | Converging arc (intake → deliver) | Diverging graph (threads fork and merge) |
| Primary input | Human's product vision | Human's intuitions + existing literature |
| Domain model | Entity-relationship | Concept graph (extends, contradicts, analogous-to) |
| Output | One specification document | Flexible (paper, proof, thesis chapter, refined question) |
| Validation | "Could two engineers implement this?" | "Does this follow logically? Is it novel?" |
| Agent role | Structured scribe | Thought partner |

## Directory Structure

```
research-builder/
  README.md                         # You are here
  CLAUDE.md                         # Plugin instructions
  plugin.toml                       # Plugin manifest

  agents/                           # Subagents
    orient.md                       # Session briefing
    literature.md                   # Paper search and summarization
    logic-checker.md                # Argument stress-testing

  skills/                           # Invocable commands
    research-session.md             # Main entry point
    orient.md, new-thread.md, checkpoint.md, threads.md,
    connections.md, critique.md

  scripts/                          # Mechanical operations
    bootstrap-project.sh, thread-report.sh, validate-state.sh

  system/                           # The harness core
    ENTRYPOINT.md                   # Session router
    workflows/                      # 5 stance files
      survey.md, connect.md, formalize.md, critique.md, meta.md
    templates/                      # Document scaffolds
    reference/                      # Quality calibration
    evolution/                      # Self-modification records

<project>/                          # Created per research project
  state/                            # Session state, log, questions, decisions
  researcher/                       # Raw input (thesis statement, idea threads)
    thesis.md                       # Research question / thesis statement
    threads/<name>/                 # One folder per idea thread
  internal/                         # Agent's processed understanding
    CONCEPT_GRAPH.md                # Concepts, relationships, formal structure
    THREAD_MAP.md                   # How threads relate
    LITERATURE.md                   # Papers and sources tracked
  reviews/                          # Session self-reviews
  output/                           # Research artifacts (papers, proofs, etc.)
```
