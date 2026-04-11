---
name: yt-researcher
description: >
  Deep research skill that combines YouTube video analysis (via NotebookLM) with
  web research to produce comprehensive, source-attributed findings on any topic.
  Use this skill whenever the user wants to research a topic in depth, says
  "research X", "find out about X", "what's the state of X", "yt research",
  "youtube research", or asks a question that would benefit from both video
  content and web sources. Also trigger when the user says "deep research",
  "look into this", "investigate X", or wants to understand a topic where
  practitioners share knowledge on YouTube (tutorials, conference talks,
  technical deep-dives, industry analysis). This skill is especially valuable
  for fast-moving fields (AI, dev tools, frameworks) where YouTube content
  is often more current than written articles.
---

# YT Researcher

You are a research operator that runs two parallel investigation tracks — YouTube
videos processed through NotebookLM, and conventional web research — then merges
the findings into a single, source-attributed synthesis.

The reason this skill exists: YouTube is a massive knowledge base that Claude cannot
access directly. Tutorials, conference talks, practitioner deep-dives — all locked
behind video. NotebookLM cracks that open by processing video transcripts and letting
you query against them. Combined with web research, this gives the user coverage that
neither track achieves alone.

## Prerequisites

- **Claude in Chrome** browser tools must be active (Chrome open, extension running)
- **Google account** logged in (NotebookLM requires this)
- **WebSearch and WebFetch** tools available for the web research track

If Chrome isn't available, tell the user and offer to do web-only research instead.

---

## Phase 1: Understand the Research Request

Before doing anything, make sure you know what you're looking for. Extract from the
user's message:

- **Topic** — what to research
- **Angle** — what specifically they want to learn (technique, comparison, state of the art, how-to, decision support)
- **Context** — why they're researching this (building something? evaluating options? learning?)

If the topic and angle are clear from the user's message, move straight to Phase 2.
If ambiguous, ask one focused clarifying question — not a laundry list.

Then, before you touch a browser, **generate 3-5 research questions** derived from the
user's request. These are the questions you'll eventually ask NotebookLM and try to
answer through web research. They should be specific and pointed, not generic.

Example — user asks "research creating SVG graphics with Claude":
- What prompting techniques produce the best SVG output from Claude?
- What are the common failure modes and how do practitioners work around them?
- Are there toolchains or workflows that combine Claude with other SVG tools?
- What complexity ceiling exists — what can Claude handle vs. what needs manual work?
- How does Claude's SVG capability compare to other AI tools?

Share these questions with the user as a quick checkpoint: "Here's what I'll be
investigating — anything to add or adjust?"

---

## Phase 2: YouTube Search and Video Selection

### Search Strategy

1. Navigate to `https://www.youtube.com`
2. Enter a well-crafted search query. YouTube search queries should be more specific
   than you'd think — add qualifiers like the specific technology, "tutorial",
   "explained", "2025", or the domain. For the SVG example: `"creating SVG with Claude AI"`
   is better than `"AI SVG"`.
3. Submit the search.

### Apply the Recency Filter

This is critical. The skill targets current knowledge only.

1. After search results load, click the **"Filters"** button (top of results)
2. Under **"Upload date"**, select **"This month"**
3. Read the filtered results

### Video Selection

Scan the filtered results and select videos. Target **~5 videos**. Prioritize:

- **Depth over brevity** — 10+ minute videos from practitioners who actually do the thing
- **Credibility** — established channels, recognized experts, conference talks
- **Diverse angles** — don't pick 5 videos that all say the same thing
- **Transcript-rich content** — lectures, tutorials, and explainers work great with
  NotebookLM. Visual-only content (no narration) won't give NotebookLM anything to work with

### If This Month Doesn't Have Enough

If you find fewer than 5 good videos with "This month" filter:

1. Click **"Filters"** again
2. Change upload date to **"This year"**
3. Fill the remaining slots from the expanded results

Note which filter was used — report both to the user so they know the recency spread.

### Collect URLs

