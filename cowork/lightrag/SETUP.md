# LightRAG Setup — One-Time Installation

Claude Code: follow these steps to install and configure LightRAG on this machine. This is infrastructure, not a 1000Problems project. Everything lives under `~/1000Problems/.lightrag/`.

## Prerequisites

- Docker Desktop installed and running
- An OpenAI API key (ask Angel if you don't have one — check `~/1000Problems/secrets.env` for existing keys)
- `jq` installed (`brew install jq` if missing)

## Step 1: Create the Directory Structure

```bash
mkdir -p ~/1000Problems/.lightrag/{tasks,results,data}
```

## Step 2: Clone LightRAG

```bash
cd ~/1000Problems/.lightrag
git clone https://github.com/HKUDS/LightRAG.git repo
```

## Step 3: Create the Environment File

Create `~/1000Problems/.lightrag/.env`:

```env
# LLM for entity/relationship extraction
LLM_MODEL=gpt-4o-mini
LLM_PROVIDER=openai
OPENAI_API_KEY=<key-from-secrets.env-or-ask-angel>

# Embedding model
EMBEDDING_MODEL=text-embedding-3-large
EMBEDDING_PROVIDER=openai

# Server config
HOST=0.0.0.0
PORT=9621

# Storage — local files, simple and free
STORAGE_PROVIDER=json
GRAPH_PROVIDER=networkx

# Data persistence directory (mapped to Docker volume)
DATA_DIR=/app/data

# Optional: reranker for better retrieval quality
# RERANK_MODEL=BAAI/bge-reranker-v2-m3
```

IMPORTANT: The `.env` file contains the OpenAI API key. Do NOT commit it. Do NOT copy it into `secrets.env` — keep the LightRAG key isolated here.

## Step 4: Create docker-compose.yml

Create `~/1000Problems/.lightrag/docker-compose.yml`:

```yaml
version: '3.8'

services:
  lightrag:
    build:
      context: ./repo
      dockerfile: Dockerfile
    container_name: lightrag
    ports:
      - "9621:9621"
    env_file:
      - .env
    volumes:
      - ./data:/app/data
    restart: unless-stopped
```

If the repo doesn't have a Dockerfile (check first), use the official Docker image instead:

```yaml
version: '3.8'

services:
  lightrag:
    image: zhuohan-hkuds/lightrag:latest
    container_name: lightrag
    ports:
      - "9621:9621"
    env_file:
      - .env
    volumes:
      - ./data:/app/data
    restart: unless-stopped
```

## Step 5: Start the Container

```bash
cd ~/1000Problems/.lightrag
docker compose up -d
```

Verify it's running:

```bash
# Should return a health response
curl -s http://localhost:9621/health

# Check Docker logs if health check fails
docker logs lightrag --tail 50
```

## Step 6: Install the Runner Script

Create `~/1000Problems/.lightrag/runner.sh`:

```bash
#!/bin/bash
# LightRAG task runner — processes task files from tasks/ and writes results to results/
# Usage: bash runner.sh [--once] [--watch]
#   --once: process all pending tasks and exit
#   --watch: poll every 5 seconds (for scheduled use)
#   (no flag): same as --once

set -euo pipefail

LIGHTRAG_DIR="$HOME/1000Problems/.lightrag"
TASKS_DIR="$LIGHTRAG_DIR/tasks"
RESULTS_DIR="$LIGHTRAG_DIR/results"
API_BASE="http://localhost:9621"

process_task() {
    local task_file="$1"
    local task_name=$(basename "$task_file")
    local result_file="$RESULTS_DIR/$task_name"

    # Skip if already processed
    [[ -f "$result_file" ]] && return 0

    local action=$(jq -r '.action' "$task_file")

    case "$action" in
        index)
            local doc_count=$(jq '.documents | length' "$task_file")
            local errors=0
            local indexed=0

            for i in $(seq 0 $((doc_count - 1))); do
                local doc_path=$(jq -r ".documents[$i].path" "$task_file")
                local doc_label=$(jq -r ".documents[$i].label" "$task_file")
                # Expand ~
                doc_path="${doc_path/#\~/$HOME}"

                if [[ ! -f "$doc_path" ]]; then
                    echo "WARN: File not found: $doc_path" >&2
                    ((errors++))
                    continue
                fi

                local content=$(cat "$doc_path")
                local payload=$(jq -n --arg text "$content" --arg desc "$doc_label" \
                    '{"text": $text, "description": $desc}')

                local response=$(curl -s -w "\n%{http_code}" -X POST "$API_BASE/documents/text" \
                    -H "Content-Type: application/json" \
                    -d "$payload")
                local http_code=$(echo "$response" | tail -1)

                if [[ "$http_code" == "200" || "$http_code" == "201" ]]; then
                    ((indexed++))
                    echo "Indexed: $doc_label ($doc_path)"
                else
                    ((errors++))
                    echo "FAIL ($http_code): $doc_label" >&2
                fi
            done

            jq -n --arg task "$task_name" --arg status "ok" \
                --argjson indexed "$indexed" --argjson errors "$errors" \
                '{"task": $task, "status": $status, "indexed": $indexed, "errors": $errors}' \
                > "$result_file"
            ;;

        query)
            local query_text=$(jq -r '.text' "$task_file")
            local mode=$(jq -r '.mode // "hybrid"' "$task_file")

            local payload=$(jq -n --arg query "$query_text" --arg mode "$mode" \
                '{"query": $query, "mode": $mode}')

            local response=$(curl -s -X POST "$API_BASE/query" \
                -H "Content-Type: application/json" \
                -d "$payload")

            jq -n --arg task "$task_name" --arg status "ok" \
                --argjson result "$response" \
                '{"task": $task, "status": $status, "result": $result}' \
                > "$result_file" 2>/dev/null || \
            jq -n --arg task "$task_name" --arg status "ok" --arg result "$response" \
                '{"task": $task, "status": $status, "result": $result}' \
                > "$result_file"
            ;;

        status)
            local health=$(curl -s "$API_BASE/health" 2>/dev/null || echo '{"status":"unreachable"}')
            local stats=$(curl -s "$API_BASE/graphs/stats" 2>/dev/null || echo '{}')

            jq -n --arg task "$task_name" --arg status "ok" \
                --argjson health "$health" --argjson stats "$stats" \
                '{"task": $task, "status": $status, "health": $health, "stats": $stats}' \
                > "$result_file"
            ;;

        *)
            jq -n --arg task "$task_name" --arg status "error" \
                --arg result "Unknown action: $action" \
                '{"task": $task, "status": $status, "result": $result}' \
                > "$result_file"
            ;;
    esac
}

# Process all pending tasks
process_all() {
    for task_file in "$TASKS_DIR"/*.json; do
        [[ -f "$task_file" ]] || continue
        process_task "$task_file"
    done
}

case "${1:-}" in
    --watch)
        echo "Watching $TASKS_DIR for new tasks..."
        while true; do
            process_all
            sleep 5
        done
        ;;
    *)
        process_all
        ;;
esac
```

Make it executable:

```bash
chmod +x ~/1000Problems/.lightrag/runner.sh
```

## Step 7: Verify the Full Pipeline

```bash
# Create a test status task
echo '{"action": "status"}' > ~/1000Problems/.lightrag/tasks/test-status.json

# Run the runner
bash ~/1000Problems/.lightrag/runner.sh

# Check the result
cat ~/1000Problems/.lightrag/results/test-status.json

# Clean up test files
rm ~/1000Problems/.lightrag/tasks/test-status.json
rm ~/1000Problems/.lightrag/results/test-status.json
```

## Step 8: Initial Full Index

Create `~/1000Problems/.lightrag/tasks/initial-index.json` with the full document list from the skill's "Index All Projects" template, then run:

```bash
bash ~/1000Problems/.lightrag/runner.sh
```

This will take a minute or two and cost ~$0.10-0.50 in OpenAI API calls.

## Verification Checklist

- [ ] Docker container "lightrag" is running (`docker ps | grep lightrag`)
- [ ] Health check returns OK (`curl -s localhost:9621/health`)
- [ ] Runner script processes tasks and writes results
- [ ] Initial index completed without errors
- [ ] .env file is NOT tracked by git

## Troubleshooting

**Container won't start**: Check `docker logs lightrag`. Most common issue is an invalid or missing OpenAI API key.

**Index fails with 500**: The LightRAG storage might not be initialized. Check that `data/` directory exists and Docker volume is mapped correctly.

**"Embedding model mismatch"**: If you change the embedding model after indexing, you must clear `data/` and re-index everything. The embeddings are model-specific.

**Port conflict**: If 9621 is taken, change `PORT` in `.env` and `ports` in `docker-compose.yml`. Update the runner script's `API_BASE` too.
