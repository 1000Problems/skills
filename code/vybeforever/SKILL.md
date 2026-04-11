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