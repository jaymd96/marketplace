# consistency

Check all project documents for contradictions and inconsistencies.

## Trigger

- "Is everything consistent?"
- "Check for contradictions"
- "Run a consistency check"
- You suspect something contradicts earlier input

## What to do

Use the consistency-checker subagent (defined in `agents/consistency-checker.md`)
to read all project documents in an isolated context and produce a report.

The checker cross-references: product model, all feature dossiers, decisions,
spec, and consistency log. It looks for:

- **Contradictions** — direct conflicts between documents
- **Terminology drift** — same concept, different names
- **Unresolved references** — mentions of undefined concepts
- **Decision gaps** — decisions not reflected in the spec
- **Orphan entities** — entities in the model with no feature reference

Present the report to the human. Resolve issues using the validate stance's
inconsistency protocol (present one at a time, lead with recommendation).
