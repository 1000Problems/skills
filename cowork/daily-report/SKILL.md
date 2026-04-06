---
name: daily-report
description: "Generate the daily incremental portfolio report for 1000Problems. Use this skill whenever Angel asks for a 'daily report', 'status update', 'what happened today', 'incremental summary', 'daily summary', 'portfolio report', or anything related to checking the state of the 1000Problems repos. Also trigger when a scheduled task runs this skill automatically at 4am. This skill should be used even for quick check-ins — it IS the standard reporting format."
---

# 1000Problems Daily Report

Generate a daily incremental summary across all projects in the 1000Problems portfolio. The report has three sections: Commits, Assessment, and Open Items. It should be concise — a busy CEO should be able to read the whole thing in 60 seconds.

## Data Collection

### Primary: VybePM Digest API (when available)

```
GET https://vybepm-v2.vercel.app/api/digest?since={yesterday}
Header: X-API-Key: {VYBEPM_API_KEY}
```

This returns all task activity grouped by project — status changes, new tasks, completed work.

### Secondary: Git commits across all project directories

Use `git_log` on each repo at `/Users/angel/1000Problems/`:

```
ytcombinator        — Next.js YouTube analytics dashboard
VybePM-v2           — Next.js task orchestration hub
Vybe                — SwiftUI iOS voice-to-task client
GitMCP              — Node/TS MCP server for git + filesystem access
KitchenInventory    — SwiftUI iOS kitchen inventory with AI
voiceq-api          — Next.js voice queue API
RubberJoints-iOS    — SwiftUI iOS workout coach
1000Problems        — Portfolio homepage (C# → Next.js migration)
Animation           — PopiPlay creative assets and prototypes
AnimationStudio     — macOS SwiftUI video production app
Skills              — Central skill repository for Cowork and Code
```

For each repo, pull commits since midnight yesterday:
```
git_log --repo_path=/Users/angel/1000Problems/{project} --max_count=20
```

Filter to only commits since the last report date.

### Tertiary: Vercel deployment status

Check deployment status for web projects: ytcombinator, VybePM-v2, voiceq-api, 1000Problems (if migrated).
Use the Vercel MCP tools (list_deployments, get_deployment) to catch build errors.

## Report Format

The report uses this exact structure. No deviations.

```
## 1000Problems — {Month Day, Year}

### Commits

| Project | # | SHA | Description |
|---|---|---|---|
| {Project} | {sequential number within project} | `{7-char SHA}` | {One-line commit message} |

{List any repos with no changes on a single line: "Vybe, Animation, KitchenInventory — no changes."}

### Tasks (from VybePM)

| Project | Task | Status | Assignee |
|---|---|---|---|
| {Project} | {Task title} | {Status change: pending → in_progress} | {assignee} |

{Only include if VybePM digest API is available. Skip this section if API is unreachable.}

### Assessment

{2-3 paragraphs. Honest editorial opinion on portfolio progress. What's moving, what's stalled, what matters. Call out risks like context rot on idle projects, broken deploys, or missing specs. Say what the right next move is and why. No cheerleading — if nothing happened, say so.}

### Open Items

1. **{Item}** — {one-line context}
2. **{Item}** — {one-line context}
...
```

## Style Rules

- The commits table is facts only. No editorializing in the description column — use the actual commit message, trimmed to one line.
- Number commits sequentially per project (1, 2, 3), not globally.
- The assessment section is where opinions go. Be direct. If a project is stalled, say it's stalled and say what that means. If something shipped, say whether it actually matters.
- Open items are actionable. Each one should be something a person could pick up tomorrow. No vague observations — "dashboard needs work" is bad, "TASK-executor-api-and-seed.md ready for Code in VybePM-v2" is good.
- No emoji. No bullet points in the assessment. No headers beyond the defined sections.
- Keep it short. The whole report should fit on one screen.
- When both git commits and VybePM task data are available, the assessment should cross-reference them.
