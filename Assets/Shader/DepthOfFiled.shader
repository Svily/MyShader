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
		//贴图纹素大小，用于计算相邻的像素坐标
		float4 _MainTex_TexelSize;
		sampler2D _BlurTex;
		//深度贴图，由unity camera获取，从脚本传入
		sampler2D _CameraDepthTexture;  
		float _BlurSize;
		float _foucousDistance;
		float _nearBlurScale;
		float _farBlurScale;
		  
		struct v2f {
			float4 pos : SV_POSITION;
			half2 uv[5]: TEXCOORD0;
		};

		struct v2fDof{
			float4 pos : SV_POSITION;
			float2 uv : TEXCOORD0;
			float2 uv1 : TEXCOORD01;
		};
		  
		v2f vertBlurVertical(appdata_img v) {
			v2f o;
			o.pos = UnityObjectToClipPos(v.vertex);
			
			half2 uv = v.texcoord;
			
			//纵向5个临近的纹理坐标
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
			
			//横向5个纹理坐标
			o.uv[0] = uv;
			o.uv[1] = uv + float2(_MainTex_TexelSize.x * 1.0, 0.0) * _BlurSize;
			o.uv[2] = uv - float2(_MainTex_TexelSize.x * 1.0, 0.0) * _BlurSize;
			o.uv[3] = uv + float2(_MainTex_TexelSize.x * 2.0, 0.0) * _BlurSize;
			o.uv[4] = uv - float2(_MainTex_TexelSize.x * 2.0, 0.0) * _BlurSize;
					 
			return o;
		}
		
		fixed4 fragBlur(v2f i) : SV_Target{
			//高斯核权重
			float weight[3] = {0.4026, 0.2442, 0.0545};		
			fixed3 sum = tex2D(_MainTex, i.uv[0]).rgb * weight[0];
			//迭代
			for (int it = 1; it < 3; it++) {
				//加权求和，求目标像素颜色
				sum += tex2D(_MainTex, i.uv[it*2-1]).rgb * weight[it];
				sum += tex2D(_MainTex, i.uv[it*2]).rgb * weight[it];
			}
			
			return fixed4(sum, 1.0);
		}


		v2fDof vertDof(appdata_img v){
			v2fDof o;

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


		fixed4 fragDof(v2fDof i) : SV_Target{

			//原图采样
			fixed4 ori = tex2D(_MainTex, i.uv);
			//高斯模糊图采样
			fixed4 blur = tex2D(_BlurTex, i.uv1);
			//线性转换采样后的深度值 深度值取值【0-1】 值越大越远
			float depth = Linear01Depth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv1));
			//对深度值大于焦点的物体进行模糊，远景模糊, 其余不作处理使用原图
			fixed4 finalColor = (depth > _foucousDistance) ? lerp(ori, blur, clamp((depth - _foucousDistance) * _farBlurScale, 0, 1)) : ori;
			//在进行了远景模糊的基础上对深度值小于焦点的物体进行模糊，近景模糊
			finalColor = (depth <= _foucousDistance) ? lerp(ori, blur, clamp((_foucousDistance - depth) * _nearBlurScale, 0, 1)) : finalColor;

			return finalColor;
			
		}
		    
		ENDCG
		
		ZTest Always Cull Off ZWrite Off
		
		//横向高斯滤波
		Pass {

			CGPROGRAM

			#pragma vertex vertBlurVertical  
			#pragma fragment fragBlur
			  
			ENDCG  
		}
		
		//纵向高斯滤波
		Pass {  	
			CGPROGRAM  
			
			#pragma vertex vertBlurHorizontal  
			#pragma fragment fragBlur
			
			ENDCG
		}

		//景深
		Pass{

			ZTest Off
			ColorMask RGBA
			CGPROGRAM  

			#pragma vertex vertDof  
			#pragma fragment fragDof
			
			ENDCG
		}
	} 
	FallBack Off
}
