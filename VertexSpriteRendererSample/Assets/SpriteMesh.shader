// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "Custom/SpriteMesh"
{
	Properties
	{
		_MainTex("Texture", 2D) = "white" {}
		_Size("Size", Float) = 1
		_Color("Color", Color) = (1,1,1,1)
		_Fade("Fade", Float) = 1

	}
		SubShader
		{ Tags {"Queue" = "Transparent" "RenderType" = "Transparent" }
				LOD 100

				ZWrite Off
				Blend SrcAlpha OneMinusSrcAlpha
			//Blend One One
		Pass
		{
			CGPROGRAM

			#pragma target 5.0
			#pragma vertex vert
			#pragma geometry gsSPRITE
			#pragma fragment frag

			#include "UnityCG.cginc"

			struct VS_OUT {
				float4 PosWVP:SV_POSITION;
				float2 TexCd:TEXCOORD0;
				float4 PosW:TEXCOORD1;
				float Size : TEXCOORD2;
				float4 Color:COLOR0;
				uint iid : IID;
			};

			struct VS_IN
			{
				float4 vertex : POSITION;
				uint iv:SV_VertexID;
				uint iid:SV_InstanceID;
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;
			float _Size;
			fixed4 _Color;
			float _Fade;

			float rand(float3 co)
			{
				return frac(sin(dot(co.xyz, float3(12.9898, 78.233, 56.787))) * 43758.5453);
			}

			VS_OUT vert(VS_IN In)
			{
				VS_OUT Out = (VS_OUT)0;

				float4 vPos = In.vertex;

				float4 PosW = mul(unity_ObjectToWorld, vPos);
				Out.PosW = PosW;
				Out.PosWVP = mul(UNITY_MATRIX_VP, PosW);
				float size = lerp(0, _Size, _Fade);
				Out.Size = size * pow(lerp(0, 5, abs(sin(rand(float3((float)In.iv, 0, 1)) * 10 + _Time.z))), 2.5);
				Out.Color = _Color;
				Out.iid = In.iv;
				return Out;
			}

			const static float3 g_positions[4] = { { -1,1,0 },{ 1,1,0 },{ -1,-1,0 },{ 1,-1,0 } };
			const static float2 g_texcoords[4] = { { 0,0 },{ 1,0 },{ 0,1 },{ 1,1 } };

			float4x4 Inverse(float4x4 input)
			{
				#define minor(a,b,c) determinant(float3x3(input.a, input.b, input.c))
				//determinant(float3x3(input._22_23_23, input._32_33_34, input._42_43_44))

				float4x4 cofactors = float4x4(
					minor(_22_23_24, _32_33_34, _42_43_44),
					-minor(_21_23_24, _31_33_34, _41_43_44),
					minor(_21_22_24, _31_32_34, _41_42_44),
					-minor(_21_22_23, _31_32_33, _41_42_43),

					-minor(_12_13_14, _32_33_34, _42_43_44),
					minor(_11_13_14, _31_33_34, _41_43_44),
					-minor(_11_12_14, _31_32_34, _41_42_44),
					minor(_11_12_13, _31_32_33, _41_42_43),

					minor(_12_13_14, _22_23_24, _42_43_44),
					-minor(_11_13_14, _21_23_24, _41_43_44),
					minor(_11_12_14, _21_22_24, _41_42_44),
					-minor(_11_12_13, _21_22_23, _41_42_43),

					-minor(_12_13_14, _22_23_24, _32_33_34),
					minor(_11_13_14, _21_23_24, _31_33_34),
					-minor(_11_12_14, _21_22_24, _31_32_34),
					minor(_11_12_13, _21_22_23, _31_32_33)
					);
				#undef minor
				return transpose(cofactors) / determinant(input);
			}

			[maxvertexcount(4)]
			void gsSPRITE(point VS_OUT In[1], inout TriangleStream<VS_OUT> SpriteStream)
			{
				VS_OUT Out = In[0];
				Out.iid = In[0].iid;
				for (int i = 0; i < 4; i++) {
					Out.TexCd = g_texcoords[i].xy;
					Out.PosWVP = mul(UNITY_MATRIX_VP, float4(In[0].PosW.xyz + In[0].Size*mul((float3x3)Inverse(UNITY_MATRIX_V), float4(g_positions[i].xyz, 1)), 1));
					SpriteStream.Append(Out);
				}
			}

			float4 col = float4(1,0,0,1);
			fixed4 frag(VS_OUT In) : SV_Target
			{
				if (length(In.TexCd.xy - .5) > 0.5) discard;
				float2 pos = In.TexCd.xy * 2 - 1;

				fixed4 c = In.Color;
				float gamma = 20;
				//float ease = pow(cos(3.1415 * length(pos) / 2.0), gamma);
				float ease = pow(min(cos(3.1415 * length(pos) / 2.0), 1.0 - abs(length(pos))), gamma);
				c.a = ease;

				//if (alphaCut && c.a < AlphaDiscard) discard;

				return c;
			}
			ENDCG
		}
		}
}
