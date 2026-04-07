# TASK: Install codeTasks skill into proper directory

> Move the codeTasks skill file into the correct cowork skill directory structure and commit.

## Context

The codeTasks skill was written by Cowork but couldn't be placed directly into `cowork/code-tasks/` due to GitMCP path restrictions. It's sitting at the repo root as `codeTasks-SKILL.md` and needs to be moved into the proper directory structure.

## Requirements

1. Create directory `cowork/code-tasks/`
2. Move `codeTasks-SKILL.md` from repo root to `cowork/code-tasks/SKILL.md`
3. Delete `codeTasks-SKILL.md` from repo root after the move
4. Update README.md to add code-tasks to the Cowork Skills table
5. Commit and push

## Implementation Notes

- The README.md has a table under "Cowork Skills" — add a row for code-tasks:
  - Name: `code-tasks`
  - Description: "Generate structured TASK spec files for Claude Code handoff"
  - Trigger: "write a task for code", "spec this for code", "hand this off to code"

## Do Not Change

- All existing skill directories under `cowork/` and `code/`
- `shared/infrastructure.md`
- Any other SKILL.md files

## Acceptance Criteria

- [ ] `cowork/code-tasks/SKILL.md` exists with full content
- [ ] `codeTasks-SKILL.md` no longer exists at repo root
- [ ] README.md includes code-tasks entry
- [ ] `git status` shows clean working tree after commit

## Verification

1. Verify `cowork/code-tasks/SKILL.md` has YAML frontmatter with `name: codeTasks`
2. Verify repo root has no leftover `codeTasks-SKILL.md`
3. Push to origin
