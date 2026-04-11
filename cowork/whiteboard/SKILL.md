---
name: whiteboard
description: "Create and iterate on visual designs in the Whiteboard notebook. Use this skill whenever the user says 'whiteboard', 'whiteboard this', 'whiteboard [topic]', 'whiteboard episode [N]', 'show me', 'draw', 'design this visually', or when a discussion would benefit from a rendered HTML page. Also trigger when the user mentions working on episode assets, storyboards, UI mockups, SVG designs, or any visual artifact that should be persisted. This skill writes self-contained HTML files to the Whiteboard project, organized by project."
---

# Whiteboard — Visual Design Skill

You are creating visual designs as self-contained HTML files in the Whiteboard project. Each page is an HTML file with inline SVG/CSS/JS that opens in any browser — same format as the PopiLearn prototypes (rob-expressions.html, rob-rigged.html).

## Before You Start

Read the project's design spec to understand the page model and conventions:

```
~/1000Problems/Whiteboard/DESIGN.md
```

If you're designing UI or any visual that needs to look great, read the frontend-design skill:

```
~/1000Problems/Skills/shared/frontend-design/SKILL.md
```

If you're working on an AnimationStudio episode, also read the character and creative references:

```
~/1000Problems/AnimationStudio/ANTI-SLOP.md
~/1000Problems/AnimationStudio/conventions.md
~/1000Problems/AnimationStudio/characters/{character}/persona.md
```

## Step 1: Determine Project and Mode

When the user invokes whiteboard, figure out two things: **which project** and **what mode**.

### Project Detection (Infer, Ask When Ambiguous)

1. Look at the conversation context. If you've been discussing AnimationStudio for the last 20 messages, the project is AnimationStudio.
2. If the user names a project explicitly ("whiteboard this for VybePM"), use that.
3. If ambiguous (cross-project discussion, no clear context), ask: "Which project is this for?"

### Mode

- **Standard mode**: User says "whiteboard [topic]" → create/update a standalone page
- **Episode mode**: User says "whiteboard episode N" or "episode N assets/layout" → create/update episode pages

## Step 2: Check for Existing Draft

Before creating a new page, check if there's an active draft for this project.

Read the project directory under the mounted path for any `meta.json` with `"status": "draft"`.

**If an unsaved draft exists from a previous session** (different topic than what the user is asking about now):

1. Tell the user: "Found unsaved work from a previous session: '{title}'. Starting fresh for the new topic — that page stays as a draft you can finalize or discard later."
2. Proceed to create the new page. Do NOT auto-finalize the old one.

**If a draft exists for the same topic** (or user is continuing work):
1. Continue on that page. Read context.md if it exists to get up to speed, then update `index.html`.

**Rule: One active draft per project.** Don't create a second draft for the same project without acknowledging the first.

## Step 3: Create or Update the Page

### CRITICAL: Drafting Is Cheap

During active drafting, write ONLY `index.html`. Nothing else. No context.md. No meta.json. No git MCP tools. One file, one write, Angel refreshes browser.

### Writing Files

Use the regular **Write** tool to the mounted folder path. The mount IS Angel's filesystem.

```
{mount}/angel--1000Problems/Whiteboard/pages/{project}/{slug}/index.html
```

Do NOT use `fs_write` via git MCP for drafting. Do NOT use git MCP tools at all during active iteration. The mounted folder at `angel--1000Problems/` maps directly to Angel's machine.

### New Page

Write `index.html` only. Self-contained HTML:

```html
<!DOCTYPE html>
<html>
<head><meta charset="utf-8">
<style>
  * { margin: 0; padding: 0; }
  body { width: 1920px; height: 1080px; overflow: hidden; background: #2B2D42; }
</style>
</head>
<body>
<svg id="scene" xmlns="http://www.w3.org/2000/svg"
     viewBox="0 0 1920 1080" width="1920" height="1080">
  <!-- Design goes here -->
</svg>
<script>
  // Animation logic if needed
  // Expose window.renderFrame(n) for animated pages
</script>
</body>
</html>
```

- Use 1920x1080 viewBox for SVG designs (matches video output and AnimationStudio canvas)
- For UI mockups or diagrams, use whatever dimensions fit the content
- Everything inline — CSS in `<style>`, JS in `<script>`, SVG in `<body>`
- No external dependencies, no CDN links, no imports
- For animated pages, expose `window.renderFrame(frameNumber)` as the Rob prototypes do

### Updating During Iteration

1. **Rewrite `index.html` entirely.** The page is always the current best version.
2. **Do NOT write context.md or meta.json.** Those are for save/finalize only.
3. **One file per iteration.** Keep it fast.

### Resuming Work (New Session)

When Angel references a whiteboard page in a new session ("look at the AnimationStudio whiteboard", "check whiteboard page baby-shark"):

1. **Read context.md first** (if it exists) — not index.html. Context.md has the AI-readable description at ~80-300 tokens. You now know what's on the page and why.
2. **Only read index.html if you need to modify it.** If the conversation is about the design (discussing, planning), context.md is sufficient.
3. **Track which page is active.** When the codetasks skill fires later, it needs to know the active whiteboard page to include the Visual Reference section.

## Step 4: Episode Mode

When the user says "whiteboard episode N" or references an episode:

### Episode Directory

```
{mount}/angel--1000Problems/Whiteboard/pages/AnimationStudio/episodes/ep-{N}-{slug}/
  episode.json          -- written on save, not during drafting
  assets/
    index.html          -- written during drafting
  layout/
    index.html          -- written during drafting
```

