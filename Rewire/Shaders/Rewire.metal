//
//  Rewire.metal
//  The app's living surfaces: background aurora, the training orb,
//  the rep-completion ripple, and the maturity "weave" celebration.
//
//  All entry points are [[stitchable]] so SwiftUI's default ShaderLibrary
//  finds them with zero build configuration. GLSL twins of these functions
//  live in prototype/shaders.js and must be kept in sync — the browser
//  prototype is where the look is audited.
//

#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

// MARK: - Noise toolkit -------------------------------------------------------

static inline float hash21(float2 p) {
    p = fract(p * float2(234.34, 435.345));
    p += dot(p, p + 34.23);
    return fract(p.x * p.y);
}

static inline float valueNoise(float2 p) {
    float2 i = floor(p);
    float2 f = fract(p);
    float2 u = f * f * (3.0 - 2.0 * f);
    float a = hash21(i);
    float b = hash21(i + float2(1.0, 0.0));
    float c = hash21(i + float2(0.0, 1.0));
    float d = hash21(i + float2(1.0, 1.0));
    return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

static inline float fbm(float2 p) {
    float v = 0.0;
    float amp = 0.5;
    float2x2 rot = float2x2(0.8, 0.6, -0.6, 0.8);
    for (int i = 0; i < 4; i++) {
        v += amp * valueNoise(p);
        p = rot * p * 2.03 + float2(11.7, 5.1);
        amp *= 0.5;
    }
    return v;
}

// MARK: - Aurora --------------------------------------------------------------
//
// Background field. Two very slow drifting hue clouds over deep ink.
// `tint` steers the palette toward the current context (stage hue while
// training, neutral indigo at home). `energy` briefly surges on celebrations.

[[ stitchable ]] half4 aurora(float2 position,
                              half4 color,
                              float2 size,
                              float time,
                              half4 tint,
                              float energy) {
    float2 uv = position / max(size.x, size.y);

    // Two drift fields on different clocks; a full loop takes ~90s.
    float t = time * 0.045;
    float n1 = fbm(uv * 2.1 + float2(t * 0.7, -t * 0.4));
    float n2 = fbm(uv * 3.3 + float2(-t * 0.5, t * 0.6) + 7.31);

    // Vertical weighting: light gathers low on the canvas, like a horizon.
    float horizon = smoothstep(0.1, 1.05, uv.y + n1 * 0.35);

    float3 ink = float3(0.027, 0.027, 0.047);           // #07070C
    float3 coolBase = float3(0.10, 0.10, 0.22);          // indigo undertone
    float3 tintRGB = float3(tint.rgb);

    float glow = n1 * n2;
    glow = glow * glow * (1.0 + energy * 2.2);

    float3 c = ink;
    c += coolBase * glow * 0.9 * horizon;
    c += tintRGB * glow * (0.55 + energy * 0.8) * horizon;

    // Fine grain keeps large gradients from banding.
    c += (hash21(position) - 0.5) * 0.012;

    return half4(half3(c), 1.0h);
}

// MARK: - Orb -----------------------------------------------------------------
//
// The living rep element. A plasma core inside a soft-edged disc.
//   charge    0…1  builds within a stage (tap → next stage resets & re-arms)
//   crossfade 0…1  hue morph from `hueA` (current stage) to `hueB` (next)
//   breathe   idle breathing amplitude (0 when Reduce Motion)
//   seed      per-rep noise offset — no two taps ever render identically
//   fire      1→0 impulse after a completed rep (flash + shockwave)

[[ stitchable ]] half4 orb(float2 position,
                           half4 color,
                           float2 size,
                           float time,
                           float charge,
                           float crossfade,
                           half4 hueA,
                           half4 hueB,
                           float breathe,
                           float seed,
                           float fire) {
    float2 uv = (position - size * 0.5) / (min(size.x, size.y) * 0.5);
    float r = length(uv);
    float angle = atan2(uv.y, uv.x);

    // Idle breath: 6 breaths/min. Charge swells the whole body.
    float breath = 1.0 + breathe * 0.035 * sin(time * 0.6283);
    float body = (0.60 + charge * 0.17) * breath;

    // Plasma interior — domain-warped fbm, seeded per rep.
    float2 pp = uv * (2.8 - charge * 0.8);
    float2 warp = float2(fbm(pp + seed * 3.7 + time * 0.11),
                         fbm(pp - seed * 2.9 - time * 0.13));
    float plasma = fbm(pp + warp * (1.2 + charge * 1.5) + float2(seed, -seed));

    // Ridged veins — the bright filament network in the interior.
    float veins = pow(clamp(1.0 - abs(2.0 * plasma - 1.0) * 1.35, 0.0, 1.0), 3.0);

    // Angular filaments sharpen as charge builds — the synapse gathering itself.
    float filaments = sin(angle * 6.0 + plasma * (6.0 + charge * 10.0)
                          + time * 0.8 + seed * 6.28);
    filaments = pow(max(0.0, filaments), 3.0) * charge * 0.45;

    // Core disc with a breathing soft edge.
    float edge = 0.05 + 0.06 * plasma;
    float disc = 1.0 - smoothstep(body - edge, body + edge * 0.5, r);

    // Limb darkening gives the disc volume.
    float limb = smoothstep(body * 1.02, body * 0.25, r);

    // Crisp rim that intensifies with charge; soft halo only outside the body.
    float rim = exp(-pow((r - body) * (15.0 - charge * 5.0), 2.0)) * (0.7 + charge * 0.9);
    float halo = exp(-max(0.0, r - body) * (4.5 - charge * 1.6)) * (0.10 + charge * 0.30);

    // Fire: an instant flash pop, then a shock ring that visibly leaves the body.
    float shockR = (1.0 - fire) * 1.8;
    float shockStrength = pow(max(0.0, fire * (1.0 - fire)) * 4.0, 1.6) * 0.9;
    float shock = exp(-pow((r - shockR) * 7.5, 2.0)) * shockStrength;
    float flash = pow(fire, 6.0) * disc * 1.3;

    // Hue morph between stages; interior runs deep → mid → veined bright.
    float3 cA = float3(hueA.rgb);
    float3 cB = float3(hueB.rgb);
    float3 hue = mix(cA, cB, smoothstep(0.0, 1.0, crossfade));
    float3 deep = hue * 0.12;
    float3 mid = hue * 0.40;
    float3 bright = hue + float3(0.30, 0.26, 0.22) * (0.30 + charge * 0.9);

    float3 c = mix(deep, mid, clamp(plasma * 1.25, 0.0, 1.0));
    c = mix(c, bright, clamp(veins * (0.30 + charge * 0.9) + filaments, 0.0, 1.0));
    c *= 0.35 + 0.65 * limb;
    c += hue * exp(-r * r / max(body * body * 0.16, 1e-4)) * (0.12 + charge * 0.55);
    c *= disc;
    c += hue * rim;
    c += hue * halo;
    c += (hue * 0.7 + 0.3) * shock;
    c += float3(1.0, 0.98, 0.94) * flash;

    // Premultiplied output: `c` is already the emitted light; alpha carries
    // the soft silhouette + effects (matches the audited GLSL compositing).
    float a = clamp(disc + rim * 0.9 + halo + shock, 0.0, 1.0);
    return half4(half3(min(c, 1.0)), half(a));
}

// MARK: - Ripple --------------------------------------------------------------
//
// Screen-space rep-completion wave, applied as a layerEffect on the training
// screen. Refraction + chromatic dispersion that decays with distance and
// time. `progress` runs 0→1 over ~1.1s.

[[ stitchable ]] half4 ripple(float2 position,
                              SwiftUI::Layer layer,
                              float2 size,
                              float2 center,
                              float progress,
                              float amplitude) {
    float2 toC = position - center;
    float dist = length(toC);
    float maxDist = length(size);

    float waveFront = progress * maxDist * 0.9;
    float band = dist - waveFront;

    // Gaussian wave packet, fading as it travels.
    float envelope = exp(-band * band / (2.0 * pow(38.0 + progress * 90.0, 2.0)));
    float decay = (1.0 - progress);
    float push = envelope * decay * decay * amplitude * 26.0;

    float2 dir = dist > 0.001 ? toC / dist : float2(0.0);
    float2 offset = dir * push;

    // Chromatic dispersion along the wavefront.
    half4 cr = layer.sample(position - offset * 1.25);
    half4 cg = layer.sample(position - offset);
    half4 cb = layer.sample(position - offset * 0.75);

    half4 c = half4(cr.r, cg.g, cb.b, cg.a);

    // A whisper of brightening right on the front.
    c.rgb += half3(envelope * decay * 0.10h);
    return c;
}

// MARK: - Weave ---------------------------------------------------------------
//
// Maturity-advancement celebration: luminous strands braiding around the
// vertical axis; they draw together as the new stage seals. `progress`
// 0→1 over ~2.8s.

[[ stitchable ]] half4 weave(float2 position,
                             half4 color,
                             float2 size,
                             float time,
                             half4 tint,
                             float progress) {
    float2 uv = (position - size * 0.5) / min(size.x, size.y);

    // Envelope: rise fast, hold, dissolve.
    float rise = smoothstep(0.0, 0.18, progress);
    float fall = 1.0 - smoothstep(0.55, 1.0, progress);
    float env = rise * fall;
    if (env < 0.003) { return half4(0.0h); }

    float t = time * 0.4 + progress * 3.0;
    float3 tintRGB = float3(tint.rgb);
    float3 acc = float3(0.0);

    for (int i = 0; i < 6; i++) {
        float fi = float(i);
        float phase = fi * 1.047 + t;
        float amp = (0.34 + 0.10 * sin(fi * 2.3 + t * 0.7)) * (1.0 - 0.45 * progress);
        float x = sin(uv.y * (2.2 + fi * 0.23) + phase) * amp;
        x += (fbm(float2(uv.y * 1.7, fi * 7.0 + t * 0.3)) - 0.5) * 0.25;
        float d = abs(uv.x - x);
        float core = exp(-d * d * 2200.0);
        float glow = exp(-d * d * 90.0) * 0.35;
        float shimmer = 0.55 + 0.45 * sin(phase * 1.7 + uv.y * 3.0);
        acc += (tintRGB * (0.55 + 0.45 * shimmer) + float3(0.5) * core * 0.5)
               * (core + glow);
    }

    // Dissolve near top/bottom; breathe room for the stage title at center.
    float vmask = smoothstep(1.05, 0.55, abs(uv.y));
    float titleDim = 1.0 - 0.55 * exp(-pow(uv.y * 2.6, 2.0));
    float3 c = acc * env * vmask * titleDim * 0.55;

    // Premultiplied: `c` is the emitted light; alpha from its luminance.
    float a = clamp(max(c.r, max(c.g, c.b)) * 1.4, 0.0, 1.0);
    return half4(half3(min(c, 1.0)), half(a));
}
