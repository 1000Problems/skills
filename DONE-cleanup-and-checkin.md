# TASK: Clean up Skills repo and check in

## Context

Cowork populated the Skills repo with all custom skills from the 1000Problems portfolio — Cowork skills, Code skills, and scheduled tasks. Files are written but need cleanup before final commit + push.

## Steps

### 1. Delete placeholder files

```bash
cd ~/1000Problems/Skills
rm -f cowork/placeholder cowork/1000p-new-project-placeholder code/placeholder shared/placeholder
```

### 2. Rename gitignore to .gitignore

```bash
mv gitignore .gitignore
```

### 3. Delete test file from root

```bash
rm -f ~/1000Problems/test-write.txt
```

### 4. Copy infrastructure.md to shared/

```bash
cp ~/1000Problems/ytcombinator/.claude/skills/1000p-deploy-v2/references/infrastructure.md shared/infrastructure.md
```

**SECURITY CHECK:** If `shared/infrastructure.md` contains tokens or PATs, add it to `.gitignore` since the repo may be public.

### 5. Delete old TASK files

```bash
rm -f TASK-organize-and-checkin.md
rm -f TASK-cleanup-and-checkin.md
```

### 6. Verify the final structure

```
Skills/
├── .gitignore
├── CLAUDE.md
├── README.md
├── cowork/
│   ├── 1000p-deploy-azure.md
│   ├── 1000p-deploy-v2.md
│   ├── 1000p-new-project.md
│   ├── daily-report.md
│   ├── scheduled-daily-report.md
│   └── scheduled-vybepm-reviewer.md
├── code/
│   ├── vybeall/
│   │   └── SKILL.md
│   └── vybego.md
└── shared/
    └── infrastructure.md
```

### 7. Commit and push

```bash
git add -A
git commit -m "Complete skills repo: 4 cowork skills, 2 code skills, 2 scheduled tasks"
git push origin main
```

### 8. Install cowork skills to ytcombinator

```bash
for skill in daily-report 1000p-deploy-v2 1000p-deploy-azure 1000p-new-project; do
  mkdir -p ~/1000Problems/ytcombinator/.claude/skills/${skill}
  cp ~/1000Problems/Skills/cowork/${skill}.md ~/1000Problems/ytcombinator/.claude/skills/${skill}/SKILL.md
done
```

## Done when

- [ ] No placeholder files remain
- [ ] .gitignore properly named
- [ ] shared/infrastructure.md exists (gitignored if secrets)
- [ ] 8 skill files in repo (4 cowork interactive, 2 cowork scheduled, 2 code)
- [ ] Pushed to github.com/1000Problems/skills
- [ ] Cowork interactive skills installed to ytcombinator/.claude/skills/
