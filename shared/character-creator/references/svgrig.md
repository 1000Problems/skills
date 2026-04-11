# SVG Joint-Rig Architecture

How AnimationStudio characters are built and animated. This is the framework that produced
Rob the Robot and Baby Shark — two very different characters on the same underlying system.

## Core Concept

Every character is a tree of SVG `<g>` (group) elements. Each group has a fixed ID that the
animation player targets. The player doesn't know or care what the character looks like — it
just rotates, translates, and scales these groups according to animation data.

This means a robot arm and a fish fin animate identically: same group ID, same rotation math,
different SVG contents.

## Coordinate System

- **Origin (0,0)** is at the center of the character's body mass
- **Y increases downward** (SVG standard)
- The character root group is placed at a stage position via `translate(stageX, stageY)`
- Each joint group is positioned via `translate(jointX, jointY)` relative to the root
- Rotation happens around (0,0) in local group space — which means the joint IS the pivot

This local-pivot design is what makes articulation work naturally. When you rotate `leftArm`
by 30 degrees, it rotates around the shoulder point because the group's translate already
placed (0,0) at the shoulder.

## Required Joint Groups

Every character view SVG must contain these groups. The animation player will error if any
is missing.

| Group ID    | Purpose                                    | Animation Use                    |
|-------------|--------------------------------------------|---------------------------------|
| `#head`     | Upper face/head area                       | Tilt, nod (rotation around neck) |
| `#torso`    | Main body                                  | Squash/stretch (scale transform) |
| `#leftArm`  | Left appendage (arm, fin, wing, tentacle)  | Wave, spread, clap (rotation)   |
| `#rightArm` | Right appendage                            | Wave, spread, clap (rotation)   |
| `#leftLeg`  | Left lower appendage (leg, tail lobe)      | Walk, wiggle (rotation)         |
| `#rightLeg` | Right lower appendage                      | Walk, wiggle (rotation)         |
| `#faceLayer` | Empty container for expression injection  | Eyes, mouth, blush swapped here |

Optional:
| `#antenna`  | Top accessory (antenna, dorsal fin, ears)   | Spring secondary motion         |
| `#bellyScreen` | Chest display area (Rob-specific)       | Content display, zoom target    |

## SVG Structure Template

```xml
<svg xmlns="http://www.w3.org/2000/svg" viewBox="{vb}" width="{w}" height="{h}">
  <defs>
    <!-- Gradients, filters, clip paths -->
  </defs>

  <g id="{character}Group" filter="url(#shadow)">

    <!-- Draw order matters — back-to-front -->
    <g id="antenna" transform="translate({ax}, {ay})">...</g>

    <!-- Legs behind body -->
    <g id="leftLeg" transform="translate({llx}, {lly})">...</g>
    <g id="rightLeg" transform="translate({rlx}, {rly})">...</g>

    <!-- Arms can be behind or in front depending on character -->
    <g id="leftArm" transform="translate({lax}, {lay})">...</g>
    <g id="rightArm" transform="translate({rax}, {ray})">...</g>

    <!-- Body is the main shape -->
    <g id="torso">...</g>

    <!-- Head overlaps upper torso -->
    <g id="head">...</g>

    <!-- Face is always on top -->
    <g id="faceLayer">
      <!-- Default expression (happy) drawn here -->
    </g>

  </g>
</svg>
```

## Animation Model (30fps)

The prototype HTML includes a `renderFrame()` function called via `requestAnimationFrame`.
Each frame calculates transforms for every joint:

### Idle Animation

Every character has an idle loop that runs continuously. Typical parameters:

```javascript
// Body bob (breathing/floating)
const bobY = Math.sin(t * bobFreq) * bobAmount;
const bobRot = Math.sin(t * bobFreq * 0.67) * tiltAmount;

// Appendage sway (fins, arms hanging)
const appendageAngle = Math.sin(t * swayFreq) * swayAmount;

// Squash/stretch on torso
const squash = 1 + Math.sin(t * bobFreq) * squashAmount;
const stretch = 1 - Math.sin(t * bobFreq) * stretchAmount;

// Secondary motion (spring physics on antenna/dorsal/ears)
const secondaryAngle = Math.sin(t * springFreq + phaseOffset) * springAmount;
```

### One-Shot Animations

Triggered by actions (wave, jump, dance). They override idle transforms for their duration:

- **Wave:** Rotate one arm to a raised position, oscillate for duration, decay
- **Jump:** Squat phase (translate down) → launch (translate up with easeOutBack) →
  land (easeOutElastic bounce). Arms spread during airborne phase.
- **Dance:** Full-body rhythm with emphasized squash/stretch, alternating arm/leg movement

### Expression System

Expressions are swapped by clearing `#faceLayer` and redrawing with new SVG elements.
The prototype uses JavaScript drawing functions; the production system uses JSON definitions
that map to the same SVG primitives.

Key: expressions inject into faceLayer, they don't modify head or torso. This means expression
changes are independent of body animation.

## Design Language Contrast

The rig system is deliberately design-agnostic. The same joint system supports:

- **Geometric characters** (Rob): rectangles, straight lines, hard corners, mechanical joints
- **Organic characters** (Baby Shark): ellipses, curved paths, rounded everything, soft joints
- **Hybrid characters**: mix of both (e.g., a character with a round body but angular accessories)

The visual style lives entirely in the SVG content inside the groups. The animation math
doesn't change.

## Proven Pattern: HTML Prototype First

Both existing characters were built prototype-first:

1. Write a full HTML page with the character, animation loop, and expression switching
2. Iterate on the visual in a browser until it looks right
3. Extract the static SVG, skeleton coordinates, and expression data into production files

The prototype IS the design tool. It's faster to tweak SVG in a live HTML page than to
edit production JSON files and reload the Xcode app.
