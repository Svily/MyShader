using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class DepthOfFiled : PostEffectsBase {

	public Shader depthShader;

	private Material depthMaterial;

	public Material material{
		get{
			return CheckShaderAndCreateMaterial(depthShader, depthMaterial);
		}
	}

	[Range(0, 4)]
	public int iteration = 3;

	[Range(0.2f, 3.0f)]
	public float blurSpeed = 0.6f;

	[Range(1, 8)]
	public int downSample = 2;

	[Range(0.0f, 100.0f)]
	public float focousDistance = 10.0f;

	[Range(0.0f, 100.0f)]
	public float nearBlurScale = 0.0f;

	[Range(0.0f, 1000.0f)]
	public float farBlurScale = 0.0f;

	public int sampleScale = 1;

	private Camera _mainCamera;

	public Camera MainCamera{

		get{
			if(_mainCamera == null){
				_mainCamera = GetComponent<Camera>();
			}

			return _mainCamera;
		}
	}

	void OnEnable(){
		//获取深度贴图
		MainCamera.depthTextureMode |= DepthTextureMode.Depth;
	}

	void OnDisable(){
		MainCamera.depthTextureMode &= ~DepthTextureMode.Depth;
	}

	void OnRenderImage(RenderTexture src, RenderTexture dest){
		if(material != null){
			//焦点截取到近裁平面和远裁平面之间
			Mathf.Clamp(focousDistance, MainCamera.nearClipPlane, MainCamera.farClipPlane);

			//降采样
			int rtW = src.width / downSample;
			int rtH = src.height / downSample;

			//申请同屏大小的缓冲，用于存放渲染好的图片
			RenderTexture rtBuffer0 = RenderTexture.GetTemporary(rtW, rtH, 0);
			
			//设为双线性滤波模式
			rtBuffer0.filterMode = FilterMode.Bilinear;

			//获取原始图像
			Graphics.Blit(src, rtBuffer0);

			for(int i = 0; i < iteration; i++){
				material.SetFloat("_BlurSize", 1.0f + i * blurSpeed);
				RenderTexture rtBuffer1 = RenderTexture.GetTemporary(rtW, rtH, 0);
				//横向高斯滤波
				Graphics.Blit(rtBuffer0, rtBuffer1, material, 0);
				RenderTexture.ReleaseTemporary(rtBuffer0);
				rtBuffer0 = rtBuffer1;
				rtBuffer1 = RenderTexture.GetTemporary(rtW, rtH, 0);
				//纵向高斯滤波
				Graphics.Blit(rtBuffer0, rtBuffer1, material, 1);
				RenderTexture.ReleaseTemporary(rtBuffer0);

				//最终滤波后的图像存放到rtbuffer0中
				rtBuffer0 = rtBuffer1;
			}

			//设置材质，准备进行景深计算
			material.SetFloat("_focousDistance", focousDistance);
			material.SetFloat("_nearBlurScale", nearBlurScale);
			material.SetFloat("_farBlurScale",farBlurScale);
			//把高斯模糊后的图片作为输入贴图
			material.SetTexture("_BlurTex", rtBuffer0);

			//高斯模糊输出
			Graphics.Blit(rtBuffer0,dest);

			//景深shader代码有问题？代码逻辑应该没问题，但不能得到效果，先不使用

			//RenderTexture.ReleaseTemporary(rtBuffer0);
			//景深~~图片直接输出到屏幕
			//Graphics.Blit(src, dest, material, 2);
			
		}else{
			Graphics.Blit(src, dest);
		}
	}

	
		
}
