---
name: 1000p-deploy-v2
description: "Deploy a new 1000Problems sub-project end-to-end: scaffold a Next.js app, write a CLAUDE.md handoff doc, push to GitHub under the 1000Problems org, deploy to Vercel, add it to the 1000Problems homepage, and register in VybePM. Use this skill whenever the user says 'new project', 'deploy a new app', 'create a new 1000Problems project', 'spin up a new site', or mentions deploying anything to the 1000Problems platform. Also trigger when the user asks to add an app to the homepage, set up a subdomain, or do anything related to the 1000Problems deployment pipeline."
---

# 1000Problems Project Deployment (Vercel)

This skill walks through deploying a sub-project under the 1000Problems umbrella — from empty folder to live site on Vercel with a card on the homepage. Stack: Next.js + Vercel + Neon PostgreSQL.

## Infrastructure context

Read `shared/infrastructure.md` for full details on accounts, credentials, naming conventions, and the current project roster. Key points:

- **GitHub account**: `1000Problems`
- **Vercel team**: `1000problems-projects`
- **Vercel account email**: `angelsbadillos@gmail.com` (critical — git author must match)
- **Database**: Neon PostgreSQL (homepage app)
- **Homepage repo**: `1000Problems/1000problems-next` (Next.js App Router on Vercel)

## The deployment sequence

8 phases, in order.

### Phase 1: Scaffold the Next.js project

```bash
npx create-next-app@latest <project-name> \
  --typescript --tailwind --eslint --app \
  --import-alias "@/*" --use-npm
```

Add database dependency if needed: `npm install @neondatabase/serverless`

### Phase 2: Write the CLAUDE.md handoff document

Include: project summary, tech stack, directory structure, database schema (full CREATE TABLEs), API endpoints (every route), auth model, env vars, state machines, critical notes. Detailed enough for Code to implement the entire backend from scratch.

### Phase 3: Build a landing page

`src/app/page.tsx` — dark gradient background, project name, SVG icon, 3 feature cards, tech badges, "A 1000Problems project" footer. Also create `public/<project>-logo.svg` (320x192).

### Phase 4: Push to GitHub

Repo MUST be under `1000Problems` account. Git author email MUST be `angelsbadillos@gmail.com`.

```bash
git init && git config user.email "angelsbadillos@gmail.com" && git config user.name "1000Problems"
git add -A && git commit -m "Initial commit: scaffolding + landing page"
```

Create repo via API: `POST https://api.github.com/user/repos`
Push: `git remote add origin https://github.com/1000Problems/<project>.git && git push -u origin main`

### Phase 5: Deploy to Vercel

```bash
npx vercel deploy --token <VERCEL_TOKEN> --yes --prod --scope 1000problems-projects
```

CRITICAL: Git author email must match Vercel account email (`angelsbadillos@gmail.com`). Hobby plan blocks mismatches.

### Phase 6: Add to the 1000Problems homepage

1. Clone `1000problems-next`
2. Copy logo SVG to `public/images/`
3. Add to `staticApps` array in `src/app/page.tsx` (insert at TOP)
4. INSERT into Neon `applications` table
5. Commit, push, auto-deploys

### Phase 7: Register in VybePM

Every project gets tracked in VybePM. The API lives at `https://vybe.1000problems.com`.

```bash
curl -X POST https://vybe.1000problems.com/api/projects \
  -H "Content-Type: application/json" \
  -d '{"name":"<project-name>","display_name":"<ProjectName>","description":"<one-liner>","status":"active"}'
```

Also update the vybeforever project registry (`Skills/code/vybeforever/SKILL.md`):
1. Add the project slug to the appropriate tier (A=buildable Next.js, B=native/iOS, C=non-code)
2. Add a row to the Project Registry table: `| <ProjectName> | ~/1000Problems/<project-name> | <stack> | <tier> |`

Commit and push the Skills repo after updating.

### Phase 8: Custom domain (optional)

Add `<project>.1000problems.com` in Vercel, add CNAME in GoDaddy → `cname.vercel-dns.com`, SSL auto-provisions.

## Verification checklist

1. Landing page loads at Vercel URL (HTTPS)
2. Homepage shows new card with logo
3. Card click navigates to new project
4. Search finds it by name
5. Project exists in VybePM (`GET https://vybe.1000problems.com/api/projects`)

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| "Git author must have access" | Amend commit with `--author="1000Problems <angelsbadillos@gmail.com>"` |
| Scope error on Vercel CLI | Verify `--scope 1000problems-projects`, check token |
| Card not showing | Check both static array AND Neon DB |
