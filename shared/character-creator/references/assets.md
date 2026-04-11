# Character Asset Specifications

Complete schemas and formats for every file in a character's production directory.
These formats are what AnimationStudio's convention-based discovery system expects.

## Directory Structure

```
characters/{characterid}/
├── character.json
├── persona.md
├── views/
│   └── front.svg
├── expressions/
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
├── mouths/
│   ├── rest.svg
│   ├── A.svg
│   ├── E.svg
│   ├── I.svg
│   ├── O.svg
│   ├── MBP.svg
│   ├── FV.svg
│   └── WR.svg
└── voice/
    ├── config.json
    └── phoneme-map.json
```

**Naming rules:**
- Character ID: lowercase, no spaces, no hyphens (`rob`, `babyshark`, `luna`)
- View names: lowercase (`front`, `side`, `back`)
- Expression names: lowercase (`happy`, `excited`)
- Mouth shapes: UPPERCASE for phonemes (`A`, `E`), lowercase for states (`rest`)

---

## character.json

The character definition file. Five sections.

```json
{
  "schemaVersion": "1.0.0",
  "id": "babyshark",
  "name": "Baby Shark",
  "description": "One-line description of the character.",

  "skeleton": {
    "head":     { "x": 0, "y": -120, "pivot": [0, -120] },
    "torso":    { "x": 0, "y": 20 },
    "leftArm":  { "x": -120, "y": 0, "pivot": [-120, 0] },
    "rightArm": { "x": 120, "y": 0, "pivot": [120, 0] },
    "leftLeg":  { "x": -35, "y": 160, "pivot": [-35, 160] },
    "rightLeg": { "x": 35, "y": 160, "pivot": [35, 160] }
  },

  "physics": {
    "weight": "light | medium | heavy",
    "squash": { "enabled": true, "amount": 0.12, "parts": ["torso", "head"] },
    "stretch": { "enabled": true, "amount": 0.10 },
    "bounce": { "decay": 0.6, "freq": 3.5 },
    "secondaryMotion": {
      "antenna": { "type": "spring", "stiffness": 0.5, "damping": 0.25 }
    }
  },

  "style": {
    "idle": {
      "bobFreq": 1.2, "bobAmount": 6,
      "finSwayFreq": 2.0, "finSwayAmount": 12
    },
    "jump": {
      "armSpread": 0.7,
      "peakExpression": "excited",
      "launchExpression": "excited",
      "landExpression": "surprised",
      "celebrateExpression": "laughing",
      "headTiltAmount": 4,
      "armEnergyMultiplier": 1.0
    }
  },

  "palette": {
    "primary": "#4FC3F7",
    "primaryLight": "#81D4FA",
    "dark": "#1565C0",
    "accent": "#FFD54F",
    "pink": "#F48FB1",
    "mouthInterior": "#0D47A1",
    "white": "#FFFFFF"
  },

  "anatomy": {
    "bodyShape": "egg | rectangular | custom",
    "limbs": {
      "leftArm": "what this joint physically is",
      "rightArm": "...",
      "leftLeg": "...",
      "rightLeg": "..."
    },
    "antenna": "what the antenna joint physically is",
    "details": ["distinguishing visual features"],
    "teeth": "description if relevant"
  }
}
```

**Critical:** The skeleton `x`/`y` values must exactly match the `translate()` values
on the corresponding SVG groups in front.svg. These are the joint positions.

---

## Expression JSON Format

Each expression defines what gets drawn into `#faceLayer`. The format is an array of SVG
primitive descriptors per eye, plus optional blush, sparkles, and extras.

```json
{
  "id": "happy",
  "description": "Human-readable description of this expression's visual.",
  "eyes": {
    "left": [
      { "type": "ellipse", "cx": -42, "cy": -128, "rx": 28, "ry": 32, "fill": "white" },
      { "type": "circle", "cx": -40, "cy": -126, "r": 18, "fill": "#1565C0" },
      { "type": "circle", "cx": -38, "cy": -128, "r": 10, "fill": "#0D2137" },
      { "type": "path", "d": "M ... Z", "fill": "white", "opacity": 0.9 }
    ],
    "right": [ /* mirror of left, with appropriate x-coordinate flips */ ]
  },
  "blush": {
    "left": { "cx": -65, "cy": -100, "rx": 18, "ry": 12, "fill": "#F48FB1", "opacity": 0.35 },
    "right": { "cx": 65, "cy": -100, "rx": 18, "ry": 12, "fill": "#F48FB1", "opacity": 0.35 }
  },
  "sparkles": {
    "positions": [[-72, -170], [72, -170]],
    "char": "✦",
    "color": "#FFD54F",
    "animated": true
  },
  "extras": [
    { "type": "text", "x": 75, "y": -155, "fill": "#81D4FA", "opacity": 0.5, "font-size": 18, "text": "zzz" },
    { "type": "ellipse", "cx": -52, "cy": -108, "rx": 3, "ry": 5, "fill": "#81D4FA", "opacity": 0.7 }
  ]
}
```

