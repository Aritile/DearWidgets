cbuffer PS_CONSTANT_BUFFER
{
%PS_CONSTANT_BUFFER%
};

cbuffer VB_CONSTANT_BUFFER
{
%VB_CONSTANT_BUFFER%
};

struct VS_INPUT
{
%VS_INPUT%
};

struct PS_INPUT
{
%PS_INPUT%
};

%PRE_FUNC%

PS_INPUT main_vs(VS_INPUT input)
{
	PS_INPUT output;

%VS_SHADER%

	return output;
}

float4 main_ps(PS_INPUT input) : SV_Target
{
	float2 uv = input.uv.xy;
	float4 col_in = input.col;
	float4 col_out = float4(1.0f, 1.0f, 1.0f, 1.0f);

%PS_SHADER%

	return col_out;
}

