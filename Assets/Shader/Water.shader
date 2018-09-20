// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "Unlit/Water"
{
	Properties{
		_Color ("Main Color", Color) = (0, 0.15, 0.115, 1)  //主色调,水面颜色
		_MainTex ("Base", 2D) = "white"{} //底图
		_WaveMap ("Wave Map", 2D) = "bump"{}	//由噪音生成的法线贴图
		_Cubemap ("Cubemap", Cube) = "_Skybox"{} //立方体文理，用于水面反射颜色采样
		_WaveXSpeed ("Wave Horizontal Speed", Range(-0.1, 0.1)) = 0.01 //水波x轴扰动
		_WaveYSpeed ("Wave Vertical Speed", Range(-0.1, 0.1)) = 0.01 //水波y轴扰动
		_Distortion ("Distortion", Range(0, 100)) = 10	//控制折射扭曲程度
	}

	SubShader{

		Tags{ "Queue" = "Transparent" "RenderType"= "Opaque"}

		GrabPass{"_RefractionTex"}  //抓取屏幕图像生成纹理

		Pass{

			Tags { "LightMode" = "ForwardBase"} //前项渲染

			CGPROGRAM

			#include "Lighting.cginc"
			#include "UnityCG.cginc"

			#pragma multi_compile_fwdbase 
			#pragma vertex vert
			#pragma fragment frag

			//properties变量
			fixed4 _Color;
			sampler2D _MainTex;
			float4 _MainTex_ST; //纹理偏移缩放 xy为缩放，zw偏移
			sampler2D _WaveMap;
			float4 _WaveMap_ST;
			samplerCUBE _Cubemap; 
			fixed _WaveXSpeed;
			fixed _WaveYSpeed;
			float _Distortion;
			sampler2D _RefractionTex;
			float4 _RefractionTex_TexelSize; //抓取的纹理的纹素大小

			struct a2v {
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float4 tangent : TANGENT;   //切线
				float4 texcoord : TEXCOORD0; //存放纹理坐标
			};

			struct v2f {
				float4 pos : SV_POSITION;
				float4 scrPos : TEXCOORD0;  //存放屏幕坐标
				float4 uv : TEXCOORD1;
				//xyz存储切线到世界空间的转换矩阵，w分量存储世界坐标
				float4 TtoW0 : TEXCOORD2; 
				float4 TtoW1 : TEXCOORD3;
				float4 TtoW2 : TEXCOORD4;
			};
			
			v2f vert(a2v v){
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex); //模型空间到裁剪空间的变换函数  unity5.3启用    替换UNITY_MATRIX_MVP矩阵乘法，函数实际还是使用该mvp矩阵
				o.scrPos = ComputeGrabScreenPos(o.pos); //屏幕空间坐标

				o.uv.xy = TRANSFORM_TEX(v.texcoord, _MainTex);  //底图采样
				o.uv.zw = TRANSFORM_TEX(v.texcoord, _WaveMap);  //法线采样

				float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz; //顶点转换到世界坐标系
				fixed3 worldNormal = UnityObjectToWorldNormal(v.normal); //法线转换到世界坐标系
				fixed3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);//切线在世界坐标系下的方向
				fixed3 worldBinormal = cross(worldNormal, worldTangent) * v.tangent.w; //使用叉积计算副切线，w分量控制副切线方向

				//填充，xyz存储变换矩阵，w存储顶点世界坐标
				o.TtoW0 = float4(worldTangent.x, worldBinormal.x, worldNormal.x, worldPos.x);
				o.TtoW1 = float4(worldTangent.y, worldBinormal.y, worldNormal.y, worldPos.y);
				o.TtoW2 = float4(worldTangent.z, worldBinormal.z, worldNormal.z, worldPos.z);

				return o;

			}

			fixed4 frag(v2f i) : SV_Target{
	
				float3 worldPos = float3(i.TtoW0.w, i.TtoW1.w, i.TtoW2.w); //定义世界坐标
				fixed3 viewDir = normalize(UnityWorldSpaceViewDir(worldPos)); //视角方向
				float2 speed = _Time.y * float2(_WaveXSpeed, _WaveYSpeed);	//用时间控制水面扰动偏移量  time.y 为正常速度    time.x = 1/2 time.z = 2
				//使用双采样模拟水面交叉波动
				fixed3 bump1 = UnpackNormal(tex2D(_WaveMap, i.uv.zw + speed)).rgb; //切线空间下对法线采样需要解码
				fixed3 bump2 = UnpackNormal(tex2D(_WaveMap, i.uv.zw - speed)).rgb;
				fixed3 bump = normalize(bump1 + bump2); //叠加后的法线
				
				float2 offset = bump.xy * _Distortion * _RefractionTex_TexelSize.xy;  //折射
				i.scrPos.xy = offset * i.scrPos.z + i.scrPos.xy; //z分量模拟水的深浅对折射的影响
				fixed3 refrCol = tex2D(_RefractionTex, i.scrPos.xy/i.scrPos.w).rgb; //折射颜色采样

				bump = normalize(half3(dot(i.TtoW0.xyz, bump), dot(i.TtoW1.xyz, bump), dot(i.TtoW2.xyz, bump))); //把法线由切线空间转换到世界空间
				fixed4 texColor = tex2D(_MainTex, i.uv.xy + speed);  //底图颜色采样 speed变量使水面动起来
				fixed3 reflDir = reflect(-viewDir, bump);  //反射方向
				fixed3 reflCol = texCUBE(_Cubemap, reflDir).rgb * texColor.rgb * _Color.rgb; //反射颜色采样

				fixed fresnel = pow(1 - saturate(dot(viewDir, bump)), 4);  //菲涅尔系数
				fixed3 finalColor = reflCol * fresnel + (1 - fresnel) * refrCol;  //使用菲涅尔混合反射和折射颜色得到最终的颜色

				return fixed4(finalColor, 1);

			}


			ENDCG

		}

	}

	Fallback Off
}
