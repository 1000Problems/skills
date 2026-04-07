---
name: animate
description: "Process AnimationStudio drafts into production-ready scripts and SVGs via the exchange protocol. Use this skill whenever the user says 'animate', 'process draft', 'convert the draft', 'check the exchange', 'generate SVGs', or mentions AnimationStudio draft processing. Also trigger when the user asks to check if there's a draft waiting, or says something like 'the draft is ready' or 'I uploaded a draft'. This skill reads a raw markdown draft from the exchange inbox on the user's machine, converts it to a structured .popi.json script, then generates one hero-frame SVG per section — all via the git MCP filesystem tools."
---

# AnimationStudio Animate

You are processing a raw episode draft into production-ready assets for AnimationStudio, a macOS app that produces animated kids' videos for PopiPlay.

The app and Cowork communicate through the **exchange protocol** — a shared folder on the user's machine with a `status.json` handshake file. The app writes a draft and polls for your output. You do the heavy creative work here.

## Before You Start

Read these reference docs from the user's machine using `fs_read`. They contain the creative rules and technical specs that govern everything you produce. Skipping them means producing slop, and the whole point of this project is to not do that.

```
~/1000Problems/AnimationStudio/ANTI-SLOP.md
~/1000Problems/AnimationStudio/conventions.md
~/1000Problems/AnimationStudio/agent-core.md
```

Then read the character persona for whoever's in the draft (usually `rob`):

```
~/1000Problems/AnimationStudio/characters/{character}/persona.md
```

And if the character has an existing front view SVG, read it — you'll base your hero frames on it:

```
~/1000Problems/AnimationStudio/characters/{character}/views/front.svg
```

## Exchange Folder Layout

All paths on user's machine at `~/1000Problems/AnimationStudio/.exchange/`:

inbox/draft.md — The app writes the raw draft here
outbox/script.popi.json — You write the finished script here
outbox/svg/{section-id}.svg — You write one SVG per section here
status.json — The handshake file, both sides read/write

Use `fs_read` to read and `fs_write` to write. All paths go through the git MCP. Do NOT use sandbox Write tool — those files won't reach the user's machine.

## status.json

Update it after every meaningful step. The app polls every second.

Phases: idle, waiting_for_worker, generating_script, generating_svgs, done
SVG statuses per section: pending, in_progress, done, failed

The app reacts to specific transitions:
- script_ready flips true: app auto-saves current, loads new script
- SVG status flips to done: app loads that SVG into canvas
- phase hits done: app reports completion, stops polling

## Execution

### 1. Check for a draft

Read status.json and inbox/draft.md. If draft_available is false, tell the user nothing is queued.

### 2. Read reference docs

Read ANTI-SLOP.md, conventions.md, agent-core.md, and character persona. This is the creative foundation.

### 3. Update status to generating_script (percent_complete: 5)

### 4. Convert draft to .popi.json

The format: { meta: { episode, character, version }, sections: [{ id, title, beats: [{ id, type, duration, character, expression, body, text, belly, sfx, camera }] }] }

Beat types: dialogue, interaction, mechanic, camera, overlay, action

Rules:
- Section IDs: lowercase, hyphenated from title
- Beat IDs: sequential d001, d002, etc across entire script
- Duration: ~0.15s per char for dialogue, 5s for interactions, 1s mechanics, 2s actions
- Expression: match the emotion in the text, don't default everything to happy
- Body: default idle unless movement implied (jump, dance, wave)
- belly: for content shown on character's belly screen
- sfx: celebrations = star-earn, freezing = freeze-chime, transitions = whoosh

Write to outbox/script.popi.json

### 5. Update status: script_ready true, list SVG section IDs as pending (percent_complete: 25)

### 6. Generate one SVG per section

Hero-frame SVG with character in section's primary expression. Required group IDs inside #characterRoot: #head, #torso, #leftArm, #rightArm, #leftLeg, #rightLeg, #faceLayer. Optional: #antenna, #bellyScreen. ViewBox: 0 0 800 600.

For each section: update status to in_progress, write SVG to outbox/svg/{section-id}.svg, update status to done, increment percent. Each SVG adds 70/section_count percent (covering 25-95 range).

### 7. Update status to done (percent_complete: 100)

## Error Handling

If SVG fails for one section, set it to failed and continue. Set phase to done regardless. Put error details in message.

## Important

- Use fs_read and fs_write for ALL file operations
- Update status.json after EVERY section SVG
- Read ANTI-SLOP.md before producing anything
