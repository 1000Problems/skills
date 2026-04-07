---
name: vybeforever
description: "Autonomous portfolio executor that runs the VybeAll loop every 4 hours, indefinitely. Iterates through every 1000Problems project, pulls pending tasks from VybePM, executes them, reports completion, then sleeps 4 hours and repeats. Use when Angel says 'vybeforever', 'run forever', 'keep building', 'loop executor', or 'autonomous mode'."
---

# VybeForever — Continuous Portfolio Executor

VybeForever is VybeAll in a loop. It runs the full portfolio executor cycle (visit every project, pull and execute pending tasks, report completion), then sleeps for 4 hours and does it again. It runs until manually stopped.

## Trigger

User runs `/vybeforever` from the `1000Problems` root directory (`~/1000Problems`).

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
| RubberJoints-iOS | ~/1000Problems/RubberJoints-iOS | iOS Swift app |
| 1000Problems | ~/1000Problems/1000Problems | Next.js homepage |
| Animation | ~/1000Problems/Animation | Creative assets |
| AnimationStudio | ~/1000Problems/AnimationStudio | macOS Swift app |
| Skills | ~/1000Problems/Skills | Skill repository |

## Loop Structure

```
┌─────────────────────────────────────────────┐
│  FOREVER LOOP                               │
│                                             │
│  0. Reindex LightRAG + preflight checks     │
│  1. Run the full VybeAll cycle              │
│  2. Print cycle summary                     │
│  3. Sleep 4 hours (14400 seconds)           │
│  4. Go to 0                                 │
│                                             │
│  Exits only when manually stopped (Ctrl+C)  │
└─────────────────────────────────────────────┘
```

## Execution Flow

### Cycle Start: Print banner

At the start of each cycle, print:

```
╔══════════════════════════════════════════════╗
║  VybeForever — Cycle #{N}                    ║
║  {date} {time} | {N} active projects         ║
║  Next cycle at: {date} {time + 4h}           ║
╚══════════════════════════════════════════════╝
```

### Step 0: LightRAG Reindex + Preflight

**0a. Reindex LightRAG (every cycle)**

Run the reindex script to ensure the knowledge graph has the latest project docs:

```bash
bash ~/1000Problems/reindex-lightrag.sh
```

This indexes all CLAUDE.md, SPEC.md, DESIGN.md, and other architectural docs across the portfolio into the LightRAG knowledge graph (localhost:9621). If LightRAG is down (script exits non-zero), log a warning but continue — you'll fall back to reading CLAUDE.md files directly for each project.

**0b. Preflight checks**

1. Confirm working directory is `~/1000Problems` (or cd to it)
2. Load credentials:
   ```bash
   source ~/1000Problems/secrets.env
   ```
   This gives you: VYBEPM_API_KEY, GITHUB_PAT, DATABASE_URL, VERCEL_TOKEN
3. Fetch the full project list from VybePM API to confirm connectivity:
   ```bash
   curl -s "https://vybepm-v2.vercel.app/api/projects" \
     -H "X-API-Key: ${VYBEPM_API_KEY}"
   ```
4. If VybePM is unreachable: log the error, sleep 4 hours, retry next cycle. Do NOT abort the forever loop.

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

#### 1b. Read project context + query LightRAG

**First, query LightRAG** for this project's architectural context and any cross-project constraints:

```bash
curl -s -X POST http://localhost:9621/query \
  -H "Content-Type: application/json" \
  -d '{"query": "what are the protected areas, constraints, and current state of '"${PROJECT_SLUG}"'", "mode": "hybrid"}'
```

Use the LightRAG response to understand:
- What files and components are protected (Do Not Change)
- What patterns and conventions the project follows
- What cross-project dependencies exist (shared DB, APIs, etc.)

**Then read `CLAUDE.md`** in the project directory. This is the authoritative instruction manual — it defines the tech stack, file structure, conventions, and constraints. The LightRAG query gives you cross-project context; CLAUDE.md gives you project-specific rules.

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

#### 1e. Query LightRAG for task-specific context

Before executing, query LightRAG with the specific task details:

```bash
curl -s -X POST http://localhost:9621/query \
  -H "Content-Type: application/json" \
  -d '{"query": "context for implementing: '"${TASK_TITLE}"' in '"${PROJECT_SLUG}"'. What patterns should I follow? What should I not change?", "mode": "hybrid"}'
```

