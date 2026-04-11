---
name: vybego
description: "Pull tasks from VybePM API, execute them, and report completion. Works two ways: (1) run with a project name — e.g. `/vybego vybepm` — from the 1000Problems root to target a specific project, or (2) run with no argument from inside any project directory. Use when Code should autonomously pick up and execute pending tasks for a project."
---

# VybeGo — Autonomous Task Executor

This skill polls VybePM for pending tasks assigned to a project, picks them up atomically, executes them, and reports completion.

## Usage

- `/vybego vybepm` — from `~/1000Problems`, work on VybePM-v2
- `/vybego animationstudio` — from `~/1000Problems`, work on AnimationStudio
- `/vybego` — no argument, work on whatever project directory you're already in

## Project Registry

When a project name is given as an argument, resolve it using this table. Match is **case-insensitive** against both the Slug and Aliases columns.

| Slug | Directory | Aliases |
|------|-----------|---------|
| ytcombinator | ~/1000Problems/ytcombinator | ytc, yt |
| VybePM | ~/1000Problems/VybePM-v2 | vybepm, vpm, vybepm-v2 |
| Vybe | ~/1000Problems/Vybe | vybe |
| GitMCP | ~/1000Problems/GitMCP | gitmcp, mcp |
| KitchenInventory | ~/1000Problems/KitchenInventory | kitchen, ki |
| RubberJoints-iOS | ~/1000Problems/RubberJoints-iOS | rubberjoints, rj |
| 1000Problems | ~/1000Problems/1000Problems | homepage, 1000p |
| PopiLearn | ~/1000Problems/popilearn | popilearn, popi |
| Animation | ~/1000Problems/Animation | animation, anim |
| AnimationStudio | ~/1000Problems/AnimationStudio | animationstudio, studio, as |
| Skills | ~/1000Problems/Skills | skills |

If the argument doesn't match any slug or alias, check if a directory with that name exists under `~/1000Problems/`. If it does, use it. Otherwise, print an error and stop.

## Execution Flow

### Step 0: Resolve the project

- **Argument given:** Look up the project in the registry. `cd` into that directory.
- **No argument:** Stay in the current directory.

Then:

1. Read the project's CLAUDE.md to get the VybePM slug and understand constraints
2. Read BUILD.md if it exists (for implementation context)
3. `GET /api/executor/next?project={slug}` to find pending tasks
4. `PATCH /api/executor/{id}/pickup` to claim the task atomically
5. Read the task description and execute it (write code, fix bugs, etc.)
6. Run build/tests if applicable for the project
7. **Fill in the Completion Evidence template** (see below — this is mandatory before calling complete)
8. `PATCH /api/executor/{id}/complete` with the completed Completion Evidence as the notes body
9. Loop back to step 3 until no more pending tasks (API returns 204)

### Fallback: Local TASK files

If VybePM returns no tasks (204) or is unreachable, check for `TASK-*.md` files in the project directory. Process them in alphabetical order. After execution, rename to `DONE-{slug}.md`.

## API Details

Base URL: `https://vybepm-v2.vercel.app`

All requests need:
- `X-API-Key: ${VYBEPM_API_KEY}`
- `X-Executor: claude-code`

Source the key before making requests:
```bash
source ~/1000Problems/secrets.env
```

### Endpoints

```
GET  /api/executor/next?project={slug}      → 200 + task JSON, or 204 if empty
PATCH /api/executor/tasks/{id}/pickup        → 200 or 409 (already claimed)
PATCH /api/executor/tasks/{id}/complete      → 200 (send {"notes": "..."} body)
```

## Completion Evidence (MANDATORY)

The automated reviewer will hard-reject any task whose notes are freeform. Do not write "Executor Notes:" summaries. Do not narrate what you did. Fill in the structured template below — every section, every field.

Before calling `/complete`, draft the Completion Evidence in full. "It passed" is not evidence — paste actual output. If a criterion doesn't apply, say why explicitly.

```
## Completion Evidence

### Scope Check
Files modified:
- `path/to/file` — what changed and why
- `path/to/file` — what changed and why

Files outside task scope: NONE
(If any: list each file + justify why the change was necessary)

### Build
(Next.js/Node projects — paste last ~10 lines of `npm run build` output)
(iOS/macOS projects — write "N/A — Xcode project, built manually in IDE")
(Non-code projects — write "N/A — no build step")

### Acceptance Criteria
- [x] criterion text — EVIDENCE: (exact file:line, terminal output, or observable behavior)
- [x] criterion text — EVIDENCE: (exact file:line, terminal output, or observable behavior)
- [ ] criterion text — BLOCKED: (specific reason why this couldn't be completed)

### Self-Review
- Secrets or hardcoded credentials introduced? No / Yes → (explain)
- `any` types added (TypeScript projects)? No / Yes → (explain)
- Files modified outside task scope? No / Yes → (list + justify)
- TODO/FIXME/HACK comments left in code? No / Yes → (explain)
- Files deleted that might matter? No / Yes → (explain)
```

If a task has no explicit acceptance criteria (e.g., a simple one-line visual fix), derive reasonable criteria from the task description and fill them in. A criterion like `- [x] Banner links to YouTube — EVIDENCE: app/page.tsx:42 — anchor wraps Image with correct href` is exactly right.

## Error Handling

- Pickup returns 409 (already claimed): skip, try next task
- Execution fails: PATCH complete with error details in the notes — still use the Completion Evidence format, mark failed criteria as `[ ] — FAILED: reason`
- Never leave a task stuck in `in_progress` without reporting back
- VybePM unreachable: fall back to local TASK files

## Do NOT

- After completing each task, review changes against the project's CLAUDE.md guidelines, then commit and push. Report any push failures in the completion evidence.
- Do NOT pick up tasks assigned to `angel` or `cowork` — only `claude-code` tasks
- Do NOT modify files outside the target project's directory
- Do NOT install dependencies globally — project-local only
- Do NOT write freeform "Executor Notes:" prose as your completion report — the reviewer will reject it every time