Context.md and meta.json for each sub-page are written on save/finalize, not during drafting.

### episode.json

Written when saving a draft (not on first create). Format:

```json
{
  "number": 12,
  "title": "Los Colores",
  "series": "PopiLearn",
  "status": "planning",
  "learning_goals": ["..."],
  "characters": ["Rob", "Luna"],
  "target_duration": "3:30",
  "created": "2026-04-10T14:30:00Z"
}
```

### Page 1: Assets

The workbench. An HTML/SVG page showing everything NEW that needs to be created for this episode: new backgrounds, new props, new character poses. Rendered as a grid of SVG elements — same style as rob-expressions.html.

Only draw what's NEW. Existing assets (Rob's standard expressions, letter blocks) are referenced verbally but not re-drawn.

User navigates here by saying "let's do the assets" or "whiteboard episode N assets."

### Page 2: Episode Layout

The blueprint. An HTML/SVG page showing all scenes (typically 12) in a grid (4 columns x 3 rows). Each scene panel shows:

- Scene number (top-left corner of panel)
- Background
- Character positions with their expressions (using the SVG character rig style)
- Prop placements
- Camera framing annotation (WIDE / CLOSE / MEDIUM)
- Dialogue cue or audio note (bottom of panel)

This is a visual shot list. The entire episode at a glance. Same 1920x1080 SVG canvas, same rendering approach as the Rob prototypes.

User navigates here by saying "now the layout" or "whiteboard episode N layout."

### Seamless Navigation

Once you're in episode mode for episode N, the user doesn't need to re-specify the episode number. "Let's do the assets" and "now the layout" are enough — you know which episode from context.

## Step 5: Saving a Draft

When Angel says "save this", "save draft", or the session is ending with active whiteboard work:

NOW write the supporting files alongside index.html:

**context.md** — the AI-readable description for future sessions and Code tasks:

```markdown
## {Date} — {Topic}

**What's on this page:** {Concrete description of what's currently rendered.
Describe elements, positions, colors, dimensions, interactions as if for
someone who cannot see the page. Not "a character" but "Baby Shark, blue
gradient body (#4FC3F7 → #0277BD), 3-joint tail, 5 mouth shapes, center
stage at 960,540."}

**Intent:** What this design solves, for which project.
**Key decisions:** Specific technical/aesthetic choices and why.
```

**meta.json**:

```json
{
  "title": "Page Title",
  "project": "ProjectSlug",
  "status": "draft",
  "type": "static",
  "created": "2026-04-10T14:30:00Z",
  "finalized": null,
  "tags": ["relevant", "tags"],
  "description": "One-line summary"
}
```

Type is one of: `static`, `animation`, `diagram`, `episode`.

For episodes: also write episode.json at this point.

## Step 6: Finalization

When the user says "finalize", "this is done", or "lock it":

1. **Write/update context.md**: Clean summary with "What's on this page" section.
2. **Update meta.json**: Set `status: "final"`, set `finalized` to current ISO timestamp.
3. **Index to LightRAG**: Use `lightrag_index` to index the context.md file.

```
lightrag_index: path = ~/1000Problems/Whiteboard/pages/{project}/{slug}/context.md
```

4. **For episodes**: Finalize BOTH pages (assets + layout), index both context files, update episode.json status.

5. **Tell the user** the page is finalized and indexed. Remind them to commit via the Whiteboard UI.

## What to Do When the User Says "Whiteboard"

Quick decision tree:

1. "whiteboard [topic]" → Standard mode. Detect project. Check for existing draft. Write index.html only.
2. "whiteboard episode N" → Episode mode. Create/find episode directory. Ask "assets or layout?"
3. "whiteboard episode N assets" → Episode mode, go straight to assets page.
4. "whiteboard episode N layout" → Episode mode, go straight to layout page.
5. "save this" / "save draft" → Write context.md + meta.json for current active page.
6. "finalize" → Save + lock + LightRAG index.
7. "whiteboard" (no topic, mid-conversation) → Whiteboard whatever we're currently discussing. Infer topic from context.

## HTML Design Quality

Every page must look intentionally designed, not like a code demo. Follow these rules:

- **No default fonts.** Use distinctive font choices. For PopiLearn/AnimationStudio: `'Comic Sans MS', 'Baloo Thambi', sans-serif` (established in prototypes).
- **No generic colors.** Use the project's palette. AnimationStudio established: `#2B2D42` (dark blue-gray), `#06D6A0` (Rob green), `#FFD166` (warm yellow), `#FF6B35` (orange), `#EF476F` (pink), `#4D9DE0` (sky blue).
- **SVG quality matters.** Clean paths, proper gradients, consistent stroke widths. These are reference designs, not wireframes.
- **Label everything.** Expressions get names. Scene panels get numbers and annotations. Props get labels. The page should be self-documenting.

## Rules

- NEVER delete a page — even drafts have useful context
- NEVER overwrite a finalized page — create a new page for revisions
- NEVER commit or push — Angel uses the Whiteboard UI for that
- NEVER use git MCP tools (fs_write, fs_read) during active drafting — use the mounted folder with Write/Read tools
- NEVER write context.md or meta.json during active iteration — save those for "save draft" or "finalize"
- ALWAYS rewrite index.html entirely when iterating (current best version)
- ALWAYS use the regular Write tool to the mounted path, not fs_write
- One active draft per project at a time
- When handing off to codetasks, the active whiteboard page path and context summary carry forward automatically
