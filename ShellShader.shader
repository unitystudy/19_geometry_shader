Shader "Geometry/ShellShader"
{
	Properties
	{
		_GlassTex("Glass Texture", 2D) = "white" {}
		_BaseColor("Base Color", Color) = (0.3, 0.5, 0.3, 1.0)
	}
		SubShader
	{
		Tags {"RenderType" = "Transparency"}
		Blend SrcAlpha OneMinusSrcAlpha
		LOD 100

		zwrite off
		cull off

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma geometry geom
			#pragma fragment frag

			#include "UnityCG.cginc"

			struct appdata
			{
				float4 pos : POSITION;
				float2 uv : TEXCOORD1;
				float2 uv0 : TEXCOORD0;
		};

			struct v2g
			{
				float2 uv : TEXCOORD1;
				float2 uv0 : TEXCOORD0;
				float4 pos : SV_POSITION;
			};

			struct g2f
			{
				float2 uv : TEXCOORD0;
				float4 pos : SV_POSITION;
			};

			sampler2D _GlassTex;
			float4 _MainTex_ST;
			fixed4 _BaseColor;

			fixed2 random2(float2 st) {
				st = float2(dot(st, fixed2(127.1, 311.7)),
					dot(st, fixed2(269.5, 183.3)));
				return -1.0 + 2.0 * frac(sin(st) * 43758.5453123);
			}

			float Noise(float2 st)
			{
				float2 p = floor(st);
				float2 f = frac(st);
				float2 u = f * f * (3.0 - 2.0 * f);

				float2 v00 = random2(p + fixed2(0, 0));
				float2 v10 = random2(p + fixed2(1, 0));
				float2 v01 = random2(p + fixed2(0, 1));
				float2 v11 = random2(p + fixed2(1, 1));

				return lerp(
					lerp(dot(random2(p + float2(0.0, 0.0)), f - float2(0.0, 0.0)),
						dot(random2(p + float2(1.0, 0.0)), f - float2(1.0, 0.0)), u.x),
					lerp(dot(random2(p + float2(0.0, 1.0)), f - float2(0.0, 1.0)),
						dot(random2(p + float2(1.0, 1.0)), f - float2(1.0, 1.0)), u.x), u.y);
			}

			float Fbm(float2 texcoord)
			{
				float2 tc = texcoord * float2(.3, .3);
				float time = _Time.y * 0.1;
				float noise
					= Noise((tc + time) * 1.0)
					+ Noise((tc + time) * 2.0) * 0.5
					+ Noise((tc + time) * 4.0) * 0.25;
				noise = noise / (1.0 + 0.5 + 0.25); // 正規化

				return noise;
			}


			v2g vert(appdata v)
			{
				v2g o;
				o.pos = v.pos;
				o.uv = v.uv;
				o.uv0 = v.uv + 0.2 * float2(
					Fbm(v.uv),
					Fbm(v.uv + float2(1000.0, 1000.0)));// 適当に遠い場所をサンプリング
				return o;
			}

			#define SHELLS 10
			[maxvertexcount(3 * SHELLS)]
			void geom(triangle v2g IN[3], inout TriangleStream<g2f> stream)
			{
				float h = 0.01;
				g2f o;
				for (int i = 0; i < SHELLS; i++) {
					float t = (float)(i) / (float)(SHELLS);
					t = t * t;
					// 元の三角形の少し上にそのままの形で重ね書き
					o.pos = UnityObjectToClipPos(IN[0].pos + float4(0, h, 0, 0));
					o.uv = lerp(IN[0].uv, IN[0].uv0, t);// 上の方ほど動かす
					stream.Append(o);

					o.pos = UnityObjectToClipPos(IN[1].pos + float4(0, h, 0, 0));
					o.uv = lerp(IN[1].uv, IN[1].uv0, t);
					stream.Append(o);

					o.pos = UnityObjectToClipPos(IN[2].pos + float4(0, h, 0, 0));
					o.uv = lerp(IN[2].uv, IN[2].uv0, t);
					stream.Append(o);

					stream.RestartStrip();// ストリップを切る

					h += 0.06;
				}
			}
			fixed4 frag(g2f i) : SV_Target
			{
				float alpha = tex2D(_GlassTex, i.uv).x;
				return _BaseColor * alpha;
			}
			ENDCG
		}
	}
}
