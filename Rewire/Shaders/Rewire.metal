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
    float body = (0.62 + charge * 0.16) * breath;

    // Plasma interior — domain-warped fbm, seeded per rep.
    float2 pp = uv * (2.6 - charge * 0.7);
    float2 warp = float2(fbm(pp + seed * 3.7 + time * 0.11),
                         fbm(pp - seed * 2.9 - time * 0.13));
    float plasma = fbm(pp + warp * (1.1 + charge * 1.4) + float2(seed, -seed));

    // Filaments sharpen as charge builds — the synapse gathering itself.
    float filaments = sin(angle * 6.0 + plasma * (6.0 + charge * 10.0)
                          + time * 0.8 + seed * 6.28);
    filaments = pow(max(0.0, filaments), 3.0) * charge * 0.5;

    // Core disc with a breathing soft edge.
    float edge = 0.10 + 0.10 * plasma;
    float disc = 1.0 - smoothstep(body - edge, body + edge * 0.6, r);

    // Rim: thin bright ring that intensifies with charge.
    float rim = exp(-pow((r - body) * (9.0 - charge * 3.0), 2.0));
    rim *= 0.55 + charge * 0.9;

    // Outer halo, very soft.
    float halo = exp(-r * (3.4 - charge * 1.1)) * (0.16 + charge * 0.22);

    // Fire: expanding shockwave ring + whole-body flash.
    float fireR = (1.0 - fire) * 1.65;
    float shock = exp(-pow((r - fireR) * 7.0, 2.0)) * fire * 1.6;
    float flash = fire * fire * disc * 1.2;

    // Hue morph between stages; interior varies between deep & bright.
    float3 cA = float3(hueA.rgb);
    float3 cB = float3(hueB.rgb);
    float3 hue = mix(cA, cB, smoothstep(0.0, 1.0, crossfade));
    float3 deep = hue * 0.22;
    float3 bright = hue + float3(0.25, 0.22, 0.2) * (0.4 + charge);

    float interior = plasma * (0.55 + charge * 0.75) + filaments;
    float3 c = mix(deep, bright, clamp(interior, 0.0, 1.0)) * disc;
    c += hue * rim;
    c += hue * halo;
    c += (hue * 0.7 + 0.3) * shock;
    c += float3(1.0, 0.98, 0.94) * flash;

    // Premultiplied output; alpha carries the soft silhouette + effects.
    float a = clamp(disc + rim * 0.9 + halo + shock, 0.0, 1.0);
    return half4(half3(c), 1.0h) * half(a);
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
// Maturity-advancement celebration: two interfering line fields that braid
// into a bright lattice, then dissolve. `progress` 0→1 over ~2.4s.

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

    float drift = time * 0.35 + progress * 2.0;
    float n = fbm(uv * 3.0 + drift * 0.2);

    // Two thread fields at opposing angles, warped by noise.
    float f1 = sin((uv.x * 0.9 + uv.y * 0.42) * 34.0 + n * 5.0 + drift);
    float f2 = sin((uv.x * -0.5 + uv.y * 0.95) * 30.0 - n * 4.0 - drift * 1.2);

    float threads = pow(max(0.0, f1), 6.0) + pow(max(0.0, f2), 6.0);
    float lattice = pow(max(0.0, f1 * f2), 3.0) * 2.2;

    // Radial mask keeps energy centered, with noise-torn edges.
    float mask = 1.0 - smoothstep(0.15, 0.75 + n * 0.2, length(uv));

    float3 tintRGB = float3(tint.rgb);
    float3 c = tintRGB * (threads * 0.5 + lattice) * mask * env;
    c += float3(1.0, 0.97, 0.9) * lattice * mask * env * 0.35;

    float a = clamp((threads * 0.4 + lattice) * mask * env, 0.0, 1.0);
    return half4(half3(c), 1.0h) * half(a * 0.85);
}
