# Stance: Organize

You're structuring what you've heard into entities, relationships, state
machines, and operations. Raw human input becomes a domain model.

## When to Adopt

- You have enough raw material to see patterns
- The human asks "how does this all fit together?"
- Synonyms, relationships, or lifecycle questions need resolving
- You're mapping features to spec sections (structuring)

## When to Switch Away

- The model needs more understanding to complete (→ understand)
- Contradictions surface during modeling (→ validate)
- The human wants to see written spec content (→ produce)
- The human introduces new information (→ understand)

## What to Do

1. Extract entities, relationships, and operations from feature dossiers
2. Resolve synonyms ("are 'job' and 'task' the same thing?")
3. Map state machines for stateful entities
4. Define invariants
5. Present your model to the human for confirmation
6. Write everything to `internal/PRODUCT_MODEL.md`

---

## Journey Context: During Model

Building the domain model — the conceptual backbone of the spec.

### Entities

Extract the core domain objects.

**Process:**
1. Read all feature dossiers and PRODUCT_MODEL.md
2. Extract every noun that represents a "thing" the system manages
3. Cluster synonyms (the human may have called the same thing different names)
4. Propose entity list to the human

**Conversation:**
"Based on everything we've discussed, I see these core entities: [list].
For each one: what uniquely identifies it? What are its essential properties?"

**Capture in PRODUCT_MODEL.md:**
```
### <EntityName>
- Identity: how it's uniquely identified
- Properties: essential attributes
- Lifecycle: created when? destroyed when?
- Owner: who/what creates and manages it
- Source: which feature discussions mentioned this
```

### Relationships

Map how entities connect.

**Process:**
1. For each pair of entities, ask: is there a relationship?
2. Classify: owns | references | contains | depends-on
3. Identify cardinality: 1:1, 1:N, N:M

**Conversation — use concrete scenarios:**
"When a [EntityA] is deleted, what happens to its [EntityB]s?"
"Can a [EntityB] exist without a [EntityA]?"

**Capture:**
```
### <EntityA> → <EntityB>
- Type: owns | references | contains | depends-on
- Cardinality: 1:1 | 1:N | N:M
- Lifecycle coupling: cascade-delete | orphan | prevent-delete
```

### State Machines

For stateful entities, define the lifecycle.

**Process:**
1. Does it have distinct states?
2. Map: initial state, terminal states, transitions, triggers
3. Verify: can every state be reached? Can every non-terminal be exited?

**Conversation:**
"A [Entity] starts as [state]. What causes it to move? Can it go back?"

**Capture:**
```
### <Entity> Lifecycle
States: [list]
Initial: <state>
Terminal: [states]
Transitions:
  <from> → <to>: triggered by <event>, guard: <condition>
```

### Operations

Define the actions the system supports.

**Process:**
1. From feature dossiers, extract every verb (create, update, deploy, approve)
2. Map each to: actor, target entity, preconditions, effects
3. Group by entity or feature area

**Capture:**
```
### <operation-name>
- Actor: who performs this
- Target: which entity/entities
- Preconditions: what must be true
- Effects: what changes (state transitions, side effects)
- Failure modes: what can go wrong
```

### Invariants

Rules that must always hold true.

**Process:**
1. Derive constraints from relationships and operations
2. Classify: hard (system-enforced) vs soft (policy, overridable)

**Capture:**
```
### INV-<N>: <short name>
- Rule: <formal statement>
- Type: hard | soft
- Enforcement: where/how this is checked
```

### Model Validation

Check the model before moving on:
1. Every feature area maps to at least one entity
2. Every entity has a clear identity and lifecycle
3. No orphan entities
4. State machines have no dead states
5. Operations cover all CRUD + domain-specific actions
6. Invariants are testable
7. No contradictions with feature discussions

---

## Journey Context: During Structure

Mapping all accumulated knowledge to spec sections.

**Standard Spec Sections (Symphony-style, adapt per product):**
```
1. Problem Statement
2. Goals and Non-Goals
3. System Overview (components, abstraction levels, dependencies)
4. Core Domain Model (entities, relationships, identifiers)
5. [Feature Area] Specification (behavior, state machines, interfaces, errors, config)
6. Cross-Cutting Concerns (auth, observability, config management, error philosophy)
7. Test Matrix (unit, integration, system)
8. Implementation Checklist (ordered by dependency)
```

**Process:**
1. Adapt the standard structure to this product
2. Write outline to `spec/SPEC.md` (headers only)
3. Create `internal/SPEC_MAP.md` mapping every source to a section:
   ```
   ### Section 5.1: <Feature Area>
   Sources: human/features/<name>/, internal/PRODUCT_MODEL.md
   Decisions: DEC-3, DEC-7
   Dependencies: Section 4.1 (entity def), Section 6.1 (auth)
   ```
4. Verify completeness: every feature mapped, every entity referenced, no orphans
5. Present to human for confirmation

---

## Modeling Tactics

### The Human Doesn't Think in Entities
Extract entities FROM workflow descriptions:
- "The user creates a deployment" → Entity: Deployment. Operation: create.
- "It goes through approval" → Entity: Approval. State: pending/approved/rejected.
- "Then it rolls out to staging" → Entity: Environment. Relationship: Deployment → Environment.

### Synonyms and Ambiguity
Track different words for the same thing:
- "job", "task", "run" might all mean the same entity
- Ask: "When you say 'job' and 'task', are those the same thing or different?"
- Record canonical name AND aliases

### Missing Entities
Some entities only become visible when you model relationships:
- "Who approves this?" → Entity: Approver or Role
- "Where is the config stored?" → Entity: Configuration
- "How do you know it succeeded?" → Entity: HealthCheck or StatusReport
