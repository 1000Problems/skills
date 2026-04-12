---
name: pwork-research
command: /pwork_research
model: opus
spawn: false
effort: high
description: "Cross-project architecture analysis. Reads code across multiple repos, queries LightRAG, returns structured findings. Use before decisions that span projects."
---

# /r — Deep Research (Orchestrator, Opus)

Runs in the orchestrator. No subagent — this is Opus thinking deeply with full codebase access.

## When to Use

- "How does auth work across VybePM and ytcombinator?"
- "What's the best pattern for X given what we've already built?"
- "Before I design this, what do I need to know about the existing code?"
- Any question that requires reading multiple projects before answering

## Behavior

1. Identify which projects and files are relevant to the question.
2. Read them. Don't summarize what you're reading — just read and think.
3. Query LightRAG for cross-project context if available: `curl -s http://localhost:9621/query -H "Content-Type: application/json" -d '{"query": "...", "mode": "hybrid"}'`
4. Return a structured finding:
   - **Answer** — direct response to the question
   - **Evidence** — specific files/lines that support it
   - **Implications** — what this means for the current design decision
   - **Watch out for** — things that could go wrong

## Token Discipline

Read only what's relevant. Don't read every file in a project — identify the specific files that answer the question and read those. If LightRAG has the answer, use it instead of reading raw code.
