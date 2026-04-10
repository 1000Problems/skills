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

## Verification Tiers

Every project falls into one of these tiers. The tier determines what evidence you collect at completion.

| Tier | Projects | Evidence Required |
|------|----------|-------------------|
| **A — Buildable** | ytcombinator, VybePM-v2, GitMCP, 1000Problems, popilearn | `npm run build` output + `git diff --name-only` + acceptance criteria evidence |
| **B — Not buildable from CLI** | Vybe, AnimationStudio, KitchenInventory, RubberJoints-iOS | `git diff --name-only` + file:line references per acceptance criterion |
| **C — Non-code** | Animation, Skills | `git diff --name-only` + content review of modified files |

## Project Registry

These are the active projects and their directories. The executor visits each in order.

| Project Slug | Directory | Type | Tier |
|-------------|-----------|------|------|
| ytcombinator | ~/1000Problems/ytcombinator | Next.js web app | A |
| VybePM | ~/1000Problems/VybePM-v2 | Next.js web app | A |
| Vybe | ~/1000Problems/Vybe | iOS Swift app | B |
| GitMCP | ~/1000Problems/GitMCP | Node.js MCP server | A |
| KitchenInventory | ~/1000Problems/KitchenInventory | iOS Swift app | B |
| RubberJoints-iOS | ~/1000Problems/RubberJoints-iOS | iOS Swift app | B |
| 1000Problems | ~/1000Problems/1000Problems | Next.js homepage | A |
| PopiLearn | ~/1000Problems/popilearn | Next.js web app | A |
| Animation | ~/1000Problems/Animation | Creative assets | C |
| AnimationStudio | ~/1000Problems/AnimationStudio | macOS Swift app | B |
| Skills | ~/1000Problems/Skills | Skill repository | C |

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
│ {directory} — {type} — Tier {A/B/C}  │
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

#### 1g. Gather Completion Evidence

**Before reporting completion, you MUST gather structured evidence.** The vybepm-reviewer will parse this format. Tasks with incomplete evidence get rejected back to `in_progress`.

**Step 1: Run `git diff --name-only`** and capture the output. Verify ONLY files listed in the TASK spec (or relevant to the task description) were modified.

**Step 2: Run the build (Tier A projects only):**
```bash
npm run build 2>&1 | tail -20
```
Capture the last 20 lines. If the build fails, fix it before proceeding.

**Step 3: Check each acceptance criterion** from the TASK spec (or infer criteria from the task title/description). For each, record specific evidence: terminal output for Tier A, file:line references for Tier B, content verification for Tier C.

**Step 4: Self-review.** Ask yourself:
- Did I modify files not listed in the TASK? If yes, why?
- Did I refactor or clean up adjacent code? If yes, that's scope creep.
- Did I add features not in the spec? If yes, that's YAGNI.

**Step 5: Compose the completion notes** using this exact format:

```
## Completion Evidence

### Scope Check
Files modified:
{paste git diff --name-only output}
Files outside TASK scope: NONE

### Build
{For Tier A: paste last 10 lines of npm run build}
{For Tier B: N/A — iOS/macOS project}
{For Tier C: N/A — non-code project}

### Acceptance Criteria
1. [x] {criterion} — EVIDENCE: {file:line or terminal output}
2. [x] {criterion} — EVIDENCE: {file:line or terminal output}

### Self-Review
- Modified files not in TASK: No
- Refactored adjacent code: No
- Added features not in spec: No
```

#### 1h. Report completion

Post the structured evidence to VybePM:

```bash
curl -s -X PATCH "https://vybepm-v2.vercel.app/api/executor/tasks/${TASK_ID}/complete" \
  -H "X-API-Key: ${VYBEPM_API_KEY}" \
  -H "X-Executor: claude-code" \
  -H "Content-Type: application/json" \
  -d '{"notes": "<the structured completion evidence from step 1g>"}'
```

**"Claiming work is complete without verification is dishonesty, not efficiency."**

```
  ✓ Task #{id} completed (evidence posted)
```

#### 1i. Check for more tasks in this project

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

## Rationalization Prevention

When executing tasks, watch for these traps:

| If you're thinking... | Stop. The reality is: |
|-----------------------|-----------------------|
| "This file needs fixing too" | That's scope creep. Create a VybePM task, don't fix it inline. |
| "I'll refactor this while I'm here" | Unauthorized cleanup. The TASK spec didn't ask for it. |
| "The build passes so it's done" | Build passing ≠ task complete. Fill in the Completion Evidence. |
| "This is a trivial change" | Trivial changes break things. Follow the full evidence flow. |
| "I'll add error handling to be safe" | Only add what the spec asks for. YAGNI. |
| "The adjacent component should match" | Stay in scope. If it should match, that's a new TASK. |
| "I can skip evidence for this one" | No. Every task gets structured notes. The reviewer will reject you. |

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
- Do NOT post freeform notes — use the structured Completion Evidence format or the reviewer will reject the task

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
