# Mode: Planning

You're designing the approach. Writing a plan, not code.

## When to Enter
- After analysis, when you understand the task well enough to decompose it
- After a RETHINK, when you need to redesign the approach

## Entry Guard
You've completed analysis mode. You can answer the four exit-guard questions.

## What to Do

### Decompose into Units
List every change needed. Each unit is ONE logical change:
- Adding a model field
- Creating a new class
- Modifying a route handler
- Adding a test
- Updating a migration

### Order by Dependency
Dependencies flow downward. Build foundations first:
1. Models / data structures
2. Business logic / services
3. API routes / CLI commands
4. Tests
5. Migrations / configuration

Within each level, order by: simplest first, or prerequisite first.

### Define Verification per Unit
For each unit, specify how to verify it independently:

| Change type | Verification |
|-------------|-------------|
| New module | `python3 -c "from module import NewClass"` |
| New function | Quick unit test or import check |
| Modified code | Run the specific test file: `pytest tests/module/test_file.py -x -q` |
| New test | Run just that test: `pytest tests/path.py::TestClass -x -q` |
| Config change | Verify the app starts or config loads |

### Identify Risks
For each unit, note:
- What could go wrong?
- Are there circular dependencies?
- Does this change a public API?
- Could this break existing tests?

### Write the Plan
Output a numbered list:

```
CHANGE LIST -- <task ID>

1. <file> -- <what changes>
   Verify: <command>
   Risk: <note>

2. <file> -- <what changes>
   Verify: <command>
   Depends on: #1

...
```

## Exit Guard
You have a numbered, ordered change list where:
- Each unit has a specific verification command
- Dependencies between units are noted
- No unit is "do everything at once"

## Common Traps
- **Units too large**: "Implement the feature" is not a unit. "Add the X field to Y model" is.
- **No verification strategy**: If you can't say how to verify it, the unit isn't well-defined.
- **Wrong ordering**: If unit 3 requires unit 5, reorder.
- **Design-free building**: Jumping from analysis to code. The plan is what prevents "let me just start coding and see what happens."
