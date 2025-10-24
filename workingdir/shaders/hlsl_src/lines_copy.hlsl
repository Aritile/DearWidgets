cbuffer PS_CONSTANT_BUFFER
{
    float2 p0;            // screen-space start
    float2 p1;            // screen-space end
    float  thickness;     // stroke width in pixels
    float  aa;            // AA fringe in pixels
    float2 dash;          // x=dash length, y=gap length
    float  dash_offset;   // offset in pixels
    float  cap;           // 0=butt, 1=square, 2=round
    float  join;          // reserved
    float  miter_limit;   // reserved
    float  pad0;          // padding
    float2 rect_min;      // quad min in screen space
    float2 rect_max;      // quad max in screen space
    float4 color;         // RGBA
};

cbuffer vertexBuffer
{
    float4x4 ProjectionMatrix;
};

struct VS_INPUT
{
    float2 pos : POSITION;
    float4 col : COLOR0;
    float2 uv  : TEXCOORD0;
};

struct PS_INPUT
{
    float4 pos : SV_POSITION;
    float4 col : COLOR0;
    float2 uv  : TEXCOORD0;
};

PS_INPUT main_vs(VS_INPUT input)
{
    PS_INPUT output;
    output.pos = mul(ProjectionMatrix, float4(input.pos.xy, 0.f, 1.f));
    output.col = input.col;
    output.uv  = input.uv;
    return output;
}

// Distance to oriented rectangle centered at c, with half extents b, local basis ex (unit), ey (unit)
float sdOrientedBox(float2 p, float2 c, float2 ex, float2 ey, float2 b)
{
    float2 rel = p - c;
    float2 q = float2(dot(rel, ex), dot(rel, ey));
    float2 d = abs(q) - b;
    return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0);
}

float sdCapsule(float2 p, float2 a, float2 b, float r)
{
    float2 pa = p - a, ba = b - a;
    float h = saturate(dot(pa, ba) / dot(ba, ba));
    return length(pa - ba * h) - r;
}

float2 perp(float2 v) { return float2(-v.y, v.x); }

float main_dash_mask(float s, float dash_len, float gap_len)
{
    float period = max(1e-5, dash_len + gap_len);
    float m = frac(s / period) * period;
    return (m <= dash_len) ? 1.0f : 0.0f;
}

float4 main_ps(PS_INPUT input) : SV_Target
{
    // Reconstruct pixel position in screen space from UV + rect
    float2 P = lerp(rect_min, rect_max, input.uv.xy);
    float2 ba = p1 - p0;
    float len = max(length(ba), 1e-5);
    float2 ex = ba / len;
    float2 ey = perp(ex);
    float halfw = 0.5 * thickness;

    // Signed distance to stroke shape (caps handled)
    float d;
    // ImWidgetsCap: 0=None,1=Butt,2=Square,3=Round
    if (cap < 1.5) // None/Butt -> butt
    {
        float2 c = 0.5 * (p0 + p1);
        float2 b = float2(0.5 * len, halfw);
        d = sdOrientedBox(P, c, ex, ey, b);
    }
    else if (cap < 2.5) // square
    {
        float2 c = 0.5 * (p0 + p1);
        float2 b = float2(0.5 * len + halfw, halfw);
        d = sdOrientedBox(P, c, ex, ey, b);
    }
    else // round (>= 2.5)
    {
        d = sdCapsule(P, p0, p1, halfw);
    }

    // Anti-aliased edge
    float alpha_edge = saturate(0.5 - d / max(aa, 1e-5));

    // Dash mask: project onto axis along segment (unclamped)
    float s = dot(P - p0, ex) + dash_offset;
    float m = main_dash_mask(s, dash.x, dash.y);

    float4 out_col = color;
    out_col.a *= alpha_edge * m;
    return out_col;
}
