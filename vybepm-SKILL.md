---
name: vybepm
description: "Review completed tasks, run two-stage quality gate, deploy if approved. Works only on the current project folder. Use when Angel says 'review tasks', 'check reviews', 'vybepm review', 'deploy', or when Code is in a project folder and needs to process tasks in review status."
---

# VybePM — Task Review & Deploy

Single-project reviewer that replaces the old scheduled task. Runs only when invoked, only on the folder where Code started. No polling, no wasted tokens.

## Trigger

Code runs this skill from inside a project folder (e.g., `~/1000Problems/ytcombinator`).

## What It Does

1. Detects which project you're in from the folder name
2. Pulls tasks in `review` status from VybePM API for that project
3. Runs a two-stage quality gate on each task
4. Approved tasks → status `done` + deploy (if Tier A)
5. Rejected tasks → status `in_progress` with rejection reason in notes

## Setup

```bash
source ~/1000Problems/secrets.env
```

Requires: `VYBEPM_API_KEY`, `VERCEL_TOKEN` (for deploys), `GITHUB_PAT` (for push if needed).

VybePM base URL: `https://vybepm-v2.vercel.app`

## Detect Current Project

Resolve the project slug from the current working directory:

```bash
basename "$(pwd)"
```

Map folder name to VybePM slug:

| Folder | Slug | Tier |
|--------|------|------|
| ytcombinator | ytcombinator | A |
| VybePM-v2 | VybePM | A |
| GitMCP | GitMCP | A |
| 1000Problems | 1000Problems | A |
| Vybe | Vybe | B |
| AnimationStudio | AnimationStudio | B |
| KitchenInventory | KitchenInventory | B |
| RubberJoints-iOS | RubberJoints-iOS | B |
| Animation | Animation | C |
| Skills | Skills | C |

If the folder doesn't match any known project, abort:
```
✗ Unknown project folder. Run this skill from a known 1000Problems project directory.
```

## Pull Tasks in Review

```bash
curl -s "https://vybepm-v2.vercel.app/api/projects/${SLUG}/tasks?status=review" \
  -H "X-API-Key: ${VYBEPM_API_KEY}"
```

If no tasks in review:
```
✓ No tasks in review for ${SLUG}. Nothing to do.
```
Exit cleanly.

## Two-Stage Review

For each task in review status, run both stages. A task must pass both to be approved.

### Stage 1: Spec Compliance Gate

Parse the task notes looking for the structured Completion Evidence format.

**Check 1 — Evidence exists:**
Notes must contain `## Completion Evidence`. If missing:
```
REJECT: No structured completion evidence found. Notes are freeform or empty.
```

**Check 2 — Scope check present:**
Must contain `### Scope Check` with `Files modified:` and `Files outside TASK scope:`.
If "Files outside TASK scope" lists files without justification → REJECT.

**Check 3 — Build output (Tier A only):**
Must contain `### Build` with actual build output (not just "passed" or "done").
Look for `✓ Compiled successfully` or similar Next.js/Node build success markers.
If build section says "N/A" on a Tier A project → REJECT.

**Check 4 — Acceptance criteria:**
Must contain `### Acceptance Criteria` with at least one `[x]` item.
Each checked item must have `EVIDENCE:` with a specific reference (file:line, terminal output).
If any criterion is `[ ]` (unchecked) without `BLOCKED:` explanation → REJECT.

**Check 5 — Self-review:**
Must contain `### Self-Review` with three answers.
If any answer is "Yes" without justification → REJECT.

### Stage 2: Sanity Check

Only runs if Stage 1 passes. This stage reads the actual code changes.

**Check 1 — No secrets leaked:**
```bash
git diff HEAD~1 --unified=0 | grep -iE "(api_key|secret|password|token|private_key)" || true
```
If any match looks like an actual secret value (not a variable name or env reference) → REJECT.

**Check 2 — No type errors (Tier A):**
```bash
npm run build 2>&1 | tail -20
```
If build fails → REJECT with the error output.

**Check 3 — Scope creep:**
```bash
git diff HEAD~1 --name-only
```
Compare modified files against what the task description/title implies.
If files were modified that clearly have nothing to do with the task → REJECT.

