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
		MainCamera.depthTextureMode |= DepthTextureMode.Depth;
	}

	void OnDisable(){
		MainCamera.depthTextureMode &= ~DepthTextureMode.Depth;
	}

	void OnRenderImage(RenderTexture src, RenderTexture dest){
		if(material != null){
			Mathf.Clamp(focousDistance, MainCamera.nearClipPlane, MainCamera.farClipPlane);

			int rtW = src.width / downSample;
			int rtH = src.height / downSample;

			RenderTexture rtBuffer0 = RenderTexture.GetTemporary(rtW, rtH, 0);
			

			rtBuffer0.filterMode = FilterMode.Bilinear;

			Graphics.Blit(src, rtBuffer0);

			for(int i = 0; i < iteration; i++){
				material.SetFloat("_BlurSize", 1.0f + i * blurSpeed);
				RenderTexture rtBuffer1 = RenderTexture.GetTemporary(rtW, rtH, 0);

				Graphics.Blit(rtBuffer0, rtBuffer1, material, 0);
				RenderTexture.ReleaseTemporary(rtBuffer0);
				rtBuffer0 = rtBuffer1;
				rtBuffer1 = RenderTexture.GetTemporary(rtW, rtH, 0);

				Graphics.Blit(rtBuffer0, rtBuffer1, material, 1);
				RenderTexture.ReleaseTemporary(rtBuffer0);
				rtBuffer0 = rtBuffer1;
			}

			
			material.SetFloat("_focousDistance", focousDistance);
			material.SetFloat("_nearBlurScale", nearBlurScale);
			material.SetFloat("_farBlurScale",farBlurScale);
			material.SetTexture("_BlurTex", rtBuffer0);
			RenderTexture.ReleaseTemporary(rtBuffer0);
			//Graphics.Blit(src, dest, material, 2);
			
		}else{
			Graphics.Blit(src, dest);
		}
	}

	
		
}
