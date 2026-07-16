# Rewire

*A mental rewiring trainer for iOS. Notice → Accept → Choose.*

Rewire helps you dissolve unwanted stimulus→reaction patterns (road rage,
doomscrolling, snapping at the kids) by deliberately rehearsing a designed
replacement response until the new pathway is the default one.

- **Blueprint wizard** — name the pattern, capture the trigger and the old
  reaction (feeling / thinking / doing), choose a preferred emotion and a
  mantra, review the blueprint.
- **Training loop** — one living, Metal-rendered orb. Tap through
  TRIGGER → NOTICE → ACCEPT → CHOOSE; the fourth tap *fires* the rep with a
  screen-wide ripple and a rising haptic arpeggio. Long-press to reveal the
  stage's cue text. No two taps ever render identically.
- **Maturity** — every pathway grows through Disruption → Foundation →
  Strengthening → Stabilizing → Enlightenment as reps accumulate, celebrated
  with a braided-light shader moment.
- **Private by design** — everything lives in one JSON file on device.
  No account, no backend, no analytics.

**Tech:** SwiftUI + SwiftUI ShaderLibrary (4 custom Metal shaders),
CoreHaptics (7 bespoke patterns), Observation. iOS 18+, zero dependencies.

| Doc | What's in it |
|-----|--------------|
| [docs/BUILD.md](docs/BUILD.md) | 2-minute build & verification guide |
| [docs/DESIGN.md](docs/DESIGN.md) | the design bible — color, type, motion, haptics |
| [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) | project layout & rendering strategy |
| [prototype/index.html](prototype/index.html) | interactive design-audit twin (GLSL ports of all shaders) |

Built end-to-end on Windows; the visual design was audited frame-by-frame
through the WebGL prototype, which stays 1:1 with the Metal source.
