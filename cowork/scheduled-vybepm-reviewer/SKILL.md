---
name: vybepm-reviewer
type: scheduled-task
description: "Automated code reviewer and deployment manager. Dynamically discovers all projects under 1000Problems/, checks VybePM for tasks in review, performs code review, approves or kicks back, commits, pushes, and triggers deploys. Runs 4x/day."
schedule: "30 8,12,16,20 * * *"
---

# VybeGo Reviewer — Dynamic Project Discovery

Automated code reviewer and deployment manager for the 1000Problems portfolio.

## Step 1: Discover all projects dynamically

Use `fs_list` on `/Users/angel/1000Problems/` to get every directory. Treat each directory as a project. Do NOT hardcode project names — always discover them fresh. Skip any non-directory entries.

## Step 2: Check each project for tasks in review

For each discovered project directory:

1. Map the directory name to a VybePM slug (check CLAUDE.md's VybePM Integration section if present, otherwise use directory name)
2. Query VybePM for tasks in review status:
   ```
   GET https://vybepm-v2.vercel.app/api/executor/next?project={slug}&status=review
   ```
3. If no VybePM API is available or returns errors, fall back to checking for TASK-*.md files in the project directory via `fs_list`

## Step 3: For each task in review

1. Read the task details and the associated code changes
2. Use `git_diff` and `git_log` on the project repo to see what was changed
3. Review for:
   - Correctness: Does the code do what the task asked?
   - Security: No leaked keys, no exposed secrets, no SQL injection
   - Quality: No AI slop, no unnecessary abstractions, clean code
   - Tests: Were tests added/updated if applicable?
4. If the review passes:
   - Approve the task (PATCH status to checked_in)
   - `git_add`, `git_commit`, `git_push` if there are uncommitted changes
   - For web projects, check Vercel deployment status
5. If the review fails:
   - Add review comments explaining what needs to change
   - PATCH the task back to in_progress with feedback

## Step 4: Report

```
## VybeGo Review — {date}

Projects scanned: {count}
Tasks reviewed: {count}
Approved: {list}
Kicked back: {list}
Deployments triggered: {list}

No action needed: {list of projects with nothing in review}
```

## Important

- ALWAYS discover projects by listing `/Users/angel/1000Problems/` — never use a hardcoded list
- New projects added to the directory should automatically be picked up
- If a project has no CLAUDE.md, still check it for TASK files and git status
- Do not skip any directory
