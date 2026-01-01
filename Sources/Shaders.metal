#include <metal_stdlib>
using namespace metal;

// SwiftUI colorEffect shader'ları için imza:
// [[ stitchable ]] float4 function_name(float2 position, half4 color, float time)

[[ stitchable ]] half4 noise(float2 position, half4 color) {
    // Basit bir noise fonksiyonu
    float2 pos = position / 1000.0; // Koordinatları normalize et
    float n = fract(sin(dot(pos, float2(12.9898, 78.233))) * 43758.5453);
    
    // Orijinal renk ile karıştır
    return half4(half3(n), 1.0);
}

// Zaman parametresi alan versiyon (SwiftUI'dan time gönderilirse)
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
    float type, // 0: Linear, 1: Radial
    float direction, // 0: Horizontal, 1: Vertical, 2: Diagonal 1, 3: Diagonal 2...
    float3 targetColor,
    float distribution // 0: Linear, 1: Gamma/Non-Linear
) {
    float2 uv = position / size;
    float t = 0.0;

    // Gradient Tipi ve Yönü
    if (type == 0) { // Linear
        if (direction == 0) { // Horizontal
            t = uv.x;
        } else if (direction == 1) { // Vertical
            t = uv.y;
        } else if (direction == 2) { // Diagonal 1 (TL -> BR)
            t = (uv.x + uv.y) / 2.0;
        } else if (direction == 3) { // Diagonal 2 (BL -> TR)
            t = (uv.x + (1.0 - uv.y)) / 2.0;
        } else if (direction == 4) { // Diagonal 3 (TR -> BL)
            t = ((1.0 - uv.x) + uv.y) / 2.0;
        } else if (direction == 5) { // Diagonal 4 (BR -> TL)
            t = ((1.0 - uv.x) + (1.0 - uv.y)) / 2.0;
        }
    } else { // Radial
        float2 center = float2(0.5, 0.5);
        float dist = distance(uv, center);
        t = 1.0 - (dist * 2.0); // Merkezden dışa doğru
        t = clamp(t, 0.0, 1.0);
    }

    // Dağılım (Distribution) - Gamma Correction Simulation
    if (distribution > 0.5) {
        t = pow(t, 2.2);
    }

    // Adımlama (Stepping/Quantization)
    if (steps < 256) {
        t = floor(t * steps) / (steps - 1);
    }

        // Renk Karışımı

        half3 color = half3(targetColor) * half(t);

        return half4(color, 1.0);

    }

    

    float random(float2 st) {

        return fract(sin(dot(st.xy, float2(12.9898,78.233))) * 43758.5453123);

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

        float2 uv = position / size;

        

        // Aspec Ratio Correction for square characters

        float aspect = size.x / size.y;

        uv.x *= aspect;

        

        float columns = size.x / fontSize;

        float2 gridPos = uv * columns;

        float2 cellId = floor(gridPos);

        

        // Random speed and offset per column

        float rnd = random(float2(cellId.x, 0.0));

        float fallSpeed = (rnd * 0.5 + 0.5) * speed;

        float yOffset = time * fallSpeed + rnd * 100.0;

        

        // Character cycling simulation

        float charChangeSpeed = 10.0;


        // Vertical position in the trail

        float y = gridPos.y + yOffset;

        float yCell = floor(y);

        float relY = fract(y); // Position within the character

        

        // Trail length and brightness

        float trailLen = 10.0 + rnd * 10.0;

        float brightness = 1.0 - (fract(y / trailLen) * 1.0);

        

        // Make it discrete characters (gap between chars)

        if (relY > 0.8) brightness = 0.0; // Gap

        

        // "Head" glow (the leading character is brighter)

        float head = step(0.95, fract(y / trailLen));

        brightness += head * 0.5;

        

        // Random digital looking glpyh shape (very basic)

        float glyph = step(0.5, random(cellId + yCell));

        if (glyph < 0.1) brightness = 0.0;

        

        // Fade out trail

        brightness = clamp(brightness, 0.0, 1.0);

        brightness = pow(brightness, 3.0); // High contrast

        

        // Mix colors

        half3 finalColor = mix(half3(bgColor), half3(rainColor), half(brightness));

        

        // Head is white-ish

        if (head > 0.5 && brightness > 0.5) {

            finalColor = mix(finalColor, half3(1.0, 1.0, 1.0), 0.5);

        }

    

        return half4(finalColor, 1.0);

    }

    