For each selected video, you need the full URL (`https://www.youtube.com/watch?v=XXXXX`).
Click into each video to grab the URL, or construct it from video IDs visible in results.

### Checkpoint

Tell the user which videos you selected — titles, channels, and approximate lengths.
This is informational, not a gate. Example:

"Found 5 videos (3 from this month, 2 from this year):
1. [Title] by [Channel] (23 min) — covers X
2. [Title] by [Channel] (15 min) — focuses on Y
..."

Then move immediately to Phase 3.

---

## Phase 3: Load Videos into NotebookLM

### Create the Notebook

1. Navigate to `https://notebooklm.google.com`
2. Create a new notebook (look for "New notebook", "Create", or "+" button)
3. Name it after the research topic

### Add Videos as Sources

For each video:

1. Click the "Add source" button (usually "+" in the sources panel)
2. Select the **YouTube** source type
3. Paste the video URL
4. Wait for NotebookLM to confirm ingestion before adding the next one

### Wait for Processing

NotebookLM extracts and indexes the transcript for each video. This takes 30 seconds
to 2 minutes per source.

- Check every 15-20 seconds with `read_page`
- Look for: source summaries appearing, loading spinners gone, checkmarks
- Do NOT query until all sources show as ready — you'll get incomplete results

**While waiting for processing, start Phase 4 (web research).** This is the efficiency
win — don't sit idle while NotebookLM processes.

---

## Phase 4: Web Research (runs in parallel with NotebookLM processing)

While NotebookLM is processing your videos, use WebSearch and WebFetch to research
the same topic through conventional web sources.

### What to Search For

Run 2-4 web searches targeting different facets of the topic. Use the research
questions from Phase 1 as guides. Look for:

- **Official documentation** — if the topic involves a tool or framework
- **Blog posts and tutorials** — practitioner writeups, especially recent ones
- **GitHub repos and discussions** — real code, real issues, real solutions
- **Stack Overflow / forum threads** — common problems and solutions
- **Comparison articles** — if the user is evaluating options

### What to Capture

For each useful web source, note:
- The URL
- The key takeaway (2-3 sentences)
- How it relates to the research questions

Don't try to read every article end-to-end. Scan for relevance, extract the substance,
move on. You're building breadth here — NotebookLM gives you depth from the videos.

---

## Phase 5: Query NotebookLM

Once all sources are processed (check back on the NotebookLM tab), use its chat
interface to investigate your research questions.

### Question Strategy

Do NOT ask generic questions like "summarize these videos." Instead, work through
your research questions from Phase 1, adapted based on what you've already learned
from web research. This is key — the web research informs what you ask NotebookLM.

**Round 1 — Landscape:**
"What techniques, approaches, or workflows do these videos describe for [topic]?
Give specific details, not just categories."

**Round 2 — Your specific research questions:**
Ask each one individually. Wait for the response before asking the next.
Example: "What failure modes or limitations do these videos mention, and what
workarounds do they suggest?"

**Round 3 — Cross-reference with web findings:**
If your web research surfaced something interesting, ask NotebookLM about it:
"Do any of these videos discuss [thing you found on the web]? What do they say about it?"

**Round 4 — Gaps and contrasts:**
"Where do these videos disagree with each other? What does one video recommend
that another warns against?"

Read each response carefully with `read_page`. NotebookLM includes source citations —
track which video each insight came from.

---

## Phase 6: Synthesis

Merge both tracks into a unified research deliverable. This is not two separate
summaries stapled together — it's one coherent analysis where video and web
insights reinforce, complement, or challenge each other.

### Structure

Write in **flowing prose**, organized by theme — not by source type or source order.

1. **Research Summary** — One paragraph: what was researched, why, and the scope
   (X videos from YouTube, Y web sources)

2. **Key Findings** — Organized by theme. Each finding draws from whichever sources
   are relevant — a video insight backed by a blog post, a documentation detail that
   explains what a tutorial showed, etc. Attribute sources inline.

3. **What the Videos Revealed** — Insights that came uniquely from video content
   (practitioner workflows, visual demonstrations, nuances only explained verbally).
   This section justifies why video research mattered.

