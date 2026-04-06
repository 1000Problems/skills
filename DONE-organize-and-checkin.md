# TASK: Organize Skills repo structure and check in

## Context

The Skills repo has been scaffolded by Cowork with flat files. Code needs to organize them into the proper directory structure and push to GitHub.

## Step 1: Create directory structure

```bash
cd ~/1000Problems/Skills
mkdir -p cowork code shared
```

## Step 2: Move VybeAll skill into place

```bash
mkdir -p code/vybeall
mv vybeall-SKILL.md code/vybeall/SKILL.md
```

## Step 3: Rename gitignore

```bash
mv gitignore.txt .gitignore
```

## Step 4: Install VybeAll as a global Code skill

```bash
mkdir -p ~/.claude/skills/vybeall
cp code/vybeall/SKILL.md ~/.claude/skills/vybeall/SKILL.md
```

This makes `/vybeall` available in any project directory.

## Step 5: Also install in 1000Problems root

```bash
mkdir -p ~/1000Problems/.claude/skills/vybeall
cp code/vybeall/SKILL.md ~/1000Problems/.claude/skills/vybeall/SKILL.md
```

## Step 6: Commit and push

```bash
cd ~/1000Problems/Skills
git add -A
git config user.email "angelsbadillos@gmail.com"
git config user.name "1000Problems"
git commit -m "Organize repo structure + add VybeAll skill"
git push origin main
```

## Step 7: Verify

1. `ls code/vybeall/SKILL.md` — exists
2. `ls ~/.claude/skills/vybeall/SKILL.md` — exists  
3. `ls ~/1000Problems/.claude/skills/vybeall/SKILL.md` — exists
4. `git log --oneline -3` — shows both commits
5. Check GitHub: `https://github.com/1000Problems/skills` shows the organized structure

## DO NOT

- Do NOT modify the content of any SKILL.md file — just move them
- Do NOT remove CLAUDE.md or README.md
- Do NOT create any new skills — only organize what's already here
