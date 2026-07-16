# Rewire — Design Bible

*A mental rewiring trainer. Notice → Accept → Choose.*

Every decision in the app answers to one sentence: **it should feel like a
meditation object, not a productivity tool.** Calm, dark, luminous, alive.

---

## 1. Identity

- **Name:** Rewire
- **Tone:** personal, quiet, warm. Second person, few words. Never clinical,
  never gamified-cheesy. "43 reps today" not "🔥 43 REPS! KEEP IT UP!"
- **Metaphor:** each pathway is a *thread of light* being re-woven. The
  training orb is a synapse — it charges as you move through the stages and
  *fires* when a rep completes.

## 2. Color

The app is **dark-only by design** (a deliberate, meditative choice — like
Endel, not like Settings). Base canvas is not pure black; it is a deep
blue-black with a slow-breathing aurora shader behind everything.

| Token          | Value                | Use |
|----------------|----------------------|-----|
| `ink`          | `#07070C`            | canvas base |
| `inkRaised`    | `#101018` @ 72%      | glass card fill under blur |
| `textPrimary`  | `#F4F2EC` (warm white) | headings, numerals |
| `textSecondary`| `#8E8E9E`            | labels, captions |
| `textTertiary` | `#55555F`            | hints, disabled |
| `hairline`     | `#FFFFFF` @ 8%       | card strokes |

**Stage hues** (fixed, semantic — the emotional temperature of the rep cycle):

| Stage   | Hue                  | Feel |
|---------|----------------------|------|
| TRIGGER | ember `#FF5C39`      | heat, the old pattern |
| NOTICE  | gold `#FFC24B`       | attention, dawn |
| ACCEPT  | teal `#3EDDC5`       | breath, water |
| CHOOSE  | violet `#8B7BFF`     | agency, night sky |

A full rep is literally a journey from heat to cool — the orb's color
temperature falls as you move through the cycle. This is the core visual
storytelling of the app.

**Pathway identity hues:** each pathway gets one of 8 curated hues (chosen
from its preferred emotion, overridable). Used for home-card threads, progress
rings, and the training screen's ambient tint. All pass ≥ 4.5:1 on `ink` when
used as text.

## 3. Typography

- **Display / numerals:** SF Pro Rounded, heavy tracking-tight. Rep counts use
  monospaced digits (`.monospacedDigit()`) so counters don't jitter.
- **Mantras & cue text:** New York (serif). Serif = the "inner voice."
  This contrast (rounded UI vs serif voice) is the app's typographic signature.
- **Labels:** SF Pro, `.caption` sizes, uppercase with wide tracking (+1.5)
  for stage names and section headers.

## 4. Materials & depth

- Glass cards: `ultraThinMaterial` tinted with `inkRaised`, 28pt continuous
  corner radius, 1px inner hairline, *no drop shadows* (light comes from the
  aurora behind, so cards get a subtle top-edge glow instead).
- Nothing floats above content except the training orb's fire ripple.
- Depth is communicated by *luminance*, not shadow.

## 5. Motion

- All springs. Standard: `spring(response: 0.45, dampingFraction: 0.82)`.
  Bouncy (celebration): `(0.5, 0.68)`. Snappy (stage tap): `(0.3, 0.85)`.
- Home → Training: zoom transition (`.navigationTransition(.zoom)`) from the
  pathway card — the card *is* the training screen's seed.
- Every stage tap: orb charge animation + custom CoreHaptics pattern, all four
  distinct (see §7).
- Rep completion ("fire"): Metal ripple radiates from orb through the whole
  screen (layerEffect on the root), counter ticks with a rolling-digit
  animation, haptic is a three-transient rising arpeggio.
- Stage advancement (maturity): full-screen shader moment — the aurora surges,
  thread of light re-weaves, new stage name types on in serif.

## 6. Shaders (Metal, SwiftUI ShaderLibrary)

1. `aurora` — background. 3-octave value noise, two drifting hue fields,
   extremely slow (90s loop), 12% max luminance. Tinted by context
   (home = neutral indigo, training = current stage hue).
2. `orb` — the living rep element. Radial signed-distance core + fbm plasma,
   charge parameter 0…1 per stage, hue crossfade between stage colors,
   breathing at 6 breaths/min when idle.
3. `ripple` — screen-space rep-completion wave (layerEffect: chromatic
   dispersion + refraction falling off with radius).
4. `weave` — stage-advancement celebration; interference of two line fields.

Prototype parity: each shader is ported 1:1 to GLSL in `prototype/` and
audited in a browser before the Metal version is finalized.

## 7. Haptics (CoreHaptics)

| Event | Pattern |
|-------|---------|
| TRIGGER tap | single sharp transient (intensity 1.0, sharpness 0.9) — a strike |
| NOTICE tap | transient + 0.3s decaying continuous — a bell |
| ACCEPT tap | soft 0.6s continuous swell, low sharpness — an exhale |
| CHOOSE tap | two quick transients rising — resolution |
| Rep fire | 3-transient rising arpeggio + soft tail |
| Maturity advance | 1.2s composed pattern: rumble → silence beat → bright triple |
| Long-press cue reveal | gentle click on reveal + softer click on release |

## 8. Information architecture

```
Home ──(tap card, zoom)──▶ Training ──(swipe down / X)──▶ back
  │──(+ button, sheet)───▶ Wizard (5 steps) ──▶ Blueprint ──▶ Training
  │──(card context menu)─▶ Edit (same wizard, prefilled) / Archive
  └──(toolbar)───────────▶ Archive space (reactivate / delete)
```

- **Home:** greeting + aggregate strip (active pathways · total reps ·
  practiced today), then pathway cards. Card shows: name, maturity stage name,
  progress thread to next stage, today-practiced glyph (small filled spark).
- **Training:** 90% orb. Stage label above (uppercase, tracked). Rep counters
  below (today / lifetime, quiet). Long-press orb = cue overlay (stimulus /
  notice statement / accept prompts / emotion + mantra in serif). Progress to
  next maturity stage as a hairline arc around the orb.
- **Wizard steps:** 1 Name · 2 Stimulus · 3 Old reaction (feelings, thoughts,
  behavior) · 4 New response (emotion preset grid + mantra presets/custom) ·
  5 Blueprint review. One question per screen, big serif prompts, progress
  dots, back is always a swipe.

## 9. Maturity stages

| Stage | Reps | Symbol thought |
|-------|------|----------------|
| Disruption | 0 | the pattern is seen |
| Foundation | 50 | a new groove begins |
| Strengthening | 150 | the groove deepens |
| Stabilizing | 400 | the new path is default |
| Enlightenment | 1000 | the old pattern is a memory |

Progress to next stage is always visible but never numeric-first (thread/arc
first, numbers on inspection).

## 10. Micro-rules (sweat these)

- Numerals never jitter (monospaced digits everywhere counts appear).
- No system blue anywhere. Tint = current context hue.
- All touch targets ≥ 44pt; the orb is ≥ 220pt.
- Every screen has exactly one focal point.
- Text over shader = always behind a 40% ink scrim gradient.
- Reduce Motion honored: shaders keep rendering but stop translating;
  springs become opacity fades.
- Every tap of the training orb seeds the shader's noise phase with the rep
  count — no two taps ever render identically.
