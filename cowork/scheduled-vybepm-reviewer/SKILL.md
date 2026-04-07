---
name: vybepm-reviewer
type: scheduled-task
description: "Automated code reviewer and deployment manager. Discovers all projects, reviews tasks, commits, pushes, deploys, and marks VybePM tasks complete through the full state machine. Runs 4x/day."
schedule: "30 8,12,16,20 * * *"
---

# VybeGo Reviewer — Dynamic Project Discovery

Automated code reviewer and deployment manager for the 1000Problems portfolio.

## Credentials

Read `/Users/angel/1000Problems/secrets.env` to get:
- `VYBEPM_API_KEY` — used as `X-API-Key` header for all VybePM API calls
- `GITHUB_PAT` — for git push if needed
- `VERCEL_TOKEN` — for deployment checks

VybePM base URL: `https://vybepm-v2.vercel.app`

## Step 1: Discover all projects dynamically

Use `fs_list` on `/Users/angel/1000Problems/` to get every directory. Treat each directory as a project. Do NOT hardcode project names — always discover them fresh. Skip any non-directory entries.

## Step 2: For each project, check for pending work

For each discovered project directory:

1. Map the directory name to a VybePM slug (check CLAUDE.md's VybePM Integration section if present, otherwise use directory name as-is)
2. Check git status via `git_status` and `git_diff` for uncommitted changes
3. Check for local TASK-*.md files via `fs_list`
4. Query VybePM for tasks assigned to `claude-code`:
   ```
   GET https://vybepm-v2.vercel.app/api/projects/{slug}/tasks
   Headers: X-API-Key: {VYBEPM_API_KEY}
   ```
   Look for tasks with `status: "review"` or `status: "in_progress"` assigned to `claude-code`.

## Step 3: For each task in review — Review the code

1. Read the task details and the associated code changes
2. Use `git_diff` and `git_log` on the project repo to see what was changed
3. Review for:
   - Correctness: Does the code do what the task asked?
   - Security: No leaked keys, no exposed secrets, no SQL injection
   - Quality: No AI slop, no unnecessary abstractions, clean code
   - Tests: Were tests added/updated if applicable?

## Step 4: Act on review results

### If the review PASSES:
1. `git_add`, `git_commit`, `git_push` if there are uncommitted changes
2. For web projects (ytcombinator, VybePM-v2, 1000Problems), verify Vercel deployment was triggered
3. **CRITICAL — Mark the task as checked_in in VybePM:**
   ```
   PATCH https://vybepm-v2.vercel.app/api/tasks/{task_id}
   Headers:
     Content-Type: application/json
     X-API-Key: {VYBEPM_API_KEY}
   Body: { "status": "checked_in" }
   ```
4. After verifying the Vercel deployment is READY (not just BUILDING), mark as deployed:
   ```
   PATCH https://vybepm-v2.vercel.app/api/tasks/{task_id}
   Headers:
     Content-Type: application/json
     X-API-Key: {VYBEPM_API_KEY}
   Body: { "status": "deployed" }
   ```
5. For non-web projects (Skills, GitMCP, KitchenInventory, etc.) that have no deploy step, go straight to done after check-in:
   ```
   PATCH https://vybepm-v2.vercel.app/api/tasks/{task_id}
   Headers:
     Content-Type: application/json
     X-API-Key: {VYBEPM_API_KEY}
   Body: { "status": "done" }
   ```

### If the review FAILS:
1. PATCH the task back to `in_progress` with feedback:
   ```
   PATCH https://vybepm-v2.vercel.app/api/tasks/{task_id}
   Headers:
     Content-Type: application/json
     X-API-Key: {VYBEPM_API_KEY}
   Body: { "status": "in_progress" }
   ```
2. Add review comments explaining what needs to change

## Step 5: Handle in_progress tasks from the executor

Also check for tasks with `status: "in_progress"` assigned to `claude-code`. If the code changes for that task are already committed and pushed (visible in git log), the executor finished but forgot to mark it. Move these to review → then review them normally in Step 3.

To move in_progress → review, use the executor complete endpoint:
```
PATCH https://vybepm-v2.vercel.app/api/executor/tasks/{task_id}/complete
Headers:
  Content-Type: application/json
  X-API-Key: {VYBEPM_API_KEY}
  X-Executor: claude-code
Body: { "notes": "Completed by executor, moved to review by reviewer." }
```

## Step 6: Final report

```
## VybeGo Review — {date}

Projects scanned: {count}
Tasks reviewed: {count}
Approved & checked in: {list with task IDs}
Deployed: {list with task IDs}
Marked done: {list with task IDs}
Kicked back: {list with task IDs}
No action needed: {list of clean projects}
```

## VybePM Task State Machine

```
pending → in_progress → review → checked_in → deployed → done
```

Allowed transitions:
- pending → in_progress (executor picks up)
- in_progress → review (executor completes)
- review → checked_in (reviewer approves + pushes code)
- review → in_progress (reviewer kicks back)
- checked_in → deployed (reviewer confirms deploy)
- deployed → done (reviewer confirms working)

For non-web projects: review → checked_in → done (skip deployed)

## Important

- ALWAYS discover projects by listing `/Users/angel/1000Problems/` — never use a hardcoded list
- New projects added to the directory should automatically be picked up
- If a project has no CLAUDE.md, still check it for TASK files and git status
- Do not skip any directory
- The /api/tasks/{id} endpoint does NOT require X-Executor header — only the /api/executor/* endpoints do
- EVERY reviewed task MUST have its VybePM status updated. If you review code and push it but don't update VybePM, the task gets stuck forever. This is the most important thing you do.
