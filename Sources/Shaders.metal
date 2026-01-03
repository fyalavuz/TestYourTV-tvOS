#include <metal_stdlib>
using namespace metal;

// Shared Helpers
float glsl_mod(float x, float y) {
    return x - y * floor(x / y);
}

float2 glsl_mod(float2 x, float y) {
    return x - y * floor(x / y);
}

float3 glsl_mod(float3 x, float y) {
    return x - y * floor(x / y);
}

float4 glsl_mod(float4 x, float y) {
    return x - y * floor(x / y);
}

float random(float2 st) {
    return fract(sin(dot(st.xy, float2(12.9898,78.233))) * 43758.5453123);
}

// --- Basic Noise Shaders ---

[[ stitchable ]] half4 noise(float2 position, half4 color) {
    float2 pos = position / 1000.0;
    float n = fract(sin(dot(pos, float2(12.9898, 78.233))) * 43758.5453);
    return half4(half3(n), 1.0);
}

[[ stitchable ]] half4 noise_animated(float2 position, half4 color, float time) {
    float n = fract(sin(dot(position + time, float2(12.9898, 78.233))) * 43758.5453);
    return half4(half3(n), 1.0);
}

[[ stitchable ]] half4 color_noise(float2 position, half4 color, float time) {
    float3 n;
    n.r = fract(sin(dot(position + time, float2(12.9898, 78.233))) * 43758.5453);
    n.g = fract(sin(dot(position + time + 10.0, float2(34.123, 56.456))) * 53123.123);
    n.b = fract(sin(dot(position + time + 20.0, float2(21.345, 87.654))) * 23456.789);
    return half4(half3(n), 1.0);
}

[[ stitchable ]] half4 pro_gradient(
    float2 position,
    half4 currentColor,
    float2 size,
    float steps,
    float type,
    float direction,
    float3 targetColor,
    float distribution
) {
    float2 uv = position / size;
    float t = 0.0;

    if (type == 0) { // Linear
        if (direction == 0) t = uv.x;
        else if (direction == 1) t = uv.y;
        else if (direction == 2) t = (uv.x + uv.y) / 2.0;
        else if (direction == 3) t = (uv.x + (1.0 - uv.y)) / 2.0;
        else if (direction == 4) t = ((1.0 - uv.x) + uv.y) / 2.0;
        else if (direction == 5) t = ((1.0 - uv.x) + (1.0 - uv.y)) / 2.0;
    } else { // Radial
        float2 center = float2(0.5, 0.5);
        float dist = distance(uv, center);
        t = 1.0 - (dist * 2.0);
        t = clamp(t, 0.0, 1.0);
    }

    if (distribution > 0.5) {
        t = pow(t, 2.2);
    }

    if (steps < 256) {
        t = floor(t * steps) / (steps - 1);
    }

    half3 color = half3(targetColor) * half(t);
    return half4(color, 1.0);
}

// --- Matrix Rain Shader ---

float2 matrix_rand(float2 uv, float time) {
    float2 a = uv * 652.6345 + float2(uv.y, uv.x) * 534.375;
    float2 b = time * 0.0000005 * dot(uv, float2(0.364, 0.934));
    float2 val = cos(a + b);
    return floor(abs(val - 0.001 * floor(val / 0.001)) * 16000.0);
}

float matrix_fallerSpeed(float col, float faller) {
    float val = cos(col * 363.435 + faller * 234.323);
    return (val - 0.1 * floor(val / 0.1)) * 1.0 + 0.3;
}

float matrix_glyph(float2 uv, float2 seed) {
    float2 grid = floor(uv * float2(4.0, 6.0));
    float n = fract(sin(dot(grid + seed, float2(12.9898, 78.233))) * 43758.5453);
    return step(0.5, n);
}

