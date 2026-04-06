---
name: daily-portfolio-report
type: scheduled-task
description: "Daily incremental report across all 1000Problems projects. Dynamically discovers projects, pulls git commits + VybePM task activity + Vercel deploy status, generates assessment with open items. Runs daily at 4am."
schedule: "0 4 * * *"
---

# 1000Problems Daily Portfolio Report — Dynamic Project Discovery

Generate the daily incremental report across ALL projects in the 1000Problems portfolio.

## Step 1: Discover all projects dynamically

Use `fs_list` on `/Users/angel/1000Problems/` to get every directory. Each directory is a project. Do NOT hardcode project names — always discover them fresh. Skip non-directory entries.

## Step 2: Pull git commits from each project

For each discovered directory, run `git_log` to get commits since midnight yesterday. If a directory isn't a git repo, note it and move on.

## Step 3: Check VybePM for task activity

```
GET https://vybepm-v2.vercel.app/api/digest?since={yesterday}
Header: X-API-Key: {VYBEPM_API_KEY}
```

If the API is unreachable, skip this section — don't fail the whole report.

## Step 4: Check Vercel deployment status

For web projects that have a `deploy_url` in their CLAUDE.md or VybePM entry, check recent deployment status via Vercel MCP tools to catch build errors.

## Step 5: Generate the report

```
## 1000Problems — {Month Day, Year}

### Commits

| Project | # | SHA | Description |
|---|---|---|---|
| {Project} | {sequential number within project} | `{7-char SHA}` | {One-line commit message} |

{List repos with no changes on one line.}

### Tasks (from VybePM)

| Project | Task | Status | Assignee |
|---|---|---|---|
| {Project} | {Task title} | {Status change} | {assignee} |

{Only include if VybePM digest API returned data.}

### Assessment

{2-3 paragraphs. Honest editorial. What's moving, what's stalled, what matters. No cheerleading.}

### Open Items

1. **{Item}** — {one-line context}
```

## Style rules

- Commits table: facts only, actual commit messages, numbered per project
- Assessment: opinions. Direct. Stalled means stalled.
- Open items: actionable and specific
- No emoji. No bullets in assessment. Fits on one screen.
- Cross-reference git commits with VybePM tasks when both available.

## Important

- ALWAYS discover projects by listing `/Users/angel/1000Problems/` — never hardcode
- New projects get included automatically
- If a directory has no .git, skip its commits but mention it exists
