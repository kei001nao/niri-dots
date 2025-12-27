// Ghostty iChannel0 = terminal text/background
// iTime = time, iResolution = window size

float textAbberation() {
    return 18.0 * sin(0.5 * iTime);
}

float hash(vec2 p) { return fract(sin(dot(p, vec2(23.43, 54.31))) * 345123.54); }

// Very cheap smooth noise
float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    float a = hash(i);
    float b = hash(i + vec2(1,0));
    float c = hash(i + vec2(0,1));
    float d = hash(i + vec2(1,1));
    vec2 u = f*f*(3.0 - 2.0*f);
    return mix(mix(a,b,u.x), mix(c,d,u.x), u.y);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord ){
    vec2 uv = fragCoord.xy / iResolution.xy;

    // --- Base terminal background
    vec4 base = texture(iChannel0, uv);

    // --- Two slow-moving noise gradients
    float n1 = noise(uv * 3.0 + iTime * 0.24);
    float n2 = noise(uv * 3.0 - iTime * 0.12);
    float g  = smoothstep(0.2, 0.7, n1 * 0.4 + n2 * 0.2);

    // Red tone curve
    vec3 redfx = vec3(g * 0.9, g * 0.0, g * 0.0);

    // CRT scanlines
    float scan = -0.2 * sin(uv.y * iResolution.y * 2.75);
    redfx -= scan;

    vec2 px = 1.0 / iResolution.xy;

    // Small blur
    vec3 b1 = (
        texture(iChannel0, uv + vec2(px.x, 0)).rgb +
        texture(iChannel0, uv - vec2(px.x, 0)).rgb +
        texture(iChannel0, uv + vec2(0, px.y)).rgb +
        texture(iChannel0, uv - vec2(0, px.y)).rgb
    ) * 0.25;

    // Larger blur
    vec3 b2 = (
        texture(iChannel0, uv + vec2(px.x * textAbberation(), 0)).rgb +
        texture(iChannel0, uv - vec2(px.x * textAbberation(), 0)).rgb +
        texture(iChannel0, uv + vec2(0, px.y * 3.0)).rgb +
        texture(iChannel0, uv - vec2(0, px.y * 3.0)).rgb
    ) * 0.25;


    // Difference between the blurs pulls out edges & glyph shapes
    float glowMask = length(b1 - b2);

    // Boost
    glowMask = pow(glowMask, 0.6) * textAbberation();

    // Red/white glow color
    vec3 textGlow = vec3(1.0, -0.1, 0.2) * glowMask * 0.1;

    // --- Final blend
    float alpha = 0.06;   // adjust transparency here
    vec3 finalFx = mix(redfx, vec3(1.0), textGlow);
    vec4 fx = vec4(finalFx, alpha);

    fragColor = mix(base, fx, fx.a);
}
