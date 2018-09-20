Shader "Custom/GerstnerWave" {
	Properties {
		_Color ("Color", Color) = (1,1,1,1)
		_MainTex ("Albedo (RGB)", 2D) = "white" {}
		//_Glossiness ("Smoothness", Range(0,1)) = 0.5
		//_Metallic ("Metallic", Range(0,1)) = 0.0
		_RefTxu("Ref", 2D) = "white"{}
 
		_SunPower("Sun Power", Float) = 1.0
 
		_SunDir("Sun Dir", Vector) = (1,1,1,1)
		_SunColor("Sun Color", Color) = (1,1,1,1)
		//(A,W,Q,Steep)
		_Wave1("Wave1",Vector) = (1,1,0.5,0.1)
		_Wave2("Wave1",Vector) = (1,1,0.5,0.1)
		_Wave3("Wave1",Vector) = (1,1,0.5,0.1)
		_StartX("startX", Float) = 0
 
		_C1("WaveC1", Vector) = (1,1,1,1)
		_C2("WaveC2", Vector) = (1,1,1,1)
		_C3("WaveC3", Vector) = (1,1,1,1)
	}
	SubShader {
		Tags{ "Queue" = "Transparent" "IgnoreProjector" = "True" "RenderType" = "Transparent" }
			LOD 200
			CGPROGRAM
			// Physically based Standard lighting model, and enable shadows on all light types
#pragma surface surf Standard  vertex:vert alpha:fade  
 
			// Use shader model 3.0 target, to get nicer looking lighting
#pragma target 3.0
 
		sampler2D _MainTex;
		sampler2D _RefTxu;
 
		struct Input {
			float2 uv_MainTex;
			float3 normal;
			float3 worldPos;
		};
 
		half _Glossiness;
		half _Metallic;
		fixed4 _Color;
 
		float _SunPower;
		float4 _SunDir;
		float4 _SunColor;
		float4 _Wave1;
		float4 _Wave2;
		float4 _Wave3;
		float _StartX;
		float4 _C1;
		float4 _C2;
		float4 _C3;
 
		float4 DisVec(float4 v, fixed i)
		{
 
			if (i == 1)
			{
				return normalize(v - _C1);
			}
			else if (i == 2)
			{
				return normalize(v - _C2);
			}
			else if (i == 3)
			{
				return normalize(v - _C3);
			}
 
		}
 
		float DiDotXY(float4 v, fixed i)
		{
			return dot(DisVec(v, i), v);
		}
 
		float4 GerstnerWave(float4 v, float t, out float3 normal)
		{
			fixed A = 0;//振幅
			fixed W = 1;//角速度
			fixed Q = 2;//初相
			fixed Step = 3;//陡度控制
 
			float CT1 = cos(_Wave1[W] * DiDotXY(v, 1) + _Wave1[Q] * t);
			float CT2 = cos(_Wave2[W] * DiDotXY(v, 2) + _Wave2[Q] * t);
			float CT3 = cos(_Wave3[W] * DiDotXY(v, 3) + _Wave3[Q] * t);
 
			float xT = v.x + _Wave1[Step] * _Wave1[A] * DisVec(v, 1).x * CT1
				+ _Wave2[Step] * _Wave2[A] * DisVec(v, 2).x * CT2
				+ _Wave3[Step] * _Wave3[A] * DisVec(v, 3).x * CT3;
 
			float yT = _Wave1[A] * sin(_Wave1[W] * DiDotXY(v, 1) + _Wave1[Q] * t)
				+ _Wave2[A] * sin(_Wave2[W] * DiDotXY(v, 2) + _Wave2[Q] * t)
				+ _Wave3[A] * sin(_Wave3[W] * DiDotXY(v, 3) + _Wave3[Q] * t);
 
			float zT = v.z + _Wave1[Step] * _Wave1[A] * DisVec(v, 1).z * CT1
				+ _Wave2[Step] * _Wave2[A] * DisVec(v, 2).z * CT2
				+ _Wave3[Step] * _Wave3[A] * DisVec(v, 3).z * CT3;
 
			float4 P = float4(xT, yT, zT, v.w);
 
			//法线计算
			float DP1 = dot(DisVec(v, 1), P);
			float DP2 = dot(DisVec(v, 2), P);
			float DP3 = dot(DisVec(v, 3), P);
 
			float C1 = cos(_Wave1[W] * DP1 + _Wave1[Q] * t);
			float C2 = cos(_Wave2[W] * DP2 + _Wave2[Q] * t);
			float C3 = cos(_Wave3[W] * DP3 + _Wave3[Q] * t);
 
			float nXT = -1 * (DisVec(v, 1).x * _Wave1[W] * _Wave1[A] * C1)
				- (DisVec(v, 2).x * _Wave2[W] * _Wave2[A] * C2)
				- (DisVec(v, 3).x * _Wave3[W] * _Wave3[A] * C3);
 
			float nYT = 1 - _Wave1[Step] * _Wave1[W] * _Wave1[A] * sin(_Wave1[W] * DP1 + _Wave1[Q] * t)
				- _Wave2[Step] * _Wave2[W] * _Wave2[A] * sin(_Wave2[W] * DP2 + _Wave2[Q] * t)
				- _Wave3[Step] * _Wave3[W] * _Wave3[A] * sin(_Wave3[W] * DP3 + _Wave3[Q] * t);
 
			float nZT = -1 * (DisVec(v, 1).z * _Wave1[W] * _Wave1[A] * C1)
				- (DisVec(v, 2).z * _Wave2[W] * _Wave2[A] * C2)
				- (DisVec(v, 3).z * _Wave3[W] * _Wave3[A] * C3);
 
			normal = float3(nXT, nYT, nZT);
 
			return P;
		}
 
		float fresnel(float3 V, float3 N)
		{
 
			half NdotL = max(dot(V, N), 0.0);
			half fresnelBias = 0.4;
			half fresnelPow = 5.0;
			fresnelPow = _SunPower;
 
			half facing = (1.0 - NdotL);
			return max(fresnelBias + (1 - fresnelBias) * pow(facing, fresnelPow), 0.0);
		}
 
		float3 computeSunColor(float3 V, float3 N)
		{
			float3 HalfVector = normalize(abs(V + (_SunDir)));
 
			return _SunColor * pow(abs(dot(HalfVector, N)), _SunPower) * _SunColor.a;
		}
 
		void vert(inout appdata_full v, out Input o)
		{
			float3 normal = float3(1,1,1);
			v.vertex = GerstnerWave(v.vertex, _Time.x, normal);
			UNITY_INITIALIZE_OUTPUT(Input, o);
			o.normal = normal;
		}
 
		void surf(Input IN, inout SurfaceOutputStandard o) {
 
			fixed4 c = tex2D(_MainTex, IN.uv_MainTex) * _Color;
 
			float3 N = IN.normal;
 
			o.Albedo = c.rgb;
			o.Alpha = _Color.a;
			o.Normal = N;
 
			float3 vDir = normalize(_WorldSpaceCameraPos - IN.worldPos);
 
			float fr = fresnel(vDir, N);
 
			//float3 skyColor = texCUBE(_ReflMap, WorldReflectionVector(IN, o.Normal)).rgb * _ReflecTivity;//* _ReflecTivity;
 
			float3 sunColor = computeSunColor(vDir, N);
 
			o.Emission = fr * c + sunColor;
		}
		ENDCG
	}
	FallBack "Diffuse"
}
