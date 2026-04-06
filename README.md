# Skills

Central repository of Cowork and Claude Code skills for the 1000Problems portfolio. Each skill is a folder containing a `SKILL.md` and optional `references/` directory.

Skills are installed by copying into a project's `.claude/skills/` directory, or referenced directly from this repo.

## Structure

```
Skills/
├── 1000p-new-project/       -- Scaffold a new 1000Problems project
│   └── SKILL.md
├── 1000p-deploy-v2/         -- Deploy to Vercel + homepage
│   ├── SKILL.md
│   └── references/
├── daily-report/             -- Portfolio-wide daily report
│   └── SKILL.md
└── ...
```

## Installation

Copy a skill folder into any project's `.claude/skills/`:

```bash
cp -r ~/1000Problems/Skills/<skill-name> ~/1000Problems/<project>/.claude/skills/
```

## Part of [1000Problems](https://www.1000problems.com)
