---
name: codeTasks
description: "Generate structured TASK spec files for Claude Code to execute. Use this skill whenever Cowork needs to hand off implementation work to Code — writing a feature spec, bug fix spec, refactor spec, or any TASK-*.md file. Also trigger when the user says 'write a task for code', 'spec this for code', 'hand this off to code', 'create a TASK file', or when a conversation reaches the point where implementation should be delegated to Code rather than done in Cowork."
---

# codeTasks — TASK Spec Generator for Claude Code

Cowork designs. Code implements. This skill ensures every handoff is airtight — Code (running Sonnet) gets exactly what it needs to execute without guessing, drifting, or breaking things it shouldn't touch.

## When to Use

- After discussing a feature/fix/refactor with Angel and agreeing on what to build
- When Angel says "write this up for code" or "spec this out"
- When the natural next step is implementation that belongs in Claude Code
- When creating VybePM tasks that will be picked up by the executor

## Step 1: Gather Context

Before writing the TASK file, collect this information (some may already be in the conversation):

1. **Project** — which repo? (ytcombinator, VybePM-v2, AnimationStudio, GitMCP, etc.)
2. **What** — what needs to be built/fixed/changed?
3. **Why** — what problem does this solve or what value does it add?
4. **Scope** — which files/components are in play?
5. **Protected areas** — what must NOT be touched? (Check the project's CLAUDE.md for global protected areas, then add task-specific ones)

If any of these are unclear from the conversation, ask Angel before writing.

## Step 2: Query LightRAG

Before writing the spec, query LightRAG for relevant cross-project context:

```bash
curl -X POST http://localhost:9621/query \
  -H "Content-Type: application/json" \
  -d '{"query": "architectural context for [feature] in [project]", "mode": "hybrid"}'
```

Use the results to:
- Identify patterns Code should follow (e.g., "VybePM uses sql tagged templates, not an ORM")
- Spot potential conflicts with other projects
- Reference related implementations Code can use as examples

## Step 3: Determine Verification Tier

Before writing the TASK, classify the project's verification capability:

**Tier A — Buildable from CLI:**
Next.js projects (ytcombinator, VybePM-v2, 1000Problems), Node.js projects (GitMCP).
Verification: `npm run build` output + `git diff --name-only` + acceptance criteria checks.

**Tier B — Not buildable from CLI:**
iOS/macOS projects (Vybe, AnimationStudio, KitchenInventory, RubberJoints-iOS).
Verification: `git diff --name-only` + file:line references per acceptance criterion + structured self-assessment. No build output required.

**Tier C — Non-code:**
Creative/config projects (Animation, Skills).
Verification: `git diff --name-only` + content review of modified files.

The tier determines what goes in the Verification and Completion Evidence sections of the TASK.

## Step 4: Write the TASK File

Create the file at: `~/1000Problems/{project}/TASK-{slug}.md`

Use this exact structure:

```markdown
# TASK: {Title}

> {One-line summary of what this task accomplishes}

## Context

{2-3 sentences explaining WHY this task exists. What problem does it solve?
What conversation or decision led to this? Link to the motivation, not just
the mechanics.}

## Requirements

{Numbered list of concrete, testable requirements. Each item should be
something Code can verify with a build, a test, or a visual check.}

1. ...
2. ...
3. ...

## Implementation Notes

{Technical guidance to prevent wrong turns. Include:
- Which files to create or modify (be specific with paths)
- Patterns to follow (reference existing code as examples)
- API contracts, data shapes, or type signatures
- Edge cases to handle
- LightRAG context if relevant (e.g., "VybePM executor API uses X-API-Key + X-Executor headers")}

## Do Not Change

{Explicit list of files, components, and patterns that are OFF LIMITS.
Start with the project's global protected areas from CLAUDE.md, then add
task-specific ones. This is the most important section for Sonnet — without
it, Code will "helpfully" refactor adjacent code.}

- `path/to/file.ts` — {reason it's protected}
- `path/to/other.ts` — {reason}
- {pattern or convention} — {reason}

## Acceptance Criteria

{How does the reviewer verify this is done correctly? Every criterion must
be binary — it either passes or it doesn't.}

- [ ] {For Tier A: `npm run build` passes with zero errors}
- [ ] {Visual or functional check}
- [ ] {Specific behavior that must work}
- [ ] `git diff --name-only` shows changes ONLY in files listed under Implementation Notes

## Verification

{What Code must do before setting the task to `review` in VybePM.}

### For Tier A (buildable) projects:
1. Run the build: `npm run build` — capture output
2. Run `git diff --name-only` — verify only in-scope files changed
3. Test each acceptance criterion and record the evidence
4. If the project has tests, run them

### For Tier B (iOS/macOS) projects:
1. Run `git diff --name-only` — verify only in-scope files changed
2. For each acceptance criterion, provide file:line references showing where the requirement is met
3. Review your own changes for obvious issues (force unwraps, hardcoded values, missing error handling)

### For Tier C (non-code) projects:
1. Run `git diff --name-only` — verify only in-scope files changed
2. Review content of each modified file for completeness

## Completion Evidence (REQUIRED)

**Code must paste the following into VybePM task notes before setting status to `review`.**
The vybepm-reviewer will parse this format. Incomplete evidence = task rejected back to `in_progress`.

~~~
## Completion Evidence

### Scope Check
Files modified: (paste git diff --name-only output)
Files outside TASK scope: NONE | (list each with justification)

### Build (Tier A only)
(paste last 10 lines of npm run build output)
(or "N/A — iOS/macOS project" for Tier B)
(or "N/A — non-code project" for Tier C)

### Acceptance Criteria
1. [x] criterion text — EVIDENCE: (file:line, terminal output, or screenshot description)
2. [x] criterion text — EVIDENCE: (file:line, terminal output, or screenshot description)
3. [ ] criterion text — BLOCKED: (reason)

### Self-Review
- Did I modify files not listed in the TASK? No | Yes: (list + justification)
- Did I refactor or clean up adjacent code? No | Yes: (what and why)
- Did I add features not in the spec? No | Yes: (what and why)
~~~

## Rationalization Prevention

{Include this table verbatim in every TASK spec. It reminds Code what
discipline looks like.}

| If you're thinking... | Stop. The reality is: |
|-----------------------|-----------------------|
| "This file needs fixing too" | That's scope creep. Create a VybePM task, don't fix it inline. |
| "I'll refactor this while I'm here" | Unauthorized cleanup. The TASK spec didn't ask for it. |
| "The tests pass so it's done" | Tests passing ≠ task complete. Fill in the Completion Evidence. |
| "This is a trivial change" | Trivial changes break things. Follow the full verification flow. |
| "I'll add error handling to be safe" | Only add what the spec asks for. YAGNI. |
| "The adjacent component should match" | Stay in scope. If it should match, that's a new TASK. |
```

## Step 5: Review with Angel

Before committing, present the TASK spec to Angel for review. Key things to confirm:
- Is the scope right? (not too broad, not too narrow)
- Is the Do Not Change list complete?
- Are the acceptance criteria specific enough?
- Is the verification tier correct?

## Step 6: Commit and Push

After Angel approves (or says to proceed):

```
git add TASK-{slug}.md
git commit -m "add TASK spec: {short description}"
git push
```

## Style Rules for TASK Specs

- **Be specific, not vague.** "Add a NavBar component" is bad. "Extract a shared NavBar component from the duplicate nav code in dashboard/page.tsx (lines 644-672) and analyze/page.tsx (lines 389-414)" is good.
- **Include file paths.** Code running Sonnet doesn't have Opus-level inference. Tell it exactly where to look.
- **Show, don't describe.** If there's a data shape, type signature, or API contract, include the actual code/JSON — don't describe it in prose.
- **Reference existing patterns.** "Follow the same pattern as the ResearchBar component in dashboard/page.tsx" gives Code a concrete example to match.
- **Keep Do Not Change aggressive.** When in doubt, protect it. It's much easier to widen scope later than to undo damage from an over-eager refactor.
- **No ambiguity in acceptance criteria.** Every criterion should be binary — it either passes or it doesn't. No "should look good" or "should work well."

## Anti-Patterns to Avoid

- **Mega-TASKs** — If a spec has more than 5 requirements, split it into multiple TASK files. Code handles focused tasks well; sprawling ones cause drift.
- **Missing context** — Don't assume Code remembers previous conversations. Every TASK must be self-contained.
- **Implicit Do Not Change** — "Just the button" is not enough. List every file and component that should remain untouched.
- **No verification step** — Every TASK must include how to verify. If you can't define how to check it, the task isn't ready.
- **Freeform completion notes** — The Completion Evidence template is mandatory. "Updated the files" is not evidence.
