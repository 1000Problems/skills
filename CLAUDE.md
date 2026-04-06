# Skills

Central repository of AI agent skills for the 1000Problems portfolio. Not a web app — this is a Git repo that stores skill files organized by runtime (Cowork vs Code).

## Tech Stack

- **Format**: Markdown (SKILL.md files with YAML frontmatter)
- **Hosting**: GitHub (1000Problems/skills)
- **Language**: None — skills are instruction documents, not executable code
- **Database**: None

## Project Structure

```
Skills/
├── CLAUDE.md
├── README.md
├── cowork/                    -- Skills that run in Cowork (desktop app)
│   ├── 1000p-new-project/     -- Scaffold a new project end-to-end
│   │   └── SKILL.md
│   ├── 1000p-deploy-v2/       -- Deploy to Vercel + homepage
│   │   ├── SKILL.md
│   │   └── references/
│   │       └── infrastructure.md
│   ├── 1000p-deploy/          -- Deploy to Azure (legacy)
│   │   ├── SKILL.md
│   │   └── references/
│   │       └── infrastructure.md
│   └── daily-report/          -- Portfolio-wide daily report
│       └── SKILL.md
├── code/                      -- Skills that run in Claude Code (CLI)
│   ├── vybego/                -- Pull tasks from VybePM and execute
│   │   └── SKILL.md
│   └── gitmcp-dev/            -- GitMCP development workflow
│       └── SKILL.md
└── shared/                    -- Reference files used by multiple skills
    └── infrastructure.md      -- Accounts, tokens, naming conventions
```

## Cowork vs Code: When to Use Which

**Cowork skills** have access to:
- GitMCP tools (fs_write, fs_read, fs_list, fs_stat) for host filesystem
- Git MCP tools (git_init, git_add, git_commit, git_push, etc.)
- Chrome MCP for browser automation
- Computer use for native app control
- Sandboxed Linux shell (NOT the host shell)

**Code skills** have access to:
- Full host filesystem (direct read/write)
- Host shell (bash, npm, npx, git, etc.)
- No browser or GUI access
- No MCP tools (unless configured in project)

**Rule of thumb:**
- If the skill writes specs, reviews code, orchestrates deployments, or talks to web APIs → Cowork
- If the skill writes application code, runs tests, builds, or needs native toolchains → Code

## Skill File Format

Every skill is a folder containing at minimum a `SKILL.md` with this structure:

```markdown
---
name: skill-name
description: "Trigger description — when should this skill activate?"
---

# Skill Title

{What this skill does and when to use it}

## Phase 1: ...
## Phase 2: ...
## Phase N: ...

## Verification
```

Optional: a `references/` subdirectory for supporting files (infrastructure docs, templates, examples).

## Installing Skills

Skills in this repo are the source of truth. To install into a project:

```bash
# Cowork skill → project's .claude/skills/
cp -r ~/1000Problems/Skills/cowork/1000p-new-project ~/1000Problems/ytcombinator/.claude/skills/

# Code skill → project's .claude/skills/
cp -r ~/1000Problems/Skills/code/vybego ~/1000Problems/Vybe/.claude/skills/
```

After copying, restart the Cowork session or Code instance to pick up the new skill.

## VybePM Integration

- **Project slug**: `Skills`
- **Task types**: skill, documentation
- **Assignees**: angel, cowork

## Critical Notes

1. **Skills are NOT code.** They're structured instructions. Don't add package.json, node_modules, or build steps.
2. **Don't duplicate infrastructure.md.** Keep one copy in `shared/` and reference it from skill files.
3. **Sensitive data** (tokens, PATs) lives in `shared/infrastructure.md` — this file should NOT be committed to a public repo. Add it to .gitignore or keep the repo private.
4. **Skill descriptions matter.** The YAML `description` field is what triggers automatic skill selection. Make it specific and include example phrases.
5. **Test before committing.** Run the skill manually in Cowork/Code to verify it works before pushing.
