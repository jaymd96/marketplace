---
name: consistency
description: "Check project documents for contradictions using parallel consistency-checker agents. Use when the user says 'is everything consistent', 'check for contradictions', 'find conflicts', 'cross-check the documents', or when something seems to contradict earlier input."
---

# consistency

Launch **2-3 parallel consistency-checker agents** (`spec-builder:consistency-checker`),
each scanning different document pairs:

- **Checker 1 — Spec vs Model:** Cross-reference `spec/SPEC.md` against
  `internal/PRODUCT_MODEL.md`. Check terminology, state machines, entity
  definitions, cardinality.
- **Checker 2 — Cross-feature:** Compare all feature dossiers against each
  other. Find contradictions between features, terminology drift, conflicting
  assumptions.
- **Checker 3 — Decisions vs Docs:** Compare `state/DECISIONS.md` against
  spec and product model. Find decision gaps, orphan entities, unresolved
  references.

All checkers use **>=80% confidence threshold** — only high-confidence
issues are surfaced.

After all agents return, **synthesize findings** into a consolidated report.
Deduplicate issues found by multiple checkers (same issue from different
angles = one finding).

Present the report to the user. Resolve issues using the validate stance's
inconsistency protocol (present one at a time, lead with recommendation).
