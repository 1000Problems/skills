# TASK: Install VybeForever Skill

**Priority:** high
**Assignee:** claude-code

## What

Move the VybeForever skill into proper directory structure and install it.

## Steps

1. **Create directory and move file:**
   ```bash
   mkdir -p /Users/angel/1000Problems/Skills/code/vybeforever
   mv /Users/angel/1000Problems/Skills/code/vybeforever-SKILL.md /Users/angel/1000Problems/Skills/code/vybeforever/SKILL.md
   ```

2. **Delete the placeholder garbage file:**
   ```bash
   rm /Users/angel/1000Problems/Skills/code/vybeforever-placeholder
   ```

3. **Install to Claude Code skills directory:**
   ```bash
   mkdir -p /Users/angel/1000Problems/.claude/skills/vybeforever
   cp /Users/angel/1000Problems/Skills/code/vybeforever/SKILL.md /Users/angel/1000Problems/.claude/skills/vybeforever/SKILL.md
   ```

4. **Commit and push the Skills repo:**
   ```bash
   cd /Users/angel/1000Problems/Skills
   git add code/vybeforever/SKILL.md README.md TASK-vybeforever-install.md
   git commit -m "Add vybeforever skill — continuous portfolio executor (4h loop)"
   git push origin main
   ```

5. **Delete this TASK file after completion:**
   ```bash
   rm /Users/angel/1000Problems/Skills/TASK-vybeforever-install.md
   git add -A && git commit -m "Remove completed TASK" && git push
   ```

## Context

VybeForever is a copy of VybeAll that runs in an infinite loop — full portfolio sweep, then sleep 4 hours, repeat. The skill content is already written at `code/vybeforever-SKILL.md` but couldn't be placed in the proper `vybeforever/` subdirectory due to GitMCP's depth limitation. Code needs to reorganize it.

## Done When

- `Skills/code/vybeforever/SKILL.md` exists with correct content
- `Skills/code/vybeforever-SKILL.md` (flat file) is gone
- `Skills/code/vybeforever-placeholder` is gone
- Skill is installed at `~/.claude/skills/vybeforever/SKILL.md`
- Changes committed and pushed
