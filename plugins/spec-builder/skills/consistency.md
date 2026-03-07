---
name: consistency
description: "Check all project documents for contradictions, terminology drift, and gaps. Use when the user says 'is everything consistent', 'check for contradictions', 'find conflicts', 'cross-check the documents', or when something seems to contradict earlier input."
---

# consistency

Use the consistency-checker subagent (defined in `agents/consistency-checker.md`)
to read all project documents in an isolated context and produce a report.

The checker cross-references: product model, all feature dossiers, decisions,
spec, and consistency log. It identifies contradictions, terminology drift,
unresolved references, decision gaps, and orphan entities.

Present the report to the human. Resolve issues using the validate stance's
inconsistency protocol (present one at a time, lead with recommendation).
