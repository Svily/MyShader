Shader "Unlit/Chapter12-BrghtnessSaturationAndContrast"
{
	Properties{
		_MainTex ("Main Tex", 2D) = "white"{}
		_Brightness ("Brightness", Float) = 1
		_Saturation ("Saturation", Float) = 1
		_Contrast ("Contrast", Float) = 1
	}

	SubShader{

		Pass{
			ZTest Always Cull Off ZWrite Off


			CGPROGRAM

			#pragma vertex vert
			#pragma fragment frag

			#include "unityCG.cginc"

			sampler2D _MainTex;
			half _Brightness;
			half _Saturation;
			half _Contrast;


			struct v2f {
				float4 pos : SV_POSITION;
				half2 uv : TEXCOORD0;
			};

			v2f vert(appdata_img v){
				v2f o;

				o.pos = UnityObjectToClipPos(v.vertex);
				o.uv = v.texcoord;

				return o;
			}

			fixed4 frag(v2f i) : SV_Target{
				fixed4 rendertTex = tex2D(_MainTex, i.uv);

				fixed3 finalColor = rendertTex.rgb * _Brightness;
				fixed luminance = 0.2125 * rendertTex.r + 0.7154 * rendertTex.g + 0.0721 * rendertTex.b;
				fixed3 luminanceColor = fixed3(luminance, luminance, luminance);
				finalColor = lerp(luminanceColor, finalColor, _Saturation);

				fixed3 avgColor = fixed3(0.5, 0.5, 0.5);
				finalColor = lerp(avgColor, finalColor, _Contrast);

				return fixed4(finalColor, rendertTex.a);
			}

			ENDCG
		}

	}

	FallBack Off
}
