---
name: pwork-code
command: /pwork_code
model: sonnet
spawn: true
effort: medium
description: "Compress the design discussion into a focused task prompt and spawn a Sonnet coding agent. The orchestrator stays in Opus while the agent implements."
---

# /c — Code Handoff

Compress the design conversation into a spawn prompt and fire the subagent. This skill is called BY the orchestrator (Opus), not by the subagent.

## Steps

### 1. Extract the Task

Review the conversation since the last /d or since session start. Identify:
- **Goal**: What are we building? One sentence.
- **Files**: Which files to create or modify. Be specific with paths.
- **Constraints**: Patterns to follow, APIs to use, things to avoid.
- **Protected files**: What must NOT be touched. Pull from CLAUDE.md + discussion.
- **Done criteria**: How the subagent knows it's finished. Must be verifiable (build passes, behavior works, git diff is scoped).

### 2. Format the Prompt

```
GOAL: {one sentence}

FILES:
- {path/to/file1} — {what to do}
- {path/to/file2} — {what to do}

CONSTRAINTS:
- {constraint}

DO NOT TOUCH:
- {file or pattern} — {reason}

DONE WHEN:
- {criterion}

VERIFY: Run `cargo build` and `npm run build`. Check `git diff --stat` — only listed files should appear.
```

Keep it under 500 tokens. The subagent reads CLAUDE.md for project context — don't repeat what's already there.

### 3. Spawn

Call the pwork MCP tool:
```
spawn_agent({ task: "<the prompt above>", model: "sonnet" })
```

If the user specified a different model (e.g., "use opus for this one"), pass that instead.

### 4. Confirm and Continue

Tell the user: "Agent spawned — {goal}. Watch the sidebar for progress."

Then continue in /d design mode. Don't wait. Don't poll. When `[pwork] Agent completed` or `[pwork] Agent failed` appears in the terminal, acknowledge it.

### 5. On Agent Failure

If the agent fails or produces bad output:
- Call `get_agent_state` to see what happened
- Discuss with the user what went wrong
- Refine the prompt and re-spawn with /c

## What NOT to Do

- Don't write the code yourself. The whole point is delegation.
- Don't create TASK-*.md files. The spawn prompt replaces them.
- Don't pass the entire conversation as context. Compress.
- Don't spawn if the design discussion isn't finished. Ask "ready to hand off?" if unsure.
