# Skills

Central repository of skills for the 1000Problems portfolio. Skills are instruction files that tell AI agents (Cowork or Claude Code) how to execute specific workflows.

## Structure

```
Skills/
├── cowork/           -- Skills for Cowork (desktop app, has MCP tools + computer use)
│   ├── 1000p-new-project/
│   │   └── SKILL.md
│   ├── 1000p-deploy-v2/
│   │   ├── SKILL.md
│   │   └── references/
│   └── ...
├── code/             -- Skills for Claude Code (CLI, has full filesystem + shell access)
│   ├── vybego/
│   │   └── SKILL.md
│   └── ...
└── shared/           -- Reference files used by both Cowork and Code skills
    └── infrastructure.md
```

## Cowork vs Code

| | Cowork | Code |
|---|--------|------|
| Runs in | Desktop app | Terminal CLI |
| File access | fs_write/fs_read via GitMCP | Direct filesystem |
| Shell access | Sandboxed Linux | Host shell |
| Git access | git MCP tools | Native git |
| Best for | Specs, reviews, orchestration, deployment | Implementation, testing, building |
| Install path | `~/.claude/skills/` in project dir | `~/.claude/skills/` in project dir |

## Installing a skill

**Cowork:** Copy the skill folder into the project's `.claude/skills/` directory:
```bash
cp -r Skills/cowork/1000p-new-project ~/1000Problems/ytcombinator/.claude/skills/
```

**Code:** Copy the skill folder into the project's `.claude/skills/` directory:
```bash
cp -r Skills/code/vybego ~/1000Problems/Vybe/.claude/skills/
```

## Part of [1000Problems](https://www.1000problems.com)
