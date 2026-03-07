# Mode: Delivery

You're packaging and shipping. Commit, push, update tracker.

## When to Enter
- All three validation passes succeeded

## Entry Guard
Verification report shows ALL PASS across correctness, compliance, and quality.

## What to Do

### 1. Stage Specific Files
```bash
git add <specific files>
```

NEVER `git add -A` or `git add .`. Stage only the files you changed.
Review the staging: `git diff --cached --stat`

### 2. Commit
Write a descriptive commit message:
```
<type>: <short description>

<body -- what changed and why>

Co-Authored-By: Claude <noreply@anthropic.com>
```

Types: feat, fix, refactor, test, docs, chore

Reference the task ID if applicable:
```
feat(auth): add MFA enrollment endpoint

Implements the MFA enrollment flow from spec W3.
- POST /auth/mfa/enroll returns QR code + secret
- TOTP verification via POST /auth/mfa/verify
- Backup codes generated on successful enrollment

PR-W3

Co-Authored-By: Claude <noreply@anthropic.com>
```

### 3. Update Tracker
Change the task status to `done` in the tracker file.
Commit the tracker update separately.

### 4. Sync (if multi-agent)
```bash
git pull origin main --no-edit
# Resolve any merge conflicts
git push origin main
```

If pull introduces conflicts:
- Read the conflicting files
- Understand what the other agent changed
- Merge intelligently (don't just accept theirs or ours)
- Test after merge resolution

### 5. Unlock
Remove lock file if one was created:
```bash
rm current_tasks/<TASK_ID>.txt
git add current_tasks/<TASK_ID>.txt
git commit -m "unlock: <TASK_ID>"
```

### 6. Signal Completion
```
AGENT_DONE: <TASK_ID> -- <outcome description>
```

This marker is parsed by the harness for session outcome detection.

## After Delivery
Do NOT start another task. One task per execution cycle.
The harness will restart you for the next task.

## Common Traps
- **`git add -A`**: Stages unrelated files, editor temp files, etc.
- **Missing tracker update**: Other agents/sessions won't know this task is done.
- **Skipping sync**: In multi-agent setups, not pulling before pushing causes conflicts for others.
- **Starting another task**: Resist the urge. Clean exit, let the harness manage task selection.
