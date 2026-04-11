---
name: character-creator
description: >
  Create new animated characters for AnimationStudio using the SVG joint-rig framework.
  Handles the full pipeline: concept → Whiteboard design page → iterate with Angel → extract
  production assets (character.json, front.svg, expressions, mouths, persona, voice config).
  Use this skill whenever someone says "create a character", "new character", "build a character",
  "design a character", mentions adding a character to AnimationStudio or PopiLearn, or references
  the SVG rig system. Also trigger when discussing character design for any animated channel, even
  if they don't say "character" explicitly — e.g. "let's make a dinosaur for the counting episode"
  or "we need a cat friend for Rob".
---

# Character Creator

Build new animated characters for AnimationStudio's SVG joint-rig framework. Every character
goes through three phases: **Design → Review → Extract**. The design phase happens in the
Whiteboard so Angel can see and iterate on the visual before any production files are generated.

This skill produced Rob the Robot and Baby Shark. Both are fully rigged SVG characters with
modular joint groups, 10 expressions, 8 mouth shapes for lip sync, and persona guides — all
discoverable by AnimationStudio's convention-based asset pipeline.

## Before You Start

Read these references as needed (they're in the `references/` directory next to this file):

- `references/svgrig.md` — The joint-group architecture, coordinate system, and animation model.
  Read this first if you haven't built a character before.
- `references/assets.md` — character.json schema, expression JSON format, mouth shape specs,
  and the full directory structure that convention-based discovery expects.

Also read AnimationStudio's `conventions.md` (in the AnimationStudio project root) — it's the
authoritative source for asset discovery rules. The references above summarize the parts relevant
to character creation, but conventions.md is the contract.

## Phase 1: Concept

Before drawing anything, nail down the character's identity. Ask about (or decide collaboratively):

**Identity**
- Species/type (robot, animal, human, fantasy creature)
- Name and role in PopiLearn episodes
- Age feel (toddler, kid, adult) — affects proportions and voice

**Personality**
- 3-4 core traits (curious, brave, clumsy, shy, etc.)
- How they express emotion physically (whole-body bounce? ear droop? tail wag?)
- Relationship to existing characters (friend of Rob? rival? mentor?)

**Visual Direction**
- Body shape silhouette (egg/round, tall/lanky, blocky, etc.)
- Color palette — must be distinct from existing characters. Check what's taken:
  - Rob: mint green (#06D6A0) + orange (#FF6B35) + navy (#2B2D42)
  - Baby Shark: sky blue (#4FC3F7) + golden yellow (#FFD54F) + deep blue (#1565C0)
- Distinguishing features (antenna, spots, stripes, hat, tail shape)
- Design language: organic curves vs geometric shapes vs mixed

**Anatomy Mapping**
Every character must map to the 7 required SVG joint groups, regardless of species. Work out
what each joint IS for this character:

| Joint Group | Humanoid | Aquatic | Quadruped | Your Character |
|-------------|----------|---------|-----------|----------------|
| head        | head     | head    | head      | ?              |
| torso       | body     | body    | body      | ?              |
| leftArm     | left arm | left fin | left front leg | ?        |
| rightArm    | right arm | right fin | right front leg | ?     |
| leftLeg     | left leg | left tail lobe | left back leg | ?   |
| rightLeg    | right leg | right tail lobe | right back leg | ? |
| antenna     | hair/hat | dorsal fin | ears/tail tip | ?        |
| faceLayer   | face     | face    | face      | face           |

The mapping matters because the animation system drives these groups generically — a "wave"
action rotates rightArm regardless of whether it's an arm, a fin, or a tentacle.

## Phase 2: Design (Whiteboard)

Once the concept is clear, create an interactive design page in the Whiteboard. This is where
Angel sees the character for the first time and decides if it works.

### Create the Whiteboard page

Use the git MCP's `fs_write` tool to create these files:

**Directory:** `pages/AnimationStudio/{character-name}-design/`

**index.html** — Interactive character prototype. This is the centerpiece. Build it as a
self-contained HTML file with:

1. **Full SVG character** with all joint groups properly ID'd and structured
2. **Underwater/environment background** appropriate to the character's world
3. **Idle animation loop** at 30fps showing the character alive:
   - Gentle body bob (breathing/floating)
   - Secondary motion on appendages (fin sway, tail wag, antenna spring)
   - Squash/stretch on torso
   - Head micro-tilt
4. **Expression buttons** — click to switch between at least 4 expressions (happy, excited,
   sad, surprised). More is better. Each expression redraws the faceLayer contents.
5. **Mouth shape cycling** — button to step through all 8 phoneme shapes (rest, A, E, I, O,
   MBP, FV, WR)
6. **One-shot animations** — Wave and Jump buttons to test joint articulation
7. **Info panel** showing character name, joint group labels, palette swatches

The HTML should be production-quality. This isn't a wireframe — it's the character. Follow
ANTI-SLOP principles: no default fonts, no generic colors, no lazy gradients. Every design
choice should be intentional and specific to this character.

Reference the Rob and Baby Shark prototypes in `Animation/` for the proven pattern:
- `rob-rigged.html` — geometric/mechanical character
- `babyshark-rigged.html` — organic/soft character

**context.md** — Document the design reasoning:
```markdown
# {Character Name} — Design Context

## Intent
What this character is for, what episodes it appears in, what it teaches.

## Design Decisions
- Body shape: why this silhouette
- Palette: why these colors, how they contrast with existing characters
- Anatomy mapping: what each joint group represents
- Expression style: how this character shows emotion differently from others

## Iterations
(Append here as Angel gives feedback and you revise)

## References
- Conversations, existing characters referenced, real-world inspiration
```

**meta.json:**
```json
{
  "title": "{Character Name} — Character Design",
  "project": "AnimationStudio",
  "status": "draft",
  "type": "animation",
  "created": "{ISO 8601}",
  "finalized": null,
  "tags": ["character", "design", "{character-name}"],
  "description": "Interactive SVG rig prototype for {Character Name}"
}
```

### Tell Angel the page is ready

After creating the Whiteboard page, tell Angel:
> "The design is up on the Whiteboard at `pages/AnimationStudio/{name}-design/`. Open
> localhost:5555 to review it, or open the index.html directly in a browser. Let me know
> what you think — we can iterate on the shape, colors, expressions, anything."

### Iterate

Angel will give feedback. Common iterations:
- "Make the eyes bigger" → adjust eye radii in the SVG and expression drawing functions
- "Change the blue to more teal" → update palette values throughout
- "The fins look stiff" → adjust idle animation parameters (frequency, amplitude)
- "Add a wiggle when it talks" → add mouth-triggered body movement

Each iteration: rewrite index.html entirely (don't patch — rewrite), append to context.md
explaining what changed and why.

## Phase 3: Extract Production Assets

Once Angel approves the design ("looks good", "love it", "let's go"), extract the full
character asset folder. This is mechanical — take the approved design and produce the
convention-compliant file structure.

### Directory structure

Create under `AnimationStudio/characters/{characterid}/`:

```
{characterid}/
├── character.json         — Skeleton, physics, style, palette
├── persona.md            — Personality guide for AI agent
├── views/
│   └── front.svg         — Canonical front view (extracted from prototype)
├── expressions/          — 10 expression JSONs
│   ├── happy.json
│   ├── excited.json
│   ├── surprised.json
│   ├── sad.json
│   ├── sleepy.json
│   ├── love.json
│   ├── thinking.json
│   ├── laughing.json
│   ├── confused.json
│   └── worried.json
├── mouths/               — 8 phoneme shape SVGs
│   ├── rest.svg
│   ├── A.svg
│   ├── E.svg
│   ├── I.svg
│   ├── O.svg
│   ├── MBP.svg
│   ├── FV.svg
│   └── WR.svg
└── voice/
    ├── config.json       — Chatterbox TTS settings
    └── phoneme-map.json  — ARPAbet → mouth shape mapping
```

The character ID is lowercase, no spaces, no hyphens. Examples: `rob`, `babyshark`, `luna`.

### Extraction checklist

For each file type, see `references/assets.md` for the exact schema and format. Key points:

**character.json** — Extract the skeleton coordinates, physics parameters, and palette from
your prototype's JavaScript. The skeleton `x`/`y` values must match the `transform="translate()"`
values on the SVG joint groups exactly.

**front.svg** — Extract the static SVG from the prototype. Must include all 7 required group
IDs. The viewBox should be centered on (0,0) with enough room for limb articulation. Include
gradients in `<defs>`. Include the default happy expression in faceLayer.

**Expression JSONs** — Convert each expression's drawing logic from the prototype's JavaScript
into the declarative JSON format. Each expression defines eyes (left/right arrays of SVG
primitives), blush, and optional extras (sparkles, tears, thought bubbles).

**Mouth SVGs** — Each is a tiny standalone SVG showing just the mouth region. The viewBox
should cover only the mouth area. Use the character's palette colors for lips/interior.

**persona.md** — Write the personality guide. This drives how the AI agent directs the
character in episodes. Include: identity, personality traits, voice direction, animation style
per emotion, relationship to other characters, and what the character is NOT.

**voice/config.json** — Chatterbox TTS settings (language, pitch, speed, style).

**phoneme-map.json** — Standard ARPAbet-to-mouth-shape mapping. This is the same for all
characters (the mouth shapes are universal), but the config file lives per-character so
it can be customized later.

### Important: never use ALL CAPS in voiced text

Chatterbox TTS distorts words written in ALL CAPS. Always use lowercase in any script text,
persona examples, or voice test strings.

## Phase 4: Finalize

After extracting production assets:

1. **Update the Whiteboard page** — set meta.json status to "final", add finalized timestamp
2. **Index to LightRAG** — index the character.json, persona.md, and front.svg so the
   character is queryable across projects
3. **Create an expression sheet** — an HTML file in `Animation/` showing all 10 expressions
   and 8 mouth shapes in a grid. Name it `{characterid}-expressions.html`. This is a quick
   reference for Angel and the animation pipeline.
4. **Verify convention discovery** — list the character's directory and confirm every required
   file exists. Compare the file tree to an existing character (rob) to make sure nothing
   is missing.

## Existing Characters (for reference and contrast)

When designing a new character, check what already exists so you don't duplicate palettes
or design language:

| Character | Style | Palette | Body Shape | World |
|-----------|-------|---------|------------|-------|
| Rob | Geometric, mechanical | Green/orange/navy | Rectangular, hard edges | Neutral dark |
| Baby Shark | Organic, soft | Blue/yellow/pink | Egg/bean, all curves | Underwater |

Every new character should be visually distinguishable from every existing one at thumbnail
size. Different silhouette, different dominant color, different world.

## Common Pitfalls

- **Forgetting a joint group.** The animation player crashes if any of the 7 required groups
  is missing. Always verify with a file listing after extraction.
- **Skeleton mismatch.** The `x`/`y` values in character.json must match the `translate()`
  values in front.svg exactly. Copy them, don't retype them.
- **Flat design.** Characters need depth — overlapping shapes, subtle gradients, specular
  highlights, shadow filters. A flat circle with eyes is not a character.
- **Generic palette.** Every character's dominant color must be unique in the cast. Check
  the existing characters table above before choosing colors.
- **Skipping the Whiteboard.** Always design in the Whiteboard first. The interactive
  prototype is how Angel evaluates the character — don't jump straight to production files.
