# TASK: Create setup/ Folder and Clean Up Root Stray Files

## Context

The Skills repo needs a `setup/` directory that holds files that belong on the
host machine at `~/1000Problems/` but are not part of any project repo. This
folder is the source of truth for machine migration.

There are also 3 stray files at `~/1000Problems/` root that are duplicate copies
of the lightrag skill and should be deleted.

## Requirements

### 1. Create setup/ directory structure

Move these files from Skills root into `Skills/setup/`:

```
Skills/setup-root-CLAUDE.md       → Skills/setup/CLAUDE.md
Skills/setup-reindex-lightrag.sh  → Skills/setup/reindex-lightrag.sh
Skills/MACHINE-SETUP.md           → Skills/setup/MACHINE-SETUP.md
```

Make `reindex-lightrag.sh` executable:
```bash
chmod +x Skills/setup/reindex-lightrag.sh
```

### 2. Delete stray files at ~/1000Problems/ root

These are orphaned duplicate copies of lightrag skill files that were written
during a failed GitMCP write attempt. Delete them:

```
~/1000Problems/SETUP.md
~/1000Problems/SKILL.md
~/1000Problems/lightrag-skill/       (entire directory)
~/1000Problems/test-write.txt
```

Use `rm -f` for files and `rm -rf` for the lightrag-skill/ directory.
Confirm each exists before deleting.

### 3. Commit both changes

Commit message: `add setup/ folder with migration checklist and root files`

## Do Not Change

- `Skills/cowork/lightrag/SKILL.md` and `SETUP.md` — real lightrag skill, not these copies
- Any project CLAUDE.md files
- `~/1000Problems/CLAUDE.md` — the live root CLAUDE.md (different from the Skills backup copy)
- `~/1000Problems/reindex-lightrag.sh` — the live script on disk
- `~/1000Problems/secrets.env` — never touch

## Acceptance Criteria

- [ ] `Skills/setup/CLAUDE.md` exists and matches the content of `~/1000Problems/CLAUDE.md`
- [ ] `Skills/setup/reindex-lightrag.sh` exists, is executable, matches live script
- [ ] `Skills/setup/MACHINE-SETUP.md` exists with machine migration checklist
- [ ] `Skills/MACHINE-SETUP.md`, `Skills/setup-root-CLAUDE.md`, `Skills/setup-reindex-lightrag.sh` are gone from Skills root
- [ ] `~/1000Problems/SETUP.md`, `SKILL.md`, `lightrag-skill/`, `test-write.txt` are deleted
- [ ] All changes committed and pushed to Skills repo

## Verification

```bash
# Confirm setup/ structure
ls ~/1000Problems/Skills/setup/

# Confirm stray files gone
ls ~/1000Problems/SETUP.md 2>&1        # should: No such file or directory
ls ~/1000Problems/lightrag-skill/ 2>&1  # should: No such file or directory

# Confirm live files untouched
head -3 ~/1000Problems/CLAUDE.md
head -3 ~/1000Problems/reindex-lightrag.sh
```
