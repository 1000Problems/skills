---
name: vybego
description: "Pull tasks from VybePM API, execute them in the current project, and report completion. Use when Code is started in any 1000Problems project directory and should autonomously pick up and execute pending tasks."
---

# VybeGo — Autonomous Task Executor

This skill polls VybePM for pending tasks assigned to the current project, picks one up atomically, executes it, and reports completion.

## Execution Flow

1. Identify current project from CLAUDE.md → VybePM slug
2. GET /api/executor/next?project={slug} to find pending tasks
3. PATCH /api/executor/{id}/pickup to claim the task atomically
4. Read the task description and execute it (write code, fix bugs, etc.)
5. Run tests if applicable
6. PATCH /api/executor/{id}/complete with result summary
7. Repeat until no more pending tasks

## Project Slug Mapping

Read the VybePM Integration section of the project's CLAUDE.md to find the slug. If no CLAUDE.md exists, use the directory name.

## Error Handling

- If pickup returns 409 (already claimed), skip and try next task
- If execution fails, PATCH /api/executor/{id}/complete with status: "failed" and error details
- Never leave a task in "in_progress" without reporting back

## API Base

https://vybepm-v2.vercel.app
