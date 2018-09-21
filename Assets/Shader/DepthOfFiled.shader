Shader "Unlit/DepthOfFiled"
{
	Properties {
		_MainTex ("Base (RGB)", 2D) = "white" {}
		_BlurSize ("Blur Size", Float) = 1.0
	}
	
	SubShader {
		CGINCLUDE
		
		#include "UnityCG.cginc"
		
		sampler2D _MainTex;
		float4 _MainTex_TexelSize;
		sampler2D _BlurTex;
		sampler2D _CameraDepthTexture;  
		float _BlurSize;
		float4 offsets;
		float _foucousDistance;
		float _nearBlurScale;
		float _farBlurScale;
		  
		struct v2f {
			float4 pos : SV_POSITION;
			half2 uv[5]: TEXCOORD0;
		};

		struct v2f_dof{
			float4 pos : SV_POSITION;
			float2 uv : TEXCOORD0;
			float2 uv1 : TEXCOORD01;
		};
		  
		v2f vertBlurVertical(appdata_img v) {
			v2f o;
			o.pos = UnityObjectToClipPos(v.vertex);
			
			half2 uv = v.texcoord;
			
			o.uv[0] = uv;
			o.uv[1] = uv + float2(0.0, _MainTex_TexelSize.y * 1.0) * _BlurSize;
			o.uv[2] = uv - float2(0.0, _MainTex_TexelSize.y * 1.0) * _BlurSize;
			o.uv[3] = uv + float2(0.0, _MainTex_TexelSize.y * 2.0) * _BlurSize;
			o.uv[4] = uv - float2(0.0, _MainTex_TexelSize.y * 2.0) * _BlurSize;
					 
			return o;
		}
		
		v2f vertBlurHorizontal(appdata_img v) {
			v2f o;
			o.pos = UnityObjectToClipPos(v.vertex);
			
			half2 uv = v.texcoord;
			
			o.uv[0] = uv;
			o.uv[1] = uv + float2(_MainTex_TexelSize.x * 1.0, 0.0) * _BlurSize;
			o.uv[2] = uv - float2(_MainTex_TexelSize.x * 1.0, 0.0) * _BlurSize;
			o.uv[3] = uv + float2(_MainTex_TexelSize.x * 2.0, 0.0) * _BlurSize;
			o.uv[4] = uv - float2(_MainTex_TexelSize.x * 2.0, 0.0) * _BlurSize;
					 
			return o;
		}
		
		fixed4 fragBlur(v2f i) : SV_Target{
			float weight[3] = {0.4026, 0.2442, 0.0545};		
			fixed3 sum = tex2D(_MainTex, i.uv[0]).rgb * weight[0];
			
			for (int it = 1; it < 3; it++) {
				sum += tex2D(_MainTex, i.uv[it*2-1]).rgb * weight[it];
				sum += tex2D(_MainTex, i.uv[it*2]).rgb * weight[it];
			}
			
			return fixed4(sum, 1.0);
		}


		v2f_dof vert_dof(appdata_img v){
			v2f_dof o;

			o.pos = UnityObjectToClipPos(v.vertex);
			o.uv.xy = v.texcoord.xy;
			o.uv1.xy = o.uv.xy;

			#if UNITY_UV_STARTS_AT_TOP
			if(_MainTex_TexelSize.y < 0){
				o.uv.y = 1 - o.uv.y;
			}
			#endif

			return o;
		}

		fixed4 frag_dof(v2f_dof i) : SV_Target{
			
			fixed4 ori = tex2D(_MainTex, i.uv1);
			fixed4 blur = tex2D(_MainTex, i.uv);

			float depth = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv));
			
			fixed4 final = (depth <= _foucousDistance) ? ori : lerp(ori, blur, clamp((depth - _foucousDistance) * _farBlurScale, 0, 1));
			final = (depth > _foucousDistance) ? final : lerp(ori, blur, clamp((_foucousDistance - depth) * _nearBlurScale, 0, 1));
			return final;
		}
		    
		ENDCG
		
		ZTest Always Cull Off ZWrite Off
		
		Pass {

			CGPROGRAM
			  
			#pragma vertex vertBlurVertical  
			#pragma fragment fragBlur
			  
			ENDCG  
		}
		
		Pass {  	
			CGPROGRAM  
			
			#pragma vertex vertBlurHorizontal  
			#pragma fragment fragBlur
			
			ENDCG
		}

		Pass{
			ZTest Off
			ColorMask RGBA
			CGPROGRAM  

			#pragma vertex vert_dof  
			#pragma fragment frag_dof
			
			ENDCG
		}
	} 
	FallBack "Diffuse"
}
