# Rewire — Architecture

Target: **iOS 18.0+**, Swift 5.10, SwiftUI + Metal (SwiftUI ShaderLibrary),
CoreHaptics. No dependencies, no backend, no accounts.

## Project layout

```
Rewire.xcodeproj/            hand-written pbxproj using Xcode 16
                             file-system-synchronized groups (folder = target)
Rewire/
  App/
    RewireApp.swift          @main, environment wiring
    RootView.swift           nav shell, zoom transitions, ripple host
  Models/
    Pathway.swift            Codable domain model + MaturityStage + RepStage
    EmotionPreset.swift      curated emotions (hue + mantra suggestions)
  Store/
    PathwayStore.swift       @Observable source of truth, JSON persistence
                             (atomic writes to Application Support)
  Engine/
    Haptics.swift            CoreHaptics engine wrapper, named patterns
    ShaderPhase.swift        time/phase plumbing for TimelineView-driven shaders
  Design/
    Theme.swift              color tokens, typography, spacing, springs
    Components/              GlassCard, StatChip, ProgressThread, TrackedLabel,
                             RollingCounter, SerifPrompt, HueGrid …
  Shaders/
    Rewire.metal             aurora / orb / ripple / weave ([[stitchable]])
  Features/
    Home/                    HomeView, PathwayCard, StatsStrip
    Training/                TrainingView, OrbView, CueOverlay, FireRipple
    Wizard/                  WizardView + 5 step views + BlueprintView
    Archive/                 ArchiveView
prototype/                   HTML/WebGL 1:1 shader + screen prototypes
docs/                        this folder
```

## Data model

- `Pathway`: id, name, stimulus, oldFeelings, oldThoughts, oldBehavior,
  chosenEmotion (name + hue), mantra, createdAt, archivedAt?,
  lifetimeReps, repLog: [DayKey: Int] (calendar-day rep counts).
- Derived: maturity stage from lifetimeReps thresholds [0, 50, 150, 400, 1000];
  `practicedToday`, `todayReps`, `progressToNextStage`.
- `PathwayStore`: `@Observable` class; loads on init, debounced atomic save
  (write temp + replace) to `Application Support/rewire.json`. Everything
  on-device, private by default.

## Rendering strategy

- Background aurora: `TimelineView(.animation)` + `Rectangle().colorEffect`.
  Paused (static phase) when `accessibilityReduceMotion`.
- Orb: dedicated `OrbView` — a Canvas-sized rectangle with `colorEffect`
  driven by (time, charge, stageHueFrom, stageHueTo, crossfade, seed).
  Charge/crossfade animate via `Animatable` conformance on a view modifier
  so the shader receives *interpolated* uniforms every frame.
- Rep-fire ripple: `layerEffect` applied to the training screen root;
  parameterized by (center, elapsed) and removed after 1.1s.
- All shader entry points are `[[stitchable]]` in one `Rewire.metal` file —
  SwiftUI's default ShaderLibrary picks them up with zero build config.

## Navigation

Single `NavigationStack`. Home → Training uses `.navigationTransition(.zoom)`
(iOS 18) sourced from the pathway card via `.matchedTransitionSource`.
Wizard and Archive are sheets with custom detents/backgrounds.

## Why these choices

- **JSON over SwiftData:** trivial model graph, zero migration risk,
  fully inspectable, atomic-write safe.
- **@Observable over ObservableObject:** finer-grained invalidation; cards
  don't re-render when an unrelated pathway logs a rep.
- **Hand-written pbxproj with `PBXFileSystemSynchronizedRootGroup`:** the
  Xcode 16 format needs only ~8 objects and no per-file bookkeeping, so the
  project stays valid as files are added — essential when authoring off-Mac.

## Verification plan (authored on Windows)

1. GLSL prototype of every shader + interactive screen mockups in
   `prototype/` — audited frame-by-frame in a browser (this is where the
   design iteration actually happened).
2. Swift sources reviewed against iOS 18 API signatures.
3. `docs/BUILD.md` — 2-minute instructions to open & run on a Mac.