[[ stitchable ]] half4 matrix_rain(
    float2 position,
    half4 currentColor,
    float2 size,
    float time,
    float3 rainColor,
    float3 bgColor,
    float speed,
    float fontSize
) {
    float2 CELLS = size / fontSize;
    float FALLERHEIGHT = 12.0;
    
    float t = time * speed * 2.0;
    float2 uv = position / size;
    uv.y = 1.0 - uv.y; // Fix rain direction
    
    float2 oneOverCells = 1.0 / CELLS;
    float2 pix = uv - oneOverCells * floor(uv / oneOverCells);
    float2 cell = (uv - pix) * CELLS;
    
    pix = pix * CELLS * float2(0.8, 1.0) + float2(0.1, 0.0);
    
    float2 cell_rand = matrix_rand(cell, t);
    float c = matrix_glyph(pix, cell_rand);
    
    float b = 0.0;
    for (float i = 0.0; i < 14.0; i += 1.0) {
        float s = matrix_fallerSpeed(cell.x, i);
        float move = (t + i * 3534.34) * s;
        float m = move - FALLERHEIGHT * floor(move / FALLERHEIGHT);
        float f = 3.0 - cell.y * 0.05 - m;
        
        if (f > 0.0 && f < 1.0) {
            b += f;
        }
    }
    
    float3 finalColor = rainColor * c * b;
    return half4(half3(finalColor), 1.0);
}

// --- Infinite Cubes Shader ---

float3x3 ray_rotateY(float theta) {
    float c = cos(theta);
    float s = sin(theta);
    return float3x3(float3(c,0,s), float3(0,1,0), float3(-s,0,c));
}

float3x3 ray_rotateZ(float theta) {
    float c = cos(theta);
    float s = sin(theta);
    return float3x3(float3(c,-s,0), float3(s,c,0), float3(0,0,1));
}

float ray_sdBox(float3 p, float3 b) {
    float3 d = abs(p) - b;
    return min(max(d.x, max(d.y, d.z)), 0.0) + length(max(d, 0.0));
}

float ray_map(float3 p, float time) {
    float3 q = fmod(p, 2.5) - 1.25;
    float3x3 rot = ray_rotateY(time) * ray_rotateZ(time * 0.5);
    return ray_sdBox(rot * q, float3(0.4, 0.4, 0.4));
}

float3 ray_getNormal(float3 p, float time) {
    float d = ray_map(p, time);
    float2 e = float2(0.01, 0.0);
    float3 n = d - float3(
        ray_map(p - e.xyy, time),
        ray_map(p - e.yxy, time),
        ray_map(p - e.yyx, time)
    );
    return normalize(n);
}

float ray_march(float3 ro, float3 rd, float time) {
    float dO = 0.0;
    for(int i=0; i<64; i++) {
        float3 p = ro + rd * dO;
        float dS = ray_map(p, time);
        dO += dS;
        if(dO > 100.0 || dS < 0.01) break;
    }
    return dO;
}

[[ stitchable ]] half4 ray_marching(float2 position, half4 color, float2 size, float time) {
    float2 uv = (position - 0.5 * size) / size.y;
    uv.y = -uv.y; // Fix upside down
    float3 ro = float3(0, 0, -3.0 + time * 2.0);
    float3 rd = normalize(float3(uv, 1.0));
    float d = ray_march(ro, rd, time);
    float3 col = float3(0.0);
    
    if(d < 100.0) {
        float3 p = ro + rd * d;
        float3 n = ray_getNormal(p, time);
        float3 lightPos = float3(2.0, 2.0, -4.0 + time * 2.0);
        float3 l = normalize(lightPos - p);
        float diff = max(dot(n, l), 0.0);
        col = float3(diff);
        col = col * (0.5 + 0.5 * n);
        col = mix(col, float3(0.0), 1.0 - exp(-0.05 * d));
    }
    return half4(half3(col), 1.0);
}

// --- Starfield Shader ---

float2 star_hash(float2 p, float d) {
    float2 col1 = float2(1234.0, -53.0);
    float2 col2 = float2(457.0, -17.0);
    return fract(1e4 * sin(float2(dot(p, col1), dot(p, col2)) + d));
}

