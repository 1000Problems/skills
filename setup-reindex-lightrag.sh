#!/bin/bash
# reindex-lightrag.sh — Index all project docs into LightRAG knowledge graph
# Run: bash ~/1000Problems/reindex-lightrag.sh
# Requires: LightRAG running on localhost:9621, jq installed

set -e

LIGHTRAG="http://localhost:9621"
BASE="$HOME/1000Problems"
INBOX="$BASE/lightrag-docs"
INDEXED="$INBOX/indexed"

# ── Bootstrap inbox folder ────────────────────────────────────────────────────
if [ ! -d "$INBOX" ]; then
  mkdir -p "$INBOX" "$INDEXED"
  cat > "$INBOX/README.md" << 'EOF'
# LightRAG Docs Inbox

Drop any `.md` file here and it will be automatically indexed into the LightRAG
knowledge graph the next time vybeforever, vybego, or vybeall runs a cycle.

## How it works

1. Drop a `.md` file into this folder (Cowork or manual)
2. At the start of every vybeforever cycle, the executor runs reindex-lightrag.sh
3. New files in this folder get indexed into LightRAG (localhost:9621)
4. After indexing, the file moves to `indexed/` — won't be re-sent next cycle

## What to put here

- Decision docs — why something was built a certain way
- Cross-project specs — patterns that span multiple projects
- Reference guides — deployment procedures, external API contracts
- Context docs — background on why a feature exists
- Research — competitor analysis, technology evaluations

## File naming convention

  decision-neon-over-planetscale.md
  api-contract-youtube-data-v3.md
  context-popiplay-brand.md

## To re-index an updated file

Move it back from `indexed/` to this folder root and it will be picked up on the
next cycle (or next manual reindex run).

## Manual run

  bash ~/1000Problems/reindex-lightrag.sh
EOF
  echo "Created $INBOX (first run)"
fi

mkdir -p "$INDEXED"

# ── Health check ──────────────────────────────────────────────────────────────
if ! curl -sf "$LIGHTRAG/health" > /dev/null 2>&1; then
  echo "ERROR: LightRAG is not running on $LIGHTRAG"
  echo "Start it with: docker start lightrag"
  exit 1
fi

echo "LightRAG is healthy. Starting reindex..."

# ── Helper ────────────────────────────────────────────────────────────────────
index_doc() {
  local filepath="$1"
  local label="$2"

  if [ ! -f "$filepath" ]; then
    echo "  SKIP (not found): $filepath"
    return
  fi

  local content
  content=$(cat "$filepath")

  curl -sf -X POST "$LIGHTRAG/documents/text" \
    -H "Content-Type: application/json" \
    -d "$(jq -n --arg text "$content" --arg desc "$label" '{text: $text, description: $desc}')" > /dev/null

  echo "  OK: $label"
}