**Supported SVG primitive types:** `circle`, `ellipse`, `path`, `line`, `rect`, `polygon`, `text`

Each primitive maps directly to an SVG element. All attributes in the JSON object become
SVG attributes on the element.

### Expression Inventory (10 required)

| Expression | Key Visual                                      |
|------------|------------------------------------------------|
| happy      | Default. Normal eyes with highlights, gentle smile |
| excited    | Enlarged eyes, sparkle stars, open mouth        |
| surprised  | Very wide eyes, tiny pupils, round O mouth      |
| sad        | Droopy eyes, frown, optional tear               |
| sleepy     | Half-closed eyes (arcs), small yawn             |
| love       | Heart-shaped eyes, heavy blush, floating hearts |
| thinking   | Eyes looking up-right, wavy mouth, thought dots |
| laughing   | Squinted happy arcs, big open mouth, music note |
| confused   | Asymmetric eyes, flat mouth, question mark      |
| worried    | Angled brows, tight mouth                       |

---

## Mouth Shape SVGs

Each mouth shape is a standalone SVG file containing just the mouth geometry. The animation
player swaps these frame-by-frame during lip sync.

**ViewBox:** Should cover only the mouth region. For a character with mouth at y=-80:
`viewBox="-40 -105 80 50"` (roughly)

**8 required shapes:**

| Shape | Sound           | Visual                                           |
|-------|-----------------|--------------------------------------------------|
| rest  | silence         | Closed or gentle smile line                      |
| A     | "ah", "aw"      | Wide open oval with teeth and tongue visible     |
| E     | "ee", "eh"      | Wide horizontal grin with top teeth              |
| I     | "ih", "ee"      | Narrow vertical oval with front teeth            |
| O     | "oh", "oo"      | Round open circle                                |
| MBP   | "m", "b", "p"   | Closed pressed line (lips together)              |
| FV    | "f", "v"        | Lower area open with top teeth biting down       |
| WR    | "w", "r"        | Small pursed circle                              |

**Design tips:**
- Teeth should be character-appropriate. Shark: triangles. Robot: none (line mouth). Human: flat.
- Include tongue hints in the open shapes (A, E) for visual richness.
- Use the character's palette for mouth interior and lip colors.

---

## voice/config.json

```json
{
  "engine": "chatterbox",
  "language": "es",
  "pitch": "high | medium | low",
  "speed": 0.9,
  "style": "bubbly | warm | gravelly | etc",
  "notes": "Direction for voice generation. Never use ALL CAPS in text."
}
```

## voice/phoneme-map.json

Standard ARPAbet-to-mouth-shape mapping. This is the same for all characters but lives
per-character for future customization.

```json
{
  "description": "ARPAbet phoneme to mouth shape mapping.",
  "mapping": {
    "AA": "A", "AE": "A", "AH": "A", "AO": "A", "AW": "A", "AY": "A",
    "EH": "E", "EY": "E", "ER": "E",
    "IH": "I", "IY": "I",
    "OW": "O", "OY": "O", "UH": "O", "UW": "O",
    "M": "MBP", "B": "MBP", "P": "MBP",
    "F": "FV", "V": "FV",
    "W": "WR", "R": "WR",
    "CH": "E", "D": "E", "DH": "E", "G": "E",
    "HH": "A", "JH": "E", "K": "E", "L": "E",
    "N": "E", "NG": "E", "S": "I", "SH": "I",
    "T": "E", "TH": "E", "Y": "I", "Z": "I", "ZH": "I"
  },
  "defaultShape": "rest",
  "restThreshold": 0.08,
  "transitionFrames": 2
}
```

---

## persona.md Template

```markdown
# {Character Name} — Persona Guide

## Identity
Who this character is. Species, age feel, role in PopiLearn.

## Personality Traits
**Core:** 3-4 adjectives.
- Trait 1 with behavioral description
- Trait 2 with behavioral description
- Trait 3 with behavioral description

## Voice Direction
- Pitch, cadence, speech patterns
- Language (Spanish primary for PopiLearn)
- IMPORTANT: never use ALL CAPS — chatterbox distorts capitalized words

## Animation Style
- Idle behavior
- Per-emotion animation notes (happy, sad, excited, etc.)

## Relationship to Other Characters
How this character interacts with the existing cast.

## Design Philosophy
Why the visual choices were made. How this character contrasts with others.

## What {Character Name} Is NOT
Boundaries for the character — things it should never do or be.
```