float star_layer(float2 U, float t) {
    float D = 8.0;
    float scale = exp2(t - 8.0) * D / (3.0 + t);
    U /= scale;
    float2 iU = ceil(U);
    float2 P = 0.2 + 0.6 * star_hash(iU, 0.0);
    float r = 9.0 * star_hash(iU, 1.0).x;
    
    // Proba of star: r < 1.0
    if (r > 1.0) return 0.0;
    
    float dist = length(P - fract(U));
    
    // Sharp core
    float intensity = 1.0 - smoothstep(0.0, 0.015, dist);
    // Soft halo
    intensity += (1.0 - smoothstep(0.0, 0.08, dist)) * 0.15;
    
    // Variation in brightness
    return intensity * (1.0 - r * 0.5);
}

[[ stitchable ]] half4 starfield(float2 position, half4 color, float2 size, float time) {
    float2 U = (position - 0.5 * size) / size.y;
    float D = 8.0;
    float Z = 3.0;
    float3 P = float3(-1.0, 0.0, 1.0) / 3.0;
    float3 t = fract(time / D + P + 0.5) - 0.5;
    float3 w = 0.5 + 0.5 * cos(6.28 * t);
    t = t * D + Z;
    
    float3 T;
    T.x = star_layer(U, t.x);
    T.y = star_layer(-U, t.y);
    T.z = star_layer(float2(U.y, U.x), t.z);
    
    float intensity = dot(w, T);
    
    // Ensure deep black background
    intensity = clamp(intensity, 0.0, 1.0);
    
    return half4(half3(intensity), 1.0);
}

// --- Spiral Shader ---

[[ stitchable ]] half4 spiral(float2 position, half4 color, float2 size, float time) {
    float2 uv = position / size.y;
    float aspect = size.x / size.y;
    float2 center = float2(aspect * 0.5, 0.5);
    float2 diff = center - uv;
    float r = length(diff);
    float a = atan2(diff.y, diff.x);
    float v = sin(100.0 * (sqrt(r) - 0.02 * a - 0.3 * time));
    v = clamp(v, 0.0, 1.0);
    return half4(half3(v), 1.0);
}

// --- Fractal Tunnel (Cyber City) Shader ---

[[ stitchable ]] half4 fractal_tunnel(float2 position, half4 color, float2 size, float time) {
    float2 uv = (2.0 * position - size) / size.y;
    float t = time * 0.2;
    
    // Adjusted camera path to avoid geometry clipping
    float3 ro = float3(0.0, 0.0, -1.5 + t * 4.0);
    float3 rd = normalize(float3(uv, 1.0));
    
    // Rotation
    float s = sin(t * 0.5);
    float c = cos(t * 0.5);
    float3x3 rot = float3x3(float3(c, s, 0), float3(-s, c, 0), float3(0, 0, 1));
    rd = rot * rd;
    
    float d = 0.0;
    float glow = 0.0;
    
    // Raymarching
    for(int i = 0; i < 64; i++) {
        float3 p = ro + rd * d;
        
        // Larger repetition grid
        float3 q = glsl_mod(p, 3.0) - 1.5;
        
        float shape = 0.0;
        float s_scale = 1.0;
        
        // Menger Sponge-like box folding with larger central void
        for(int j = 0; j < 3; j++) {
            q = abs(q);
            if (q.x < q.y) { float tmp = q.x; q.x = q.y; q.y = tmp; }
            if (q.x < q.z) { float tmp = q.x; q.x = q.z; q.z = tmp; }
            if (q.y < q.z) { float tmp = q.y; q.y = q.z; q.z = tmp; }
            
            q = q * 3.0 - 2.5; // Adjusted offset for larger void
            s_scale *= 3.0;
            q.z += sin(p.z * 0.5 + t) * 0.2;
        }
        
        float3 d3 = abs(q) - float3(1.0);
        float d_box = min(max(d3.x, max(d3.y, d3.z)), 0.0) + length(max(d3, 0.0));
        
        shape = d_box / s_scale;
        
        d += shape * 0.6;
        glow += 0.01 / (0.01 + abs(shape));
        
        if (d > 20.0 || abs(shape) < 0.005) break;
    }
    
    float3 col = float3(0.0);
    float3 neon1 = float3(0.0, 1.0, 1.0); 
    float3 neon2 = float3(1.0, 0.0, 1.0); 
    float3 glowC = mix(neon1, neon2, sin(d * 0.2 + t) * 0.5 + 0.5);
    
    col += glowC * glow * 0.05;
    col = mix(col, float3(0.05, 0.0, 0.1), 1.0 - exp(-d * 0.15));
    col = pow(col, float3(0.45));
    
    return half4(half3(col), 1.0);
}

