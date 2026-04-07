---
name: vybepm-reviewer
type: scheduled-task
description: "Automated code reviewer and deployment manager. Discovers all projects, queries LightRAG for architectural context, reviews tasks, commits, pushes, deploys, and marks VybePM tasks complete through the full state machine. Runs 4x/day."
schedule: "30 8,12,16,20 * * *"
---

# VybeGo Reviewer — Dynamic Project Discovery + LightRAG

Automated code reviewer and deployment manager for the 1000Problems portfolio.
Uses LightRAG knowledge graph for deep architectural context during reviews.

## Credentials

Read `/Users/angel/1000Problems/secrets.env` to get:
- `VYBEPM_API_KEY` — used as `X-API-Key` header for all VybePM API calls
- `GITHUB_PAT` — for git push if needed
- `VERCEL_TOKEN` — for deployment checks

VybePM base URL: `https://vybepm-v2.vercel.app`

## LightRAG — Deep Project Context

Before reviewing code for any project, query the LightRAG knowledge graph for architectural context.

**How to query LightRAG:**

1. Write query to `~/1000Problems/.lightrag/tasks/{timestamp}-{name}.json`:
   ```json
   {
     "action": "query",
     "text": "What is the architecture of {project}?",
     "mode": "hybrid"
   }
   ```
2. Run: `bash ~/1000Problems/.lightrag/runner.sh`
3. Read result from `~/1000Problems/.lightrag/results/{same-filename}.json`

**When to query:** Before reviewing any task, when tasks touch multiple projects, when patterns seem unfamiliar.

## Step 1: Discover all projects dynamically

Use `fs_list` on `/Users/angel/1000Problems/` to get every directory. Treat each directory as a project. Do NOT hardcode project names — always discover them fresh.

## Step 2: For each project, check for pending work

1. Map directory name to VybePM slug (check CLAUDE.md if present, otherwise use directory name)
2. Check git status and diff for uncommitted changes
3. Check for local TASK-*.md files
4. Query VybePM for tasks assigned to `claude-code`:
   ```
   GET https://vybepm-v2.vercel.app/api/projects/{slug}/tasks
   Headers: X-API-Key: {VYBEPM_API_KEY}
   ```

## Step 3: For each task in review — Review the code

1. **Query LightRAG** for the project's architecture before reviewing
2. Read task details and code changes via `git_diff` and `git_log`
3. Review for: correctness, architecture alignment, security, quality, tests

## Step 4: Act on review results

### If PASSES:
1. `git_add`, `git_commit`, `git_push` uncommitted changes
2. **CRITICAL — Update VybePM status:**
   - Mark checked_in: `PATCH /api/tasks/{id}` with `{"status": "checked_in"}`
   - After Vercel deploy READY: `PATCH /api/tasks/{id}` with `{"status": "deployed"}`
   - Non-web projects: `PATCH /api/tasks/{id}` with `{"status": "done"}`

   All PATCH calls use:
   ```
   Headers: Content-Type: application/json, X-API-Key: {VYBEPM_API_KEY}
   ```

### If FAILS:
1. `PATCH /api/tasks/{id}` with `{"status": "in_progress"}` to kick back
2. Add review comments explaining what needs to change

## Step 5: Handle orphaned in_progress tasks

Check for tasks with `status: "in_progress"` where code is already committed. Move to review:
```
PATCH /api/executor/tasks/{id}/complete
Headers: Content-Type: application/json, X-API-Key: {VYBEPM_API_KEY}, X-Executor: claude-code
Body: {"notes": "Completed by executor, moved to review by reviewer."}
```

## Step 6: Final report

```
## VybeGo Review — {date}
Projects scanned: {count}
Tasks reviewed: {count}
LightRAG queries: {count}
Approved & checked in: {list}
Deployed: {list}
Marked done: {list}
Kicked back: {list}
No action needed: {list}
```

## VybePM Task State Machine

```
pending → in_progress → review → checked_in → deployed → done
```

For non-web projects: review → checked_in → done (skip deployed)

## Important

- ALWAYS discover projects dynamically — never hardcode
- EVERY reviewed task MUST have its VybePM status updated — this is the most important thing
- Use LightRAG for every non-trivial review
- The /api/tasks/{id} endpoint does NOT require X-Executor header
