---
name: lightrag
description: "Manage the LightRAG knowledge graph — index project documents, query cross-project knowledge, and check system status. Use this skill whenever the user says 'index', 'reindex', 'query lightrag', 'search the knowledge graph', 'lightrag', 'update the graph', 'what does the graph know about', or wants to feed documents into the memory system. Also trigger when the user mentions 'deep memory', 'cross-project search', or asks a question that would benefit from searching across all project specs and docs at once."
---

# LightRAG — Knowledge Graph Memory Layer

You are managing LightRAG, a graph-based RAG system that serves as the deep memory layer for the 1000Problems portfolio. It runs as a Docker container on Angel's Mac and stores a knowledge graph of entities and relationships extracted from project documents.

This is the **deep memory** complement to `.auto-memory` (which handles fast-access preferences and workflow rules). LightRAG handles cross-project retrieval, complex relationship queries, and large-scale document search.

## Architecture

```
Docker container "lightrag" on localhost:9621
├── LLM: OpenAI gpt-4o-mini (entity extraction + Q&A)
├── Embeddings: OpenAI text-embedding-3-large
├── Storage: local JSON + NetworkX graph
└── API: REST on port 9621
```

Both Cowork and Claude Code can interact with LightRAG:
- **Claude Code**: direct `curl` calls to `localhost:9621` from terminal
- **Cowork**: writes task files via `fs_write`, Code or a runner script executes them

## How This Skill Works

Cowork's sandbox cannot hit localhost. So this skill uses a **file-based task protocol** (same pattern as the animate skill's exchange protocol).

1. Cowork writes a task JSON to `~/1000Problems/.lightrag/tasks/`
2. A runner script (or Claude Code) picks up the task, calls the LightRAG API, writes the response
3. Results land in `~/1000Problems/.lightrag/results/{task-id}.json`
4. Cowork reads results via `fs_read`

The runner script is `~/1000Problems/.lightrag/runner.sh`. It can be invoked manually (`bash runner.sh`) or wired to the Cowork `schedule` skill for automatic polling.

## Writing Task Files

Use `fs_write` to create task files. Name them `{YYYYMMDD-HHmmss}-{action}.json`.

### Index — Feed Documents Into the Graph

```json
{
  "action": "index",
  "documents": [
    {
      "path": "~/1000Problems/VybePM-v2/CLAUDE.md",
      "label": "VybePM build instructions"
    },
    {
      "path": "~/1000Problems/ytcombinator/CLAUDE.md",
      "label": "YTCombinator project spec"
    }
  ]
}
```

Use absolute paths with `~` (the runner expands them). The `label` helps identify the document in the graph later.

### Query — Search the Knowledge Graph

```json
{
  "action": "query",
  "text": "Which projects use Neon PostgreSQL and what are their database schemas?",
  "mode": "hybrid"
}
```

Search modes:
- `naive` — vector similarity only (fast, shallow)
- `local` — entity neighborhood search (specific facts about a named thing)
- `global` — community-level summaries (broad patterns, comparisons)
- `hybrid` — local + global combined (best quality, use by default)

### Status — Health Check

```json
{
  "action": "status"
}
```

Returns container state, document count, entity count, and relationship count.

## Reading Results

Results appear at `~/1000Problems/.lightrag/results/{same-filename-as-task}.json`:

```json
{
  "task": "20260406-191500-query.json",
  "status": "ok",
  "result": "..."
}
```

If `status` is `"error"`, the `result` field contains the error message. Common errors:
- `"connection refused"` — Docker container not running. Tell Angel to run `docker start lightrag`.
- `"empty graph"` — No documents indexed yet. Run an index task first.

## What to Index

Durable architectural knowledge — things that change rarely and define how projects work:

| File | Projects | Purpose |
|------|----------|---------|
| `CLAUDE.md` | All active projects | Architecture, build rules, constraints |
| `SPEC.md` | VybePM-v2 | Data model, API, state machines |
| `brand-reference.md` | AnimationStudio | Characters, tone, episode structure |
| `ANTI-SLOP.md` | AnimationStudio | Creative policy |
| `conventions.md` | AnimationStudio | SVG naming, file layout |

### Do NOT Index

- `.auto-memory/` files — separate system, not graph material
- Source code files — specs are the source of truth, code changes too fast
- Media files — text-only system
- `.env` or `secrets.env` — never

### Re-index When

- A CLAUDE.md or SPEC.md gets a real update (not typos)
- A new project joins the portfolio
- Angel explicitly asks to refresh

## Index All Projects (Template)

To do a full re-index of the portfolio, write this task:

```json
{
  "action": "index",
  "documents": [
    {"path": "~/1000Problems/1000Problems/CLAUDE.md", "label": "1000Problems homepage"},
    {"path": "~/1000Problems/VybePM-v2/CLAUDE.md", "label": "VybePM build instructions"},
    {"path": "~/1000Problems/VybePM-v2/SPEC.md", "label": "VybePM full specification"},
    {"path": "~/1000Problems/ytcombinator/CLAUDE.md", "label": "YTCombinator project spec"},
    {"path": "~/1000Problems/AnimationStudio/CLAUDE.md", "label": "AnimationStudio build instructions"},
    {"path": "~/1000Problems/AnimationStudio/brand-reference.md", "label": "PopiPlay brand reference"},
    {"path": "~/1000Problems/AnimationStudio/ANTI-SLOP.md", "label": "Anti-slop creative policy"},
    {"path": "~/1000Problems/GitMCP/CLAUDE.md", "label": "GitMCP project spec"},
    {"path": "~/1000Problems/KitchenInventory/CLAUDE.md", "label": "KitchenInventory project spec"},
    {"path": "~/1000Problems/RubberJoints-iOS/CLAUDE.md", "label": "RubberJoints iOS spec"}
  ]
}
```

Adjust this list as projects are added or archived. Skip `voiceq-api` (archived).

## Setup

If LightRAG is not installed yet, see `~/1000Problems/.lightrag/SETUP.md` for the one-time installation guide. Summary:

1. Install Docker Desktop (if not already present)
2. Clone LightRAG into `~/1000Problems/.lightrag/`
3. Create `.env` with `OPENAI_API_KEY`, model settings, storage config
4. Run `docker compose up -d`
5. Create `tasks/` and `results/` directories
6. Install the runner script
7. Do initial full index

The setup is a Claude Code task — give Code the SETUP.md and let it handle it.

## Cost Expectations

- **Indexing**: ~$0.01-0.05 per document (gpt-4o-mini for entity extraction + text-embedding-3-large)
- **Full portfolio index**: ~$0.10-0.50 one-time
- **Queries**: fractions of a cent each
- **Monthly at current scale**: under $2 if querying a few times per day

If costs spike, check whether something is re-indexing repeatedly.
