﻿Shader "Custom/3_Bloom"
{
    Properties
    {
        _MainTex ("Base(RGB)", 2D) = "white" {}//输入的渲染纹理
		_Bloom ("Bloom(RGB)", 2D) = "black" {}//高斯模糊后较亮区域
		_LuminanceThreshold("Luminance Threshold",Float) = 0.5//提取较量区域的阈值
		_BlurSize("Blur Size",Float) = 1.0
    }
    SubShader
    {
	//类似于头文件
		CGINCLUDE
			sampler2D _MainTex;
			half4 _MainTex_TexelSize;
			sampler2D _Bloom;
			float _LuminanceThreshold;
			float _BlurSize;

			#include "UnityCG.cginc"

			struct v2f{
				float4 pos : SV_POSITION;
				half2 uv : TEXCOORD0;
			};

			//提取较亮区域的顶点着色器和片元着色器
			v2f vertExtractBright(appdata_img v){
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);

				o.uv = v.texcoord;

				return o;
			};

			fixed luminance(fixed4 color){
				return 0.2125 * color.r + 0.7154 * color.g + 0.0721 * color.b;
			};

			fixed4 fragExtractBright(v2f i) : SV_Target{
				fixed4 c = tex2D(_MainTex,i.uv);
				fixed val = clamp(luminance(c) - _LuminanceThreshold, 0.0, 1.0); //得到的亮度  - 阈值 。 截取到 0~1之间；
				//该值与原像素相乘 得到提取后的亮度区域

				return c * val;
			};

			//混合亮部图像和原图像 使用的 着色器
			struct v2fBloom{
				float4 pos : SV_POSITION;
				half4 uv : TEXCOORD0;
			};

			v2fBloom vertBloom(appdata_img v){
				v2fBloom o;

				o.pos = UnityObjectToClipPos(v.vertex);
				o.uv.xy = v.texcoord;//maintex
				o.uv.zw = v.texcoord;//Bloom

				//平台差异化处理
				#if UNITY_UV_STARTS_AT_TOP
				if(_MainTex_TexelSize.y < 0.0)
					o.uv.w = 1.0 - o.uv.w;
				#endif

				return o;
			}

			fixed4 fragBloom(v2fBloom i ):SV_Target{
				return tex2D(_MainTex, i.uv.xy) + tex2D(_Bloom, i.uv.zw);
			}
		ENDCG

		ZTest Always Cull Off ZWrite Off

		Pass{
//提取亮度区域
			CGPROGRAM
			#pragma vertex vertExtractBright
			#pragma fragment fragExtractBright

			ENDCG
		}

		UsePass "Custom/2_GaussianBlur/GAUSSIAN_BLUR_VERTICAL"

		UsePass "Custom/2_GaussianBlur/GAUSSIAN_BLUR_HORIZONTAL"
		

		Pass{
//Bloom
			CGPROGRAM
			#pragma vertex vertBloom
			#pragma fragment fragBloom

			ENDCG
		}
    }
	FallBack Off
}