// --- Digital Rain Shader ---

float rain_sphere(float2 coord, float2 pos, float r) {
    float2 d = pos - coord;
    return smoothstep(60.0, 0.0, dot(d, d) - r * r);
}

[[ stitchable ]] half4 digital_rain(float2 position, half4 color, float2 size, float time) {
    float falling_speed = 0.25;
    float stripes_factor = 5.0;
    float2 uv = position / size;
    uv.y = 1.0 - uv.y; // Fix upside down
    
    float2 clamped_uv = (round(position / stripes_factor) * stripes_factor) / size;
    float value = fract(sin(clamped_uv.x) * 43758.5453123);
    float y_term = uv.y * 0.5 + (time * (falling_speed + value / 5.0)) + value;
    float mod_y = y_term - 0.5 * floor(y_term / 0.5);
    
    float3 col = float3(1.0 - mod_y);
    
    // Neon Color Palette: Pink/Purple/Cyan
    float3 neonColors = float3(0.8, 0.2, 1.0); // Base Purple
    float3 shift = 0.5 + 0.5 * cos(time + uv.xyx + float3(0, 2, 4));
    col *= mix(neonColors, float3(0.2, 0.8, 1.0), shift.x); // Mix with Cyan
    
    float move_term = (time * (falling_speed + value / 5.0)) + value;
    float mod_move = move_term - 0.5 * floor(move_term / 0.5);
    float2 sphere_pos = float2(clamped_uv.x, (1.0 - 2.0 * mod_move)) * size;
    
    col += float3(rain_sphere(position, sphere_pos, 0.9)) * 0.8;
    float fade = exp(-pow(abs(uv.y - 0.5), 6.0) / pow(2.0 * 0.05, 2.0));
    col *= float3(fade);
    
    return half4(half3(col), 1.0);
}

// --- Infinite Pipes (Optimized) Shader ---

[[ stitchable ]] half4 noodles(float2 position, half4 color, float2 size, float time) {
    float2 p = (2.0 * position - size) / size.y;
    p.y = -p.y; // Fix upside down
    float3 ro = float3(0.0, 0.0, time * 2.0);
    float3 rd = normalize(float3(p, 1.5));
    
    float ang = time * 0.1;
    float c = cos(ang); float s = sin(ang);
    rd.xy = float2(rd.x * c - rd.y * s, rd.x * s + rd.y * c);
    
    float d = 0.0;
    float3 pos = ro;
    
    for (int i = 0; i < 40; i++) { 
        float3 q = glsl_mod(pos, 2.0) - 1.0;
        float d1 = length(q.xy) - 0.2;
        float d2 = length(q.xz) - 0.2;
        float d3 = length(q.yz) - 0.2;
        float dist = min(d1, min(d2, d3));
        dist -= 0.05 * sin(pos.z * 5.0 + time);
        d += dist * 0.5; 
        pos = ro + rd * d;
        if (dist < 0.01 || d > 30.0) break;
    }
    
    float3 col = float3(0.0);
    if (d < 30.0) {
        float3 q = floor(pos / 2.0);
        float tint = fract(sin(dot(q, float3(12.9898, 78.233, 45.164))) * 43758.5453);
        col = float3(0.8, 0.4, 0.1) * tint + float3(0.1, 0.2, 0.5);
        col *= 1.0 / (1.0 + d * 0.1); 
    }
    return half4(half3(col), 1.0);
}

// --- Spectral Flow (Enhanced) Shader ---

[[ stitchable ]] half4 spectral(float2 position, half4 color, float2 size, float time) {
    float2 uv = (position / size) * 2.0 - 1.0;
    uv.x *= size.x / size.y;
    
    float v = 0.0;
    v += sin(uv.x * 10.0 + time);
    v += sin(uv.y * 10.0 + time * 0.5);
    v += sin((uv.x + uv.y) * 10.0 + time * 0.7);
    v += cos(length(uv) * 20.0 - time * 2.0);
    v *= 0.5;
    
    float3 col = 0.5 + 0.5 * cos(v + float3(0.0, 2.0, 4.0) + time * 0.2);
    col += smoothstep(0.8, 1.0, sin(v * 5.0)) * 0.5;
    return half4(half3(col), 1.0);
}

