# Progress log

Working checklist — updated as work lands. (Newest at bottom.)

- [x] git init, .gitignore
- [x] DESIGN.md — design bible (color, type, motion, haptics, IA)
- [x] ARCHITECTURE.md — project layout, data model, rendering strategy
- [x] Models + Store (Pathway, EmotionPreset, PathwayStore)
- [x] Theme + core components
- [x] Metal shaders (aurora, orb, ripple, weave)
- [x] Haptics engine
- [x] Home feature
- [x] Training feature (orb, cue overlay, fire ripple)
- [x] Wizard (5 steps + blueprint)
- [x] Archive
- [x] Xcode project (pbxproj via synchronized root group, generated Info.plist keys, assets + generated icon)
- [x] Prototype: GLSL shader parity + interactive screen twins, freeze/step audit rig
- [x] Design audit pass — findings & fixes (all back-ported to Metal/Swift):
  - orb v1 read as "orange fruit" → v2: ridged veins, limb darkening, hot
    kernel, crisp rim, halo outside body only
  - fire flash blew out white too long → instant pop (fire^6) + shock ring
    that detaches and crosses the maturity arc
  - weave v1 read as polka-dot lattice → v2: six braiding strands, title
    breathing room
  - duplicate stage label under cue overlay → chrome fades during cue/celebration
  - wizard footer not pinned → fixed
  - live-verified: 4-tap rep loop, counters, 150-rep threshold crossing,
    celebration auto-dismiss, wizard validation, archive
- [x] Correctness pass: RepRipple re-pauses after wave (no perma-ticking),
  ripple centered on orb via visualEffect proxy (not UIScreen guess),
  orb seed constant within a rep, aurora paused under Reduce Motion
- [x] BUILD.md + README