This gives you awareness of:
- Similar patterns implemented in other projects
- Related state machines or API contracts
- Files that other projects depend on (don't break them)

If LightRAG is down, skip this step and rely on CLAUDE.md alone.

#### 1f. Execute the task

Print the task:
```
  Task #{id} [{priority}] {task_type}
  {title}
  {description}
  ────────────────────────
```

Execute the task using both the LightRAG context and the project's CLAUDE.md as guardrails. This is standard Code work:
- Read relevant source files
- Write/modify code
- Run tests if the project has them
- Fix any errors that come up

**Critical: respect the CLAUDE.md Protected Areas and any Do Not Change section in the TASK spec.** If you discover something outside scope that needs fixing, create a VybePM task for it instead:

```bash
curl -s -X POST "https://vybepm-v2.vercel.app/api/projects/${PROJECT_SLUG}/tasks" \
  -H "X-API-Key: ${VYBEPM_API_KEY}" \
  -H "Content-Type: application/json" \
  -d '{"title": "Found during task #'${TASK_ID}': ...", "task_type": "dev", "priority": 3, "assignee": "claude-code"}'
```

Stay within the project directory. Do not touch files in other projects.

#### 1g. Report completion

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

#### 1h. Check for more tasks in this project

Loop back to 1c. Keep executing tasks for this project until the API returns 204 (no more pending tasks). Then move to the next project.

### Step 2: Print cycle summary

After all projects have been processed for this cycle:

```
╔══════════════════════════════════════════════╗
║  Cycle #{N} Complete                         ║
╠══════════════════════════════════════════════╣
║  Projects visited: {N}                       ║
║  Tasks completed:  {count}                   ║
║  Tasks failed:     {count}                   ║
║  Skipped (no CLAUDE.md): {count}             ║
║  Cycle duration: {duration}                  ║
║  LightRAG: {up/down}                         ║
║                                              ║
║  Sleeping until: {time + 4h}                 ║
╚══════════════════════════════════════════════╝

Completed tasks:
  #{id} {project} — {title}
  ...

Failed tasks:
  #{id} {project} — {title} — {error reason}
  ...
```

### Step 3: Sleep 4 hours

```bash
sleep 14400
```

Then increment the cycle counter and go back to Cycle Start.

If there were zero tasks across all projects, still sleep and retry — new tasks may appear in VybePM between cycles.

## Error Handling

### Per-task errors
If a task fails during execution:
- Do NOT report completion — leave the task as `in_progress`
- Log the error in the cycle summary
- Move on to the next task in the same project (or next project if no more tasks)
- Do NOT abort the cycle or the forever loop because of one failed task

### API errors
- If VybePM is unreachable at preflight: log the error, skip the entire cycle, sleep 4 hours, retry
- If VybePM becomes unreachable mid-cycle: retry once, then skip that project and continue
- If the API key is missing: abort immediately (this is a config problem, not transient)

### LightRAG errors
- If LightRAG is down during reindex: log a warning, continue without graph context
- If LightRAG is down during per-project queries: skip the query, rely on CLAUDE.md alone
- Do NOT abort any cycle because LightRAG is unavailable — it's an enhancement, not a requirement

### Project errors
- If a project directory doesn't exist: log a warning and skip
- If CLAUDE.md is missing: log a warning and skip
- If git is in a broken state (merge conflicts, etc.): log a warning and skip

### Forever loop resilience
The forever loop must NEVER exit on its own except for:
- Missing API key (unrecoverable config issue)
- Manual interruption (Ctrl+C)

All other errors (network, API, LightRAG, task failures, project errors) are logged and the loop continues. The next cycle is a fresh start.

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
- Do NOT exit the forever loop unless the API key is missing or the user interrupts
- Do NOT modify Protected Areas listed in a project's CLAUDE.md — create a VybePM task instead

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
mkdir -p ~/.claude/skills/vybeforever
cp ~/1000Problems/Skills/code/vybeforever/SKILL.md ~/.claude/skills/vybeforever/SKILL.md
```

Or install in the 1000Problems root project:
```bash
mkdir -p ~/1000Problems/.claude/skills/vybeforever
cp ~/1000Problems/Skills/code/vybeforever/SKILL.md ~/1000Problems/.claude/skills/vybeforever/SKILL.md
```
