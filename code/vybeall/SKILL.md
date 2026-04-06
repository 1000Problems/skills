---
name: vybeall
description: "Portfolio-wide autonomous task executor. Iterates through every 1000Problems project, pulls pending tasks from VybePM, executes them, and reports completion — one Code session builds the entire portfolio. Use when Angel says 'vybeall', 'run all projects', 'build everything', 'execute all tasks', or 'portfolio run'."
---

# VybeAll — Portfolio-Wide Task Executor

VybeAll is the big brother of VybeGo. Instead of executing tasks for one project, it walks through every active project in the 1000Problems portfolio and runs the VybeGo loop for each. One Code session, all projects, all pending tasks.

## Trigger

User runs `/vybeall` from the `1000Problems` root directory (`~/1000Problems`).

## Environment

Requires `VYBEPM_API_KEY` in environment or `.env.local` at the root level.
VybePM base URL: `https://vybepm-v2.vercel.app`

## Project Registry

These are the active projects and their directories. The executor visits each in order.

| Project Slug | Directory | Type |
|-------------|-----------|------|
| ytcombinator | ~/1000Problems/ytcombinator | Next.js web app |
| VybePM | ~/1000Problems/VybePM-v2 | Next.js web app |
| Vybe | ~/1000Problems/Vybe | iOS Swift app |
| GitMCP | ~/1000Problems/GitMCP | Node.js MCP server |
| KitchenInventory | ~/1000Problems/KitchenInventory | iOS Swift app |
| voiceq-api | ~/1000Problems/voiceq-api | Next.js API |
| RubberJoints-iOS | ~/1000Problems/RubberJoints-iOS | iOS Swift app |
| 1000Problems | ~/1000Problems/1000Problems | Next.js homepage |
| Animation | ~/1000Problems/Animation | Creative assets |
| AnimationStudio | ~/1000Problems/AnimationStudio | macOS Swift app |
| Skills | ~/1000Problems/Skills | Skill repository |

## Execution Flow

### Step 0: Preflight

1. Confirm working directory is `~/1000Problems` (or cd to it)
2. Verify `VYBEPM_API_KEY` is available
3. Fetch the full project list from VybePM API to confirm connectivity:
   ```bash
   curl -s "https://vybepm-v2.vercel.app/api/projects" \
     -H "X-API-Key: ${VYBEPM_API_KEY}"
   ```
4. Print the run header:
   ```
   ╔══════════════════════════════════════════╗
   ║  VybeAll — Portfolio Executor            ║
   ║  {date} | {N} active projects            ║
   ╚══════════════════════════════════════════╝
   ```

### Step 1: For each project in the registry

Process projects in the order listed above. For each project:

#### 1a. Enter the project

```bash
cd ~/1000Problems/{directory}
```

Print a project header:
```
┌──────────────────────────────────────┐
│ [{index}/{total}] {ProjectSlug}      │
│ {directory} — {type}                 │
└──────────────────────────────────────┘
```

#### 1b. Read project context

Read `CLAUDE.md` in the project directory. This is the project's instruction manual — it tells you the tech stack, file structure, conventions, and constraints.

If no CLAUDE.md exists, print a warning and skip to the next project:
```
⚠ No CLAUDE.md found — skipping {project}
```

#### 1c. Check for pending tasks

```bash
curl -s "https://vybepm-v2.vercel.app/api/executor/next?project=${PROJECT_SLUG}" \
  -H "X-API-Key: ${VYBEPM_API_KEY}" \
  -H "X-Executor: claude-code"
```

If 204 (no tasks):
```
  ✓ No pending tasks — moving on
```
Skip to the next project.

If 200: parse the task JSON.

#### 1d. Pick up the task

```bash
curl -s -X PATCH "https://vybepm-v2.vercel.app/api/executor/tasks/${TASK_ID}/pickup" \
  -H "X-API-Key: ${VYBEPM_API_KEY}" \
  -H "X-Executor: claude-code"
```

If 409 (already picked up): go back to 1c for the next available task.

#### 1e. Execute the task

Print the task:
```
  Task #{id} [{priority}] {task_type}
  {title}
  {description}
  ────────────────────────
```