// --- Synth Terrain (Blueprint Style) Shader ---

[[ stitchable ]] half4 synth_terrain(float2 position, half4 color, float2 size, float time) {
    float2 p = (position - 0.5 * size) / size.y;
    p.y = -p.y; // Fix upside down
    
    float horizon = 0.1;
    float fov = 0.5;
    
    if (p.y > horizon) {
        return half4(0.0, 0.0, 0.1, 1.0);
    }
    
    float z = fov / (horizon - p.y);
    float x = p.x * z;
    
    z += time * 3.0;
    
    float gridX = abs(fract(x) - 0.5);
    float gridZ = abs(fract(z) - 0.5);
    float line = smoothstep(0.45, 0.5, max(gridX, gridZ));
    
    float wave = sin(x * 0.2 + z * 0.1 + time) * 2.0;
    if (p.y > horizon - (wave * 0.01 / z)) {
        // Sky depth near horizon
    }
    
    float3 bg = float3(0.0, 0.05, 0.25); 
    float3 fg = float3(0.4, 0.8, 1.0); 
    float fog = 1.0 / (z * 0.1 + 1.0);
    
    float3 col = mix(bg, fg, line * fog);
    return half4(half3(col), 1.0);
}

// --- Hyper Ring (Optimized) Shader ---

[[ stitchable ]] half4 hyper_ring(float2 position, half4 color, float2 size, float time) {
    float2 p = (2.0 * position - size) / min(size.x, size.y);
    float r = length(p);
    float a = atan2(p.y, p.x);
    
    float ringRadius = 0.6 + 0.05 * sin(time * 2.0 + a * 4.0);
    float thickness = 0.02 + 0.01 * sin(time * 3.0);
    float dist = abs(r - ringRadius) - thickness;
    
    float glow = 0.015 / (abs(dist) + 0.002);
    float3 col = 0.5 + 0.5 * cos(time + a + float3(0.0, 2.0, 4.0));
    col *= glow;
    col += float3(1.0) * smoothstep(0.01, 0.0, abs(dist));
    
    return half4(half3(col), 1.0);
}

// --- Color Twist (Liquid Spiral) Shader ---

[[ stitchable ]] half4 color_twist(float2 position, half4 color, float2 size, float time) {
    float2 uv = (position - 0.5 * size) / min(size.x, size.y);
    float r = length(uv);
    float a = atan2(uv.y, uv.x);
    float2 p = float2(log(r), a);
    p.x -= time * 0.3;
    float twistAmount = 3.0 + 2.0 * sin(time * 0.3);
    p.y += p.x * 0.5 + r * twistAmount; 
    float val = sin(p.y * 8.0 + sin(p.x * 8.0 + time));
    float3 c1 = float3(1.0, 0.4, 0.1); 
    float3 c2 = float3(0.5, 0.0, 0.8); 
    float3 c3 = float3(0.0, 0.8, 0.9); 
    float t1 = sin(val + r * 3.0 + time) * 0.5 + 0.5;
    float t2 = cos(val * 0.5 - a * 2.0) * 0.5 + 0.5;
    float3 col = mix(c1, c2, t1);
    col = mix(col, c3, t2 * 0.8);
    col *= smoothstep(0.0, 0.15, r);
    col *= 1.0 - r * 0.3;
    return half4(half3(col), 1.0);
}

// --- Polar Lattice Shader ---

[[ stitchable ]] half4 polar_lattice(float2 position, half4 color, float2 size, float time) {
    float2 U = 2.0 * position - size;
    float T = 6.2832;
    float zoom = 30.0 + 10.0 * sin(time * 0.5);
    float l = length(U) / zoom;
    float L = ceil(l) * 6.0;
    float rot_speed = (fract(L * 0.123) - 0.5) * 2.0; 
    float angle_offset = time * 1.5 * rot_speed;
    float a = atan2(U.x, U.y) + angle_offset;
    float3 col = 0.6 + 0.4 * cos(floor(fract(a / T) * L) + float3(0.0, 2.0, 4.0) + time);
    float pat = max(0.0, 9.0 * max(cos(T * l + time), cos(a * L)) - 8.0);
    col = col - pat;
    return half4(half3(col), 1.0);
}