# ── Inbox: index new docs and move to indexed/ ────────────────────────────────
INBOX_COUNT=0
if [ -d "$INBOX" ]; then
  echo ""
  echo "=== Inbox ($INBOX) ==="
  for f in "$INBOX"/*.md; do
    [ -f "$f" ] || continue          # skip if no .md files
    filename=$(basename "$f")
    label="inbox: $filename"
    index_doc "$f" "$label"
    mv "$f" "$INDEXED/$filename"
    echo "  → moved to indexed/"
    INBOX_COUNT=$((INBOX_COUNT + 1))
  done
  if [ "$INBOX_COUNT" -eq 0 ]; then
    echo "  (no new docs)"
  fi
fi

# ── Standard project docs ─────────────────────────────────────────────────────
echo ""
echo "=== Root ==="
index_doc "$BASE/CLAUDE.md" "1000Problems root — global instructions, LightRAG setup, active projects"

echo ""
echo "=== AnimationStudio ==="
index_doc "$BASE/AnimationStudio/CLAUDE.md" "AnimationStudio — macOS video production app, SwiftUI, Phase 1 complete"
index_doc "$BASE/AnimationStudio/DESIGN.md" "AnimationStudio DESIGN — UI layout, colors, typography, component specs"
index_doc "$BASE/AnimationStudio/ANTI-SLOP.md" "AnimationStudio ANTI-SLOP — AI quality policy, humans own craft"
index_doc "$BASE/AnimationStudio/conventions.md" "AnimationStudio conventions — asset discovery rules, SVG group IDs, folder structure"
index_doc "$BASE/AnimationStudio/ANIMATION-GUIDE.md" "AnimationStudio animation guide — character animation system, keyframes, physics"
index_doc "$BASE/AnimationStudio/VOICE-GUIDE.md" "AnimationStudio voice guide — chatterbox TTS, lip sync, timestamps"
index_doc "$BASE/AnimationStudio/PERSONA-GUIDE.md" "AnimationStudio persona guide — PopiPlay character personalities and dialogue rules"
index_doc "$BASE/AnimationStudio/DIRECTION-CONTRACT.md" "AnimationStudio direction contract — episode structure, pacing, visual direction"
index_doc "$BASE/AnimationStudio/ACTION-SYSTEM.md" "AnimationStudio action system — interactive elements, mechanics, game logic"
index_doc "$BASE/AnimationStudio/PERFORMANCE.md" "AnimationStudio performance — rendering pipeline, optimization, benchmarks"
index_doc "$BASE/AnimationStudio/agent-core.md" "AnimationStudio agent core — AI agent tool definitions and routing"

echo ""
echo "=== VybePM-v2 ==="
index_doc "$BASE/VybePM-v2/CLAUDE.md" "VybePM-v2 — task orchestration hub, Next.js, Neon, executor API"
index_doc "$BASE/VybePM-v2/SPEC.md" "VybePM-v2 SPEC — full API spec, data model, state machine, UI requirements"

echo ""
echo "=== ytcombinator ==="
index_doc "$BASE/ytcombinator/CLAUDE.md" "ytcombinator — YouTube channel automation, keyword research, video analyzer"
index_doc "$BASE/ytcombinator/DESIGN-keyword-scraper.md" "ytcombinator DESIGN — keyword scraper architecture, quota management, collection pipeline"

echo ""
echo "=== GitMCP ==="
index_doc "$BASE/GitMCP/CLAUDE.md" "GitMCP — local MCP server for native git access, security model"
index_doc "$BASE/GitMCP/SPEC.md" "GitMCP SPEC — tool definitions, path validation, execFile security"

echo ""
echo "=== Vybe ==="
index_doc "$BASE/Vybe/CLAUDE.md" "Vybe — iOS voice client for VybePM, speech-to-task pipeline"
index_doc "$BASE/Vybe/SPEC.md" "Vybe SPEC — VybePM API integration, Claude parsing, SpeechService"

echo ""
echo "=== RubberJoints-iOS ==="
index_doc "$BASE/RubberJoints-iOS/CLAUDE.md" "RubberJoints-iOS — AI workout coach, SwiftUI, SwiftData, Claude API"

echo ""
echo "=== KitchenInventory ==="
index_doc "$BASE/KitchenInventory/CLAUDE.md" "KitchenInventory — iOS kitchen inventory, voice-first, agentic tool-calling"
index_doc "$BASE/KitchenInventory/DESIGN.md" "KitchenInventory DESIGN — visual design system, fonts, colors, spacing"
index_doc "$BASE/KitchenInventory/DEVELOPMENT_PLAN.md" "KitchenInventory development plan — phases, features, architecture decisions"

echo ""
echo "=== Skills ==="
index_doc "$BASE/Skills/CLAUDE.md" "Skills repo — central skill repository, Cowork vs Code skills, install process"
index_doc "$BASE/Skills/README.md" "Skills README — skill catalog, directory structure, format"

echo ""
echo "=== Done ==="
echo "Inbox docs indexed: $INBOX_COUNT"
echo "Query: curl -s -X POST $LIGHTRAG/query -H 'Content-Type: application/json' -d '{\"query\": \"test\", \"mode\": \"hybrid\"}'"
