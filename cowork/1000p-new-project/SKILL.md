---
name: 1000p-new-project
description: "Scaffold a new 1000Problems project from an idea: create directory, GitHub repo, CLAUDE.md, VybePM registration, and git init — everything needed so Code can start building immediately. Use this skill whenever the user says 'new project', 'I have an idea for a project', 'spin up a new project', 'create a new app', or mentions wanting to start something new under the 1000Problems umbrella. Also trigger when the user wants to add a project to the ecosystem, bootstrap a repo, or get a new idea production-ready for Code."
---

# New 1000Problems Project

This skill takes a project idea from zero to build-ready — a real directory on disk, a GitHub repo, a CLAUDE.md that Code can execute against, and VybePM registration so tasks flow through the pipeline. After this skill completes, Code can open the project and start building with zero setup.

This is NOT the deployment skill. Deployment (Vercel, landing page, homepage card) happens later via `1000p-deploy-v2`. This skill handles the birth of a project — everything before the first line of app code gets written.

## Before you start

Gather these details from the user. Most can be inferred from a short conversation, but confirm before proceeding:

1. **Project name** — PascalCase for the directory (e.g., `YTCombinator`), lowercase-hyphenated for the GitHub repo (e.g., `ytcombinator`)
2. **One-liner** — What does this project do, in one sentence?
3. **Tech stack** — Framework, language, database, hosting target. Default to Next.js + Vercel + Neon unless the user specifies otherwise. For iOS apps, SwiftUI + SwiftData. For macOS, SwiftUI + AVFoundation.
4. **Project type** — Web app, iOS app, macOS app, API, CLI tool, creative assets directory
5. **Key features** — 3-5 bullet points describing what the project will do

If the user gives a rough idea like "a YouTube channel manager," that's enough — fill in reasonable defaults and confirm.

## Phase 1: Create the directory

All 1000Problems projects live at `/Users/angel/1000Problems/`. Use `git_init` to create the directory and initialize git in one step, then write files with `fs_write`:

```
/Users/angel/1000Problems/{ProjectName}/
├── CLAUDE.md          (Phase 2)
├── README.md          (this phase)
└── gitignore          (this phase — rename to .gitignore via Code)
```

**README.md**:
```markdown
# {ProjectName}

{one-liner description}

## Status

Scaffolding — no app code yet. See CLAUDE.md for the build spec.

## Part of [1000Problems](https://www.1000problems.com)
```

**gitignore** (fs_write blocks dotfiles — rename to .gitignore via Code):

For Next.js/Node: `node_modules/`, `.next/`, `.env`, `.env.local`, `.vercel`
For Swift: `.build/`, `DerivedData/`, `*.xcuserdata`, `.swiftpm/`
For Python: `__pycache__/`, `.venv/`, `*.pyc`, `.env`

## Phase 2: Write the CLAUDE.md

This is the most important file. It's Code's instruction manual — detailed enough that Code can build the entire project without asking questions.

Structure:

```markdown
# {ProjectName}

{one-liner description}

## Tech Stack

- **Framework**: {framework}
- **Language**: {language}
- **Database**: {database or "None"}
- **Hosting**: {Vercel / Azure / App Store / etc.}
- **Auth**: {auth approach}

## Project Structure

{directory tree showing where everything goes}

## Database Schema

{CREATE TABLE statements if applicable}

## API Endpoints

{Method | Path | Description | Auth}

## Key Features

{numbered list}

## Environment Variables

| Variable | Description |
|----------|-------------|

## VybePM Integration

- **Project slug**: `{ProjectName}`
- **Task types**: {feature, bug, design, content}
- **Assignees**: angel, cowork

## Critical Notes

{gotchas, design decisions, constraints}
```

For iOS/macOS apps, replace API Endpoints with Views and Models. For creative/asset directories, simplify to folder structure and conventions.

Cold start test: if Code opens this project for the first time with no other context, can it start building immediately?

## Phase 3: Create the GitHub repo

Create a repo under the **1000Problems** GitHub organization. Repo name: lowercase with hyphens.

1. Create via GitHub API:
   ```
   POST https://api.github.com/orgs/1000Problems/repos
   Authorization: token {GITHUB_PAT from shared/infrastructure.md}
   {"name": "{project-name}", "private": false, "description": "{one-liner}"}
   ```

2. Git is initialized from Phase 1. Use git MCP tools:
   - `git_add` all files
   - `git_commit` "Initial scaffold: CLAUDE.md + README"
   - `git_remote` add origin
   - `git_push` origin main

Git author email MUST be `angelsbadillos@gmail.com` for Vercel compatibility.

## Phase 4: Register in VybePM

**Option A — API call (if Executor API is live):**
```
POST https://vybepm-v2.vercel.app/api/projects
{"name": "{ProjectName}", "slug": "{ProjectName}", "description": "{one-liner}",
 "tech_stack": "{stack}", "github_repo": "1000Problems/{project-name}", "is_active": true}
```

**Option B — Update seed script:**
Add entry to `/Users/angel/1000Problems/VybePM-v2/scripts/seed.ts`, then user runs `npx tsx scripts/seed.ts`.

## Phase 5: Verify

1. `fs_stat` — directory exists
2. `fs_read` — CLAUDE.md passes cold start test
3. GitHub repo exists
4. `git_status` — clean working tree
5. VybePM slug registered

## After completion

> **{ProjectName} is scaffolded and ready.**
> - Directory: `/Users/angel/1000Problems/{ProjectName}`
> - GitHub: `github.com/1000Problems/{project-name}`
> - VybePM slug: `{ProjectName}`
>
> Next: Open in Code to build, then `1000p-deploy-v2` to deploy.

## Not in scope

No app code, no deployment, no database setup, no domain config.

## VybePM Color Palette

| Project | Color |
|---------|-------|
| AnimationStudio | #FF6B6B |
| VybePM-v2 | #4ECDC4 |
| Vybe | #45B7D1 |
| GitMCP | #96CEB4 |
| ytcombinator | #FFEAA7 |
| RubberJoints-iOS | #DDA0DD |
| 1000Problems | #FF9FF3 |
| prompts | #A0A0A0 |
| VoiceQ | #74B9FF |
| Animation | #FD79A8 |
| Skills | #B8E986 |