// --- Nebula Flow (Advanced Noise) Shader ---

float nebula_random(float2 st) {
    return fract(sin(dot(st.xy, float2(12.9898, 78.233))) * 43758.5453123);
}

float nebula_noise(float2 st) {
    float2 i = floor(st);
    float2 f = fract(st);
    float a = nebula_random(i);
    float b = nebula_random(i + float2(1.0, 0.0));
    float c = nebula_random(i + float2(0.0, 1.0));
    float d = nebula_random(i + float2(1.0, 1.0));
    float2 u = f * f * (3.0 - 2.0 * f);
    return mix(a, b, u.x) + (c - a)* u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}

float nebula_fbm(float2 st) {
    float v = 0.0;
    float a = 0.5;
    float2 shift = float2(100.0);
    float2x2 rot = float2x2(cos(0.5), sin(0.5), -sin(0.5), cos(0.50));
    for (int i = 0; i < 5; ++i) {
        v += a * nebula_noise(st);
        st = rot * st * 2.0 + shift;
        a *= 0.5;
    }
    return v;
}

[[ stitchable ]] half4 noise_cloud(float2 position, half4 color, float2 size, float time) {
    float2 st = position / min(size.x, size.y) * 3.0;
    st.y = 3.0 - st.y; 
    float t = time * 0.5; 
    float2 q = float2(0.0);
    q.x = nebula_fbm(st + 0.00 * t);
    q.y = nebula_fbm(st + float2(1.0));
    float2 r = float2(0.0);
    r.x = nebula_fbm(st + 1.0 * q + float2(1.7, 9.2) + 0.15 * t);
    r.y = nebula_fbm(st + 1.0 * q + float2(8.3, 2.8) + 0.126 * t);
    float f = nebula_fbm(st + r);
    float3 c1 = float3(0.5, 0.5, 0.5);
    float3 c2 = float3(0.5, 0.5, 0.5);
    float3 c3 = float3(1.0, 1.0, 1.0);
    float3 c4 = float3(0.0, 0.33, 0.67);
    float3 color_mix = c1 + c2 * cos(6.28318 * (c3 * f + c4 + time * 0.1));
    float3 finalColor = mix(float3(0.0, 0.0, 0.05), color_mix, clamp((f * f) * 4.0, 0.0, 1.0));
    finalColor += float3(0.1) * length(q);
    return half4(half3(finalColor), 1.0);
}

// --- Neural Network Shader ---

float neural_hash21(float2 p) {
    float3 a = fract(float3(p.x, p.y, p.x) * float3(213.897, 653.453, 253.098));
    a += dot(a, a.yzx + 79.76);
    return fract((a.x + a.y) * a.z);
}

float2 neural_getPos(float2 id, float2 offs, float t) {
    float n = neural_hash21(id + offs);
    float n1 = fract(n * 10.0);
    float n2 = fract(n * 100.0);
    float a = t + n;
    return offs + float2(sin(a * n1), cos(a * n2)) * 0.4;
}

float neural_df_line(float2 a, float2 b, float2 p) {
    float2 pa = p - a, ba = b - a;
    float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
    return length(pa - ba * h);
}

float neural_line(float2 a, float2 b, float2 uv) {
    float r1 = 0.04;
    float r2 = 0.01;
    float d = neural_df_line(a, b, uv);
    float d2 = length(a - b);
    float fade = smoothstep(1.5, 0.5, d2);
    fade += smoothstep(0.05, 0.02, abs(d2 - 0.75));
    return smoothstep(r1, r2, d) * fade;
}

