# Stance: Produce

You're writing spec content. Turning organized understanding into precise,
implementable specification prose.

## When to Adopt

- The human asks to see written output
- A section has enough backing material to draft
- You're working solo to advance the spec between conversations
- The project is in the building phase and needs spec content

## When to Switch Away

- The human has feedback on what you wrote (→ validate or understand)
- You discover a gap while writing (→ understand)
- You find an inconsistency (→ validate)
- The human introduces new information (→ understand)

## What to Do

1. Read source material for the section (from SPEC_MAP.md)
2. Read relevant decisions and consistency resolutions
3. Draft the section following quality standards below
4. Cross-reference against the domain model
5. Present to the human for review
6. Update SPEC_MAP.md and spec_version

---

## Journey Context: During Draft

Writing the specification sections.

### Prioritize Sections

1. Foundational first (domain model, system overview)
2. Feature sections in dependency order
3. Cross-cutting concerns after features
4. Test matrix and implementation checklist last

### Per-Section Quality Standard

Each section must include (where applicable):

**Behavior Specification:**
- Observable behavior, not implementation details
- "The system SHALL..." for requirements
- "The system SHOULD..." for recommendations
- "The system MAY..." for optional behavior

**Entity Definitions:**
```
#### <Entity Name>

<Description>

Fields:
- `<field>` (<type>) — <purpose>
  - <constraints>
```

**State Machines:**
```
States: [list]
Initial: <state>
Terminal: [states]

Transitions:
  <from> → <to>
    Trigger: <what causes this>
    Guard: <what must be true>
    Effect: <what changes>
```

**Protocols / Interfaces:**
```
#### <Operation Name>

Input: <what it receives>
Output: <what it returns>
Preconditions: <what must be true>
Postconditions: <what is guaranteed after>
Error conditions: <what can go wrong>
```

**Error Handling:**
- What errors can occur
- How each is reported (error type, message pattern)
- Recovery behavior (retry, fail, escalate)

**Configuration:**
- What's configurable
- Default values
- Validation rules

### Cross-Reference After Each Section

1. Does this section reference entities defined in the domain model?
2. Are state transitions consistent with the definitions?
3. Do operation preconditions match entity invariants?
4. Are error types consistent with the error handling philosophy?
5. Fix trivially obvious issues inline, log non-trivial ones

### Common Issues During Drafting

- **New requirements discovered:** capture in feature dossier, add to GAPS.md,
  mark as `[TBD: needs exploration]` in the section
- **Ambiguity:** ask the human directly
- **Section too large:** split into subsections, update outline
- **Contradictions resurface:** log to CONSISTENCY_LOG.md

---

## Journey Context: During Deliver

Polish and finalize the spec.

### Final Polish

1. Read complete spec end-to-end
2. Fix: TOC matches sections, numbering sequential, cross-references valid,
   formatting consistent, no orphan markers, version and date current
3. Ensure self-contained: a reader doesn't need the feature dossiers

### Implementation Checklist

Derive from spec sections:
```
## Implementation Checklist

### Phase 1: Foundation
- [ ] 1.1 Implement <Entity> model (Section 4.1)
      Deps: none | Complexity: small
- [ ] 1.2 Implement <Entity> persistence (Section 4.1)
      Deps: 1.1 | Complexity: medium

### Phase 2: Core Features
- [ ] 2.1 Implement <Feature A> (Section 5.1)
      Deps: 1.1, 1.2 | Complexity: large
```

### Sign-Off

Present summary:
"The specification is complete: [N] sections, [N] entities, [N] state machines,
[N] test requirements, [N] implementation items. Ready to approve?"

If human approves, mark PROJECT_STATE.md as delivered, tag `spec-v1.0`.

---

## Writing Guidelines

### Voice and Precision
- Present tense: "The system creates..." not "will create"
- Specific: "responds within 200ms at p99" not "responds quickly"
- Behavior, not implementation: describe WHAT not HOW
- RFC 2119: MUST, SHOULD, MAY for requirement levels

### Structure Within Sections
- Lead with one-paragraph summary
- Then details in subsections
- End with error handling and configuration
- Cross-reference by section number: "see Section 4.1"

### Handling Uncertainty
- Decided → state as requirement
- Needs human input → `[DECISION NEEDED: question]`
- Intentionally deferred → `[OUT OF SCOPE: reason]`
- Never silently skip — make every gap visible

### Level of Detail
- Domain model: very precise (field names, types, constraints)
- Behavior spec: precise (inputs, outputs, state changes)
- System overview: moderate (components, interactions)
- Non-goals: brief (clear exclusions)

### Compile the Complete Spec

When all sections are drafted:
1. Add table of contents
2. Add version header and changelog
3. Full read-through for terminology consistency, formatting, dangling markers
4. Increment spec_version
