# Skills

Central skill repository for the 1000Problems portfolio. Every Cowork and Claude Code skill lives here as a self-contained folder, versioned in git, and installable into any project.

## Tech Stack

- **Format**: Markdown (SKILL.md files with YAML frontmatter)
- **Hosting**: GitHub (1000Problems/skills)
- **Runtime**: None — skills are static instruction files consumed by Cowork and Claude Code
- **Language**: English prose + embedded code examples

## Project Structure

```
Skills/
├── CLAUDE.md                     -- This file
├── README.md                     -- Repo overview
├── .gitignore
├── cowork/                       -- Skills for Cowork (desktop agent)
│   ├── 1000p-new-project/
│   │   └── SKILL.md
│   ├── 1000p-deploy-v2/
│   │   ├── SKILL.md
│   │   └── references/
│   │       └── infrastructure.md
│   ├── daily-report/
│   │   └── SKILL.md
│   └── ...
├── code/                         -- Skills for Claude Code (terminal agent)
│   ├── vybego/
│   │   └── SKILL.md
│   └── ...
└── shared/                       -- Skills usable by both
    └── ...
```

## Skill File Format

Every skill is a folder with at minimum a `SKILL.md`. The file uses YAML frontmatter:

```markdown
---
name: skill-name
description: "One-line description used for trigger matching. Include trigger phrases."
---

# Skill Title

Instructions for the agent...
```

### Frontmatter Fields

| Field | Required | Description |
|-------|----------|-------------|
| `name` | Yes | Lowercase hyphenated identifier |
| `description` | Yes | Trigger description — include phrases that should activate this skill |

### Optional: references/ directory

For skills that need supporting data (infrastructure credentials, templates, examples), add a `references/` subdirectory:

```
my-skill/
├── SKILL.md
└── references/
    ├── infrastructure.md
    ├── template.html
    └── examples.json
```

The SKILL.md should reference these files with relative paths.

## Conventions

1. **One skill per folder** — never put multiple SKILL.md files in the same directory
2. **Skill names are kebab-case** — `1000p-new-project`, not `1000pNewProject`
3. **Descriptions include trigger phrases** — the description field is what Cowork uses to decide when to activate a skill, so pack it with relevant phrases
4. **No secrets in SKILL.md** — credentials go in `references/infrastructure.md` which is gitignored if sensitive, or reference env vars
5. **Skills are self-contained** — a skill should work without reading other skills (cross-reference is OK, dependency is not)
6. **Cold start test** — if an agent reads this skill for the first time with no prior context, can it execute the full workflow? If not, add more detail.

## Installation

Skills are installed by copying the folder into a project's `.claude/skills/` directory:

```bash
# Install a Cowork skill
cp -r ~/1000Problems/Skills/cowork/1000p-new-project ~/1000Problems/ytcombinator/.claude/skills/

# Install a Code skill
cp -r ~/1000Problems/Skills/code/vybego ~/1000Problems/Vybe/.claude/skills/
```

After copying, the skill appears in the agent's available skills list on next session start.

## Adding a New Skill

1. Create a folder under the appropriate category (`cowork/`, `code/`, or `shared/`)
2. Write `SKILL.md` with proper YAML frontmatter
3. Add `references/` directory if the skill needs supporting files
4. Test the skill by installing it in a project and running it
5. Commit and push to this repo

## VybePM Integration

- **Project slug**: `Skills`
- **Task types**: skill, documentation
- **Assignees**: angel, cowork

## Critical Notes

1. **This is not a code project** — there is no build step, no dependencies, no runtime. Skills are plain text consumed by AI agents.
2. **The description field matters more than the content** — Cowork decides whether to trigger a skill based on the YAML description, not the body. Write descriptions like search keywords.
3. **Don't gitignore references/ globally** — most reference files are fine to commit. Only gitignore specific files that contain secrets (and note which ones in the SKILL.md).
4. **Skills evolve** — when a skill's workflow changes, update the SKILL.md in this repo AND in every project that has it installed. The installed copies are independent — there's no auto-sync.