Execute the task using the project's CLAUDE.md as context. This is standard Code work:
- Read relevant source files
- Write/modify code
- Run tests if the project has them
- Fix any errors that come up

Stay within the project directory. Do not touch files in other projects.

#### 1f. Report completion

```bash
curl -s -X PATCH "https://vybepm-v2.vercel.app/api/executor/tasks/${TASK_ID}/complete" \
  -H "X-API-Key: ${VYBEPM_API_KEY}" \
  -H "X-Executor: claude-code" \
  -H "Content-Type: application/json" \
  -d '{"notes": "Summary of changes..."}'
```

Notes should include: files created/modified, tests run, issues encountered.

```
  ✓ Task #{id} completed
```

#### 1g. Check for more tasks in this project

Loop back to 1c. Keep executing tasks for this project until the API returns 204 (no more pending tasks). Then move to the next project.

### Step 2: Print summary

After all projects have been processed, print a run summary:

```
╔══════════════════════════════════════════╗
║  VybeAll Run Complete                    ║
╠══════════════════════════════════════════╣
║  Projects visited: {N}                   ║
║  Tasks completed:  {count}               ║
║  Tasks failed:     {count}               ║
║  Skipped (no CLAUDE.md): {count}         ║
║  Time elapsed: {duration}                ║
╚══════════════════════════════════════════╝

Completed tasks:
  #{id} {project} — {title}
  #{id} {project} — {title}
  ...

Failed tasks:
  #{id} {project} — {title} — {error reason}
  ...
```

## Error Handling

### Per-task errors
If a task fails during execution:
- Do NOT report completion — leave the task as `in_progress`
- Log the error in the summary
- Move on to the next task in the same project (or next project if no more tasks)
- Do NOT abort the entire run because of one failed task

### API errors
- If VybePM is unreachable at preflight: abort the entire run with a clear error
- If VybePM becomes unreachable mid-run: retry once, then skip that project and continue
- If the API key is missing: abort immediately

### Project errors
- If a project directory doesn't exist: log a warning and skip
- If CLAUDE.md is missing: log a warning and skip
- If git is in a broken state (merge conflicts, etc.): log a warning and skip

## Fallback: Local TASK files

If the VybePM Executor API is not yet deployed (returns 404), fall back to reading local `TASK-*.md` files in each project directory. Process them in alphabetical order. After execution, rename the file to `DONE-*.md` so it's not picked up again.

## Do NOT

- Do NOT commit or push — Angel handles git for every project
- Do NOT modify files outside the current project's directory while working on its tasks
- Do NOT pick up tasks assigned to `angel` or `cowork` — only `claude-code` tasks
- Do NOT skip the pickup step — it prevents race conditions with other executors
- Do NOT continue to the next project if the current one has a dirty git state that might cause problems — log a warning and skip
- Do NOT install dependencies globally — use project-local installs only
- Do NOT delete any files unless the task explicitly requires it

## Project-Specific Notes

Some projects need extra care:

| Project | Notes |
|---------|-------|
| Vybe | iOS project — can't run tests without simulator. Validate with `xcodebuild -scheme VybePM -destination 'platform=iOS Simulator,name=iPhone 16' build` |
| AnimationStudio | macOS project — `xcodebuild -scheme AnimationStudio build` |
| Animation | Not a code project — tasks here are creative (generate HTML prototypes, write scripts). No test runner. |
| Skills | Not a code project — tasks are writing/updating SKILL.md files. |
| GitMCP | After changes, rebuild with `npm run build`. Run `node dist/index.js --help` to sanity check. |

## Installation

Install as a global Code skill:
```bash
mkdir -p ~/.claude/skills/vybeall
cp ~/1000Problems/Skills/code/vybeall/SKILL.md ~/.claude/skills/vybeall/SKILL.md
```

Or install in the 1000Problems root project:
```bash
mkdir -p ~/1000Problems/.claude/skills/vybeall
cp ~/1000Problems/Skills/code/vybeall/SKILL.md ~/1000Problems/.claude/skills/vybeall/SKILL.md
```
