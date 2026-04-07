# Skills

Central repository of skills for the 1000Problems portfolio. Skills are instruction files that tell AI agents (Cowork or Claude Code) how to execute specific workflows.

## Structure

```
Skills/
├── cowork/                              -- Cowork skills + scheduled tasks
│   ├── 1000p-new-project.md             -- Scaffold a new project end-to-end
│   ├── 1000p-deploy-v2.md              -- Deploy to Vercel + homepage
│   ├── 1000p-deploy-azure.md           -- Deploy to Azure (legacy)
│   ├── daily-report.md                  -- Portfolio daily report
│   ├── scheduled-vybepm-reviewer.md     -- [Scheduled] Code review + deploy (4x/day)
│   └── scheduled-daily-report.md        -- [Scheduled] Daily portfolio report (4am)
├── code/                                -- Claude Code skills
│   ├── vybeall/                         -- Portfolio-wide task scanner
│   │   └── SKILL.md
│   ├── vybeforever/                     -- Continuous task executor (loops every 4h)
│   │   └── SKILL.md
│   └── vybego.md                        -- Autonomous task executor
└── shared/                              -- Reference files used by multiple skills
    └── infrastructure.md                -- Accounts, tokens, naming conventions
```

## Cowork Skills

Interactive skills that run in Cowork (desktop app). Triggered by conversation or slash commands.

| Skill | Description |
|-------|-------------|
| `1000p-new-project` | Scaffold a new project: directory, GitHub repo, CLAUDE.md, VybePM registration |
| `1000p-deploy-v2` | Deploy to Vercel: Next.js scaffold, landing page, homepage card, custom domain |
| `1000p-deploy-azure` | Deploy to Azure App Service (legacy path for older projects) |
| `daily-report` | Generate the daily portfolio report: commits, tasks, assessment, open items |

## Code Skills

Skills that run in Claude Code (CLI). Executed autonomously or via VybePM task pickup.

| Skill | Description |
|-------|-------------|
| `vybego` | Pull tasks from VybePM API, execute them, report completion |
| `vybeall` | Scan all projects for pending tasks, execute across the portfolio |
| `vybeforever` | Like vybeall but runs continuously — executes a full portfolio sweep then sleeps 4 hours, forever |

## Scheduled Tasks

Cowork scheduled tasks that run automatically. Filed under `cowork/` with `scheduled-` prefix and `type: scheduled-task` in frontmatter.

| Task | Schedule | Description |
|------|----------|-------------|
| `vybepm-reviewer` | 4x/day (8:30, 12:30, 4:30, 8:30) | Review tasks, approve/kick back, commit, push, deploy |
| `daily-portfolio-report` | Daily at 4am | Git commits + VybePM tasks + deploy status → assessment report |

Both scheduled tasks dynamically discover projects by listing `/Users/angel/1000Problems/` — no hardcoded project lists.

## Installing a skill

**Cowork:** Copy into the project's `.claude/skills/` directory:
```bash
mkdir -p ~/1000Problems/ytcombinator/.claude/skills/1000p-new-project
cp ~/1000Problems/Skills/cowork/1000p-new-project.md ~/1000Problems/ytcombinator/.claude/skills/1000p-new-project/SKILL.md
```

**Code:** Copy into the project's `.claude/skills/` directory:
```bash
mkdir -p ~/1000Problems/Vybe/.claude/skills/vybego
cp ~/1000Problems/Skills/code/vybego.md ~/1000Problems/Vybe/.claude/skills/vybego/SKILL.md
```

## Part of [1000Problems](https://www.1000problems.com)
