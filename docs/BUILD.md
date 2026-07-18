# Building Rewire

Authored off-Mac (Windows), so the project was designed for a zero-fixup
first build. Two minutes on any Mac:

## Requirements
- Xcode 16 or newer
- iOS 18.0+ simulator or device (iPhone)

## Steps
1. `open Rewire.xcodeproj`
2. Xcode may prompt to set a development team for automatic signing
   (Signing & Capabilities → Team). Simulator builds usually need none.
3. Pick an iPhone simulator, ⌘R.

That's it — no packages, no scripts, no configuration. The project uses an
Xcode 16 file-system-synchronized root group, so every file under `Rewire/`
(including `Shaders/Rewire.metal` and `Assets.xcassets`) is part of the
target automatically; new files added to those folders join the build with
zero project edits.

## What to verify on first run (in order)
1. **Home** — aurora drifting slowly behind glass cards; empty state if no
   pathways.
2. **Wizard** — 5 steps; Continue stays disabled until each step's field is
   filled; emotion choice retints the whole flow.
3. **Training** — tap the orb: TRIGGER → NOTICE → ACCEPT → CHOOSE, each with
   a distinct haptic; the 4th tap fires the rep (flash + screen ripple +
   rising haptic arpeggio) and counters tick.
4. **Long-press the orb** — the chrome fades and the current stage's cue
   text appears in serif; release to dismiss.
5. **Maturity crossing** — at 50/150/400/1000 lifetime reps: aurora surge,
   braided-light celebration, new stage name.
6. **Reduce Motion on** — shaders freeze their drift, everything remains
   legible and functional.

## Known device-vs-simulator notes
- CoreHaptics is silent in the simulator; all patterns need a device.
- The rep ripple (`layerEffect`) renders in the simulator but its cost is
  only meaningful on device — it's mounted for 1.1s per rep.

## PWA (iPhone / installable web)

The interactive prototype in `prototype/` can run as a Progressive Web App.

### Local dev
```bash
cd prototype
python -m http.server 8080
```
Open http://localhost:8080/ on your phone (same Wi‑Fi) or use a tunnel for HTTPS testing.

### GitHub Pages (HTTPS)
1. Push to `master` — the workflow `.github/workflows/deploy-prototype-pages.yml` publishes `prototype/` to GitHub Pages.
2. In the repo on GitHub: **Settings → Pages → Build and deployment → Source: GitHub Actions**.
3. After the workflow succeeds, open the Pages URL (typically `https://<user>.github.io/Neural-Conditioning-App2/`).

### Install on iPhone
1. Open the HTTPS URL in **Safari**.
2. Share → **Add to Home Screen**.
3. Launch from the icon — standalone, full screen, data saved on device via `localStorage`.

Debug panel on phone: append `?debug=1` to the URL.

The shaders and screens were audited frame-by-frame in `prototype/index.html`
(open in any browser; use the debug panel to scrub fire/charge/celebration).
GLSL there and Metal here are kept 1:1 — if you tune one, tune both.