**Check 4 — No TODO/FIXME/HACK left behind:**
```bash
git diff HEAD~1 | grep -E "^\+" | grep -iE "(TODO|FIXME|HACK|XXX)" || true
```
If new TODOs were introduced → flag as warning (not auto-reject, but note it).

**Check 5 — No console.log/print debugging left:**
```bash
git diff HEAD~1 | grep -E "^\+" | grep -E "(console\.log|print\(|debugger)" || true
```
If debugging statements found → REJECT.

## Decision

### APPROVE — both stages pass

```bash
# Move to done
curl -s -X PATCH "https://vybepm-v2.vercel.app/api/tasks/${TASK_ID}" \
  -H "X-API-Key: ${VYBEPM_API_KEY}" \
  -H "Content-Type: application/json" \
  -d '{"status": "done", "notes": "APPROVED by vybepm reviewer.\n\nStage 1: ✓ Evidence complete\nStage 2: ✓ Code clean\n\nOriginal notes preserved below.\n---\n'"${ORIGINAL_NOTES}"'"}'
```

Print:
```
✓ Task #${ID} APPROVED — ${TITLE}
```

### REJECT — any check fails

```bash
# Move back to in_progress
curl -s -X PATCH "https://vybepm-v2.vercel.app/api/tasks/${TASK_ID}" \
  -H "X-API-Key: ${VYBEPM_API_KEY}" \
  -H "Content-Type: application/json" \
  -d '{"status": "in_progress", "notes": "REJECTED by vybepm reviewer.\n\nFailed: ${STAGE} — ${CHECK}\nReason: ${REASON}\n\nOriginal notes preserved below.\n---\n'"${ORIGINAL_NOTES}"'"}'
```

Print:
```
✗ Task #${ID} REJECTED — ${TITLE}
  Failed: ${STAGE} — ${CHECK}
  Reason: ${REASON}
```

## Deploy (Tier A approved tasks only)

After approving a Tier A task, deploy:

```bash
# Commit if there are uncommitted changes (Angel may have already committed)
git add -A && git commit -m "task #${TASK_ID}: ${TASK_TITLE}" --author="Angel <angelsbadillos@gmail.com>" || true

# Push
git push origin main

# Vercel auto-deploys from GitHub push. Verify:
echo "Deployed. Vercel will pick up the push automatically."
```

For Tier B and C projects, skip deploy — just approve the task.

## Rationalization Prevention

| If you're thinking... | Stop. The reality is: |
|-----------------------|-----------------------|
| "The evidence is close enough" | Incomplete evidence = reject. No partial credit. |
| "I can infer the build passed" | If it's not in the notes, it didn't happen. Reject. |
| "This is a small change, skip stage 2" | Every task gets both stages. No exceptions. |
| "The TODO is fine, they'll clean it up" | New TODOs in a completed task = incomplete work. Reject. |
| "I'll approve and fix it myself" | You're a reviewer, not a fixer. Reject and let the author fix it. |

## Summary Output

After processing all review tasks:

```
╔══════════════════════════════════════╗
║  VybePM Review — ${SLUG}            ║
╠══════════════════════════════════════╣
║  Reviewed:  ${TOTAL}                ║
║  Approved:  ${APPROVED}             ║
║  Rejected:  ${REJECTED}             ║
║  Deployed:  ${DEPLOYED}             ║
╚══════════════════════════════════════╝
```

## Do NOT

- Do NOT review tasks from other projects — only the current folder's project
- Do NOT fix code yourself — reject and let the implementer fix it
- Do NOT approve tasks without structured completion evidence, no matter how obvious the change
- Do NOT skip Stage 2 for "trivial" changes
- Do NOT modify any source files — this skill is read-only except for git commit/push on deploy
- Do NOT run on all projects at once — that's what the old scheduled task did and it burned tokens

## Installation

```bash
# In the 1000Problems root (available to all projects):
mkdir -p ~/1000Problems/.claude/skills/vybepm
cp ~/1000Problems/Skills/vybepm-SKILL.md ~/1000Problems/.claude/skills/vybepm/SKILL.md
```