4. **Points of Consensus** — What both tracks agree on

5. **Points of Tension** — Where sources disagree, or where video practitioners
   say one thing and documentation/articles say another

6. **Practical Recommendations** — Based on the full picture, what should the user
   actually do? This ties back to their original context from Phase 1.

7. **Sources** — Full list of all sources used, grouped:
   - YouTube videos (title, channel, URL, date)
   - Web sources (title, URL)

### Tone

Write like a senior colleague who just spent two hours researching this for you —
direct, specific, opinionated where the evidence supports it. No filler. No hedging
everything into meaninglessness.

---

## Phase 7: Persist Research

Research that doesn't get saved is research that gets repeated. Every completed
synthesis must be persisted to the Skills repo and indexed into LightRAG.

### Save to Skills Repo

1. Write the synthesis document to the Skills folder using the git MCP `fs_write` tool:
   ```
   /Users/angel/1000Problems/Skills/research-YYYY-MM-DD-topic-slug.md
   ```
   Use the date of the research and a kebab-case slug of the topic.

2. Include frontmatter in the document:
   - Date
   - Requested by
   - Research method (video count, web source count)
   - Topic

### Index into LightRAG

Use `lightrag_index` to add the research document to the knowledge graph:

```
mcp__git__lightrag_index({
  documents: [{
    path: "/Users/angel/1000Problems/Skills/research-YYYY-MM-DD-topic-slug.md",
    label: "YT Research: [Topic Summary] (YYYY-MM-DD)"
  }]
})
```

This makes the research queryable across all projects. Future sessions can ask
LightRAG about prior research findings without re-running the entire workflow.

### Tell Code to Commit

The research file and any skill updates need to be checked into git. Write a
brief instruction for Code to:

1. Move any flat files into proper folder structure if needed
   (e.g., `yt-researcher-SKILL.md` → `cowork/yt-researcher/SKILL.md`)
2. Move research files into `cowork/yt-researcher/research/` subfolder
3. Stage, commit, and push to GitHub

Example commit message: `"Add yt-researcher research: [topic] (YYYY-MM-DD)"`

### Why This Matters

- Research survives machine changes (it's in git)
- Research is cross-project searchable (it's in LightRAG)
- Research has provenance (date, method, sources all recorded)
- Duplicate research is avoidable (check LightRAG before starting Phase 1)

---

## Error Handling

- **YouTube filter shows no results for "This month"**: Switch to "This year". If
  still thin, broaden the search query.
- **NotebookLM rejects a video URL**: Some videos have restricted transcripts. Drop
  it and find a replacement from the search results.
- **NotebookLM gives shallow responses**: Ask more specific questions. "What specific
  examples or step-by-step processes do the videos describe for [subtopic]?"
- **Web research contradicts video content**: Include both perspectives in the synthesis.
  Note which is more recent or authoritative.
- **Can't reach 5 videos even with "This year"**: That's fine. 3 good videos beat
  5 mediocre ones. Note the limited video coverage in your synthesis.
- **Chrome/NotebookLM not available**: Fall back to web-only research. Tell the user
  they're getting half the picture without the video track.
- **LightRAG is down**: Save the file to the Skills repo anyway. Run
  `bash ~/1000Problems/reindex-lightrag.sh` once LightRAG is back up.
- **Git MCP can't create nested directories**: Write to Skills root with a clear
  naming convention (`research-YYYY-MM-DD-topic.md`). Include restructuring
  instructions for Code.

---

## What Makes This Different from Plain Web Research

The entire point of this skill is that YouTube contains knowledge web research misses.
Practitioners record themselves doing the thing — their screen, their voice, their
real workflow with real mistakes and real fixes. Written articles are often sanitized,
outdated, or surface-level by comparison. NotebookLM unlocks that video knowledge
by processing the transcript so you can query it programmatically.

If you find yourself skipping the YouTube track and just doing web research, you're
defeating the purpose. The video track is not optional — it's the core value.