float neural_layer(float2 st, float n, float t) {
    float2 id = floor(st) + n;
    st = fract(st) - 0.5;
    
    float2 p[9];
    int i = 0;
    for(float y = -1.0; y <= 1.0; y++) {
        for(float x = -1.0; x <= 1.0; x++) {
            p[i++] = neural_getPos(id, float2(x, y), t);
        }
    }
    
    float m = 0.0;
    float sparkle = 0.0;
    
    for(int j = 0; j < 9; j++) {
        m += neural_line(p[4], p[j], st);
        float d = length(st - p[j]);
        float s = (0.005 / (d * d));
        s *= smoothstep(1.0, 0.7, d);
        float pulse = sin((fract(p[j].x) + fract(p[j].y) + t) * 5.0) * 0.4 + 0.6;
        pulse = pow(pulse, 20.0);
        s *= pulse;
        sparkle += s;
    }
    
    m += neural_line(p[1], p[3], st);
    m += neural_line(p[1], p[5], st);
    m += neural_line(p[7], p[5], st);
    m += neural_line(p[7], p[3], st);
    
    float sPhase = (sin(t + n) + sin(t * 0.1)) * 0.25 + 0.5;
    sPhase += pow(sin(t * 0.1) * 0.5 + 0.5, 50.0) * 5.0;
    m += sparkle * sPhase;
    
    return m;
}

[[ stitchable ]] half4 neural_network(float2 position, half4 color, float2 size, float time) {
    float2 uv = (position - 0.5 * size) / size.y;
    float t = time * 0.1;
    
    float s = sin(t);
    float c = cos(t);
    float2x2 rot = float2x2(c, -s, s, c);
    float2 st = rot * uv; // Metal matrix mult: M * v
    
    float m = 0.0;
    for(float i = 0.0; i < 1.0; i += 0.25) {
        float z = fract(t + i);
        float layerSize = mix(15.0, 1.0, z);
        float fade = smoothstep(0.0, 0.6, z) * smoothstep(1.0, 0.8, z);
        m += fade * neural_layer(st * layerSize - z, i, time);
    }
    
    float3 baseCol = float3(s, cos(t * 0.4), -sin(t * 0.24)) * 0.4 + 0.6;
    float3 col = baseCol * m;
    
    return half4(half3(col), 1.0);
}

// --- Fractal Pyramid Shader ---

float3 pyramid_palette(float d) {
    return mix(float3(0.2, 0.7, 0.9), float3(1.0, 0.0, 1.0), d);
}

float2 pyramid_rotate(float2 p, float a) {
    float c = cos(a);
    float s = sin(a);
    return float2(p.x * c - p.y * s, p.x * s + p.y * c);
}

float pyramid_map(float3 p, float time) {
    for(int i = 0; i < 8; ++i) {
        float t = time * 0.2;
        float2 xz = pyramid_rotate(p.xz, t);
        p.x = xz.x; p.z = xz.y;
        
        float2 xy = pyramid_rotate(p.xy, t * 1.89);
        p.x = xy.x; p.y = xy.y;
        
        p.xz = abs(p.xz);
        p.xz -= 0.5;
    }
    return dot(sign(p), p) / 5.0;
}

[[ stitchable ]] half4 fractal_pyramid(float2 position, half4 color, float2 size, float time) {
    float2 uv = (position - 0.5 * size) / size.x;
    float3 ro = float3(0.0, 0.0, -50.0);
    
    // Rotate camera
    float2 xz = pyramid_rotate(ro.xz, time);
    ro.x = xz.x; ro.z = xz.y;
    
    float3 cf = normalize(-ro);
    float3 cs = normalize(cross(cf, float3(0.0, 1.0, 0.0)));
    float3 cu = normalize(cross(cf, cs));
    
    float3 uuv = ro + cf * 3.0 + uv.x * cs + uv.y * cu;
    float3 rd = normalize(uuv - ro);
    
    float t = 0.0;
    float3 col = float3(0.0);
    float d = 0.0;
    
    for(float i = 0.0; i < 64.0; i++) {
        float3 p = ro + rd * t;
        d = pyramid_map(p, time) * 0.5;
        if (d < 0.02 || d > 100.0) break;
        col += pyramid_palette(length(p) * 0.1) / (400.0 * d);
        t += d;
    }
    
    return half4(half3(col), 1.0);
}
