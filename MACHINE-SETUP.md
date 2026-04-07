# New Machine Setup — 1000Problems Portfolio

Follow this checklist when setting up 1000Problems on a new machine. Everything
in this `setup/` folder belongs at specific locations on the host machine and
must be copied manually or by Claude Code.

---

## Step 1: Clone All Repos

```bash
mkdir -p ~/1000Problems && cd ~/1000Problems

git clone https://github.com/1000Problems/ytcombinator.git
git clone https://github.com/1000Problems/VybePM-v2.git
git clone https://github.com/1000Problems/AnimationStudio.git
git clone https://github.com/1000Problems/GitMCP.git
git clone https://github.com/1000Problems/Vybe.git
git clone https://github.com/1000Problems/RubberJoints-iOS.git
git clone https://github.com/1000Problems/KitchenInventory.git
git clone https://github.com/1000Problems/skills.git Skills
```

---

## Step 2: Copy Root-Level Files

These files live OUTSIDE any project repo, directly in `~/1000Problems/`.
They are version-controlled in this Skills repo under `setup/`.

```bash
SKILLS=~/1000Problems/Skills

# Root Claude Code instructions (mandatory — read on every Code session)
cp "$SKILLS/setup/CLAUDE.md" ~/1000Problems/CLAUDE.md

# LightRAG reindex script
cp "$SKILLS/setup/reindex-lightrag.sh" ~/1000Problems/reindex-lightrag.sh
chmod +x ~/1000Problems/reindex-lightrag.sh
```

---

## Step 3: Restore secrets.env

**Never committed to any repo.** Transfer this file securely from the old machine.

```bash
# Target location
~/1000Problems/secrets.env
```

Required keys:
- `VYBEPM_API_KEY` — VybePM v2 API key
- `GITHUB_PAT` — GitHub personal access token (issue a new one per machine)
- `VERCEL_TOKEN` — Vercel deploy token
- `DATABASE_URL` — Neon PostgreSQL connection string
- `OPENAI_API_KEY` — OpenAI API key

---

## Step 4: Install LightRAG

See `Skills/cowork/lightrag/SETUP.md` for the full guide. Summary:

```bash
mkdir -p ~/1000Problems/.lightrag/{tasks,results,data}
cd ~/1000Problems/.lightrag

# Create .env with OPENAI_API_KEY, LLM_MODEL=gpt-4o-mini,
# EMBEDDING_MODEL=text-embedding-3-large, PORT=9621
# (copy from old machine or recreate — do NOT commit this file)

docker compose up -d
curl -s http://localhost:9621/health   # should return OK

# Rebuild the knowledge graph from source docs
bash ~/1000Problems/reindex-lightrag.sh
```

The LightRAG graph data does NOT transfer between machines. The reindex script
rebuilds it from source docs — takes ~2 min, costs ~$0.50 in OpenAI API calls.

---

## Step 5: Configure Claude Code MCPs

Claude Code MCP config lives at `~/.claude/` (version-dependent).
Re-add MCPs manually on the new machine:

- **GitMCP** — `cd ~/1000Problems/GitMCP && npm install && npm start`
- **VybePM** (if applicable) — `https://vybepm-v2.vercel.app`

Save a copy of `~/.claude/` from the old machine as reference.

---

## Step 6: Recreate Scheduled Cowork Tasks

Scheduled tasks are stored in the Cowork app and do NOT transfer.
Recreate after installing Cowork on the new machine:

| Task | Schedule | Skill | Notes |
|------|----------|-------|-------|
| Calendar briefing | 4am daily | — | List 2 weeks of events, table format |
| YT keyword collect | 6am daily | — | Seed keywords + trigger GH Actions collect |
| VybePM reviewer | TBD | vybepm-reviewer | Opus model |
| Portfolio report | TBD | daily-report | All active projects |

Use the `schedule` skill in Cowork to recreate each one.

---

## Step 7: Start GitMCP

```bash
cd ~/1000Problems/GitMCP
npm install
npm start
```

Verify it's running before opening Claude Code.

---

## Step 8: Verify Everything

```bash
# LightRAG health
curl -s http://localhost:9621/health

# GitMCP running
ps aux | grep GitMCP

# Secrets loaded
source ~/1000Problems/secrets.env && echo $VYBEPM_API_KEY | head -c 8
```

---

## Cleanup Checklist for Old Machine

After confirming everything works on the new machine:

- [ ] Transfer `secrets.env` and `~/.lightrag/.env` via AirDrop or 1Password
- [ ] Delete `secrets.env` from old machine
- [ ] Delete `~/.lightrag/.env` from old machine
- [ ] Revoke old GitHub PAT, issue a new one for the new machine

---

## Root-Level File Inventory

These files should exist in `~/1000Problems/` but are NOT part of any project repo:

| File | Source in Skills | Notes |
|------|-----------------|-------|
| `CLAUDE.md` | `Skills/setup/CLAUDE.md` | Global Code instructions |
| `reindex-lightrag.sh` | `Skills/setup/reindex-lightrag.sh` | LightRAG index script |
| `secrets.env` | Manual transfer | API keys — never commit |
| `.lightrag/` | Manual setup | Docker + data dir |
| `lightrag-docs/` | Auto-created on first reindex | Drop inbox for new docs |
