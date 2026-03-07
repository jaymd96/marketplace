---
name: audit
description: "Audit the specification against quality rubric using parallel auditor agents. Scores structural completeness, consistency, testability, and delivery readiness. Use when assessing 'is the spec ready', 'audit the spec', 'quality gate', or 'how complete is the specification'."
---

# audit

Evaluate the specification against the quality rubric using **3 parallel
spec-auditor agents**, each examining a different rubric group. Produces a
scored readiness report.

## Steps

1. **Identify the project.** Find the spec project directory (containing
   `state/PROJECT_STATE.md`). Read `spec/SPEC.md` to confirm it exists.

2. **Launch 3 parallel spec-auditor agents** (`spec-builder:spec-auditor`):

   - **Auditor 1 — Group A (Structure & Completeness):** Scope and vision
     clarity, feature coverage, domain model completeness. "Audit this
     spec against Group A rubric: structure and completeness."

   - **Auditor 2 — Group B (Consistency & Clarity):** Internal consistency,
     implementability, decision traceability. "Audit this spec against
     Group B rubric: consistency and clarity."

   - **Auditor 3 — Group C (Testability & Delivery):** Testability of
     requirements, organization, delivery readiness. "Audit this spec
     against Group C rubric: testability and delivery readiness."

3. **Synthesize findings.** After all agents return, combine into a unified
   readiness report:

```
SPEC READINESS REPORT
=====================
Product: <name>
Spec version: <version>
Date: <date>

SCORECARD
  Structure & Completeness
    Scope & vision:        PASS | PARTIAL | FAIL  (<score>/100)
    Feature coverage:      PASS | PARTIAL | FAIL  (<score>/100)
    Domain model:          PASS | PARTIAL | FAIL  (<score>/100)

  Consistency & Clarity
    Internal consistency:  PASS | PARTIAL | FAIL  (<score>/100)
    Clarity:               PASS | PARTIAL | FAIL  (<score>/100)
    Decision traceability: PASS | PARTIAL | FAIL  (<score>/100)

  Testability & Delivery
    Testability:           PASS | PARTIAL | FAIL  (<score>/100)
    Organization:          PASS | PARTIAL | FAIL  (<score>/100)
    Delivery readiness:    PASS | PARTIAL | FAIL  (<score>/100)

  OVERALL: <average>/100

CRITICAL ISSUES (must resolve before implementation)
  - [section] <issue>

TOP 5 IMPROVEMENTS (highest impact)
  1. <what to fix and why>
  2. ...

VERDICT: READY FOR IMPLEMENTATION | NEEDS WORK ON: <list>
```

4. **Present to the user.** Group by severity:
   - Critical issues blocking implementation
   - Important issues that increase implementation risk
   - Areas that are well-covered (reinforcement)

5. **Offer next steps:**
   - "Want me to address the critical issues now?"
   - "Want a deeper look at any specific dimension?"
   - "Ready to move to implementation? Here's the handoff checklist."

## Relationship to /review and /consistency

| Skill | What it checks | When to use |
|-------|---------------|-------------|
| `/review` | 5-dimension quality review (completeness, consistency, clarity, testability, org) | Quick quality check during conversation |
| `/consistency` | Cross-document contradictions, terminology drift, gaps | When you suspect inconsistencies |
| `/audit` | Full rubric-based readiness assessment (9 criteria, 3 groups) | Formal quality gate before delivery |

`/audit` is the most comprehensive — use it when deciding if the spec is ready
for implementation. `/review` and `/consistency` are lighter-weight checks for
use during the conversation.
