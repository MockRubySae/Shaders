Shader "ToonWater"
{
    Properties
    {
        _DepthGradientShallow("Depth Gradient Shallow", Color) = (0.325, 0.807, 0.971, 0.725)
        _DepthGradientDeep("Depth Gradient Deep", Color) = (0.086, 0.407, 1, 0.749)
        _DepthMaxDistance("Depth Maximum Distance", Float) = 1
        _SurfaceNoise("Surface Noise", 2D) = "white" {}
        _SurfaceNoiseCutoff("Surface Noise Cutoff", Range(0, 1)) = 0.777
        _FoamMaxDistance("Foam Maximum Distance", Float) = 0.4
        _FoamMinDistance("Foam Minimum Distance", Float) = 0.04
        _SurfaceNoiseScroll("Surface Noise Scroll Amount", Vector) = (0.03, 0.03, 0, 0)
        _SurfaceDistortion("Surface Distortion", 2D) = "white" {}
        _SurfaceDistortionAmount("Surface Distortion Amount", Range(0, 1)) = 0.27
        _FoamColour("Foam Colour", Color) = (1,1,1,1)
    }
    SubShader
    {
        Tags
        {
	        "Queue" = "Transparent"
        }
        Pass
        {
            Blend SrcAlpha OneMinusSrcAlpha
            ZWrite Off
			CGPROGRAM
			#define SMOOTHSTEP_AA 0.01
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            
            float4 _DepthGradientShallow;
            float4 _DepthGradientDeep;

            float _DepthMaxDistance;

            sampler2D _CameraDepthTexture;
            
            sampler2D _SurfaceNoise;
            float4 _SurfaceNoise_ST;
            float _SurfaceNoiseCutoff;

            float _FoamMaxDistance;
            float _FoamMinDistance;
            float4 _FoamColour;
            
            float2 _SurfaceNoiseScroll;
            sampler2D _SurfaceDistortion;
            float4 _SurfaceDistortion_ST;

            float _SurfaceDistortionAmount;

            sampler2D _CameraNormalsTexture;
            // Function to blend two colors with alpha values
            float4 alphaBlend(float4 top, float4 bottom)
            {
                float3 color = (top.rgb * top.a) + (bottom.rgb * (1 - top.a)); // Calculate blended color
                float alpha = top.a + bottom.a * (1 - top.a); // Calculate blended alpha

                return float4(color, alpha); // Return the blended color with alpha
            }

            // Input structure for vertex shader
            struct appdata
            {
                float4 vertex : POSITION; // Vertex position
                float4 uv : TEXCOORD0; // Texture coordinates
                float3 normal : NORMAL; // Normal vector
            };

            // Output structure for vertex shader
            struct v2f
            {
                float4 vertex : SV_POSITION; // Vertex position in screen space
                float4 screenPosition : TEXCOORD2; // Screen position
                float2 noiseUV : TEXCOORD0; // Noise texture coordinates
                float2 distortUV : TEXCOORD1; // Distortion texture coordinates
                float3 viewNormal : NORMAL; // Normal vector in view space
            };

            // Vertex shader function
            v2f vert (appdata v)
            {
                v2f o;

                o.vertex = UnityObjectToClipPos(v.vertex); // Transform vertex to clip space
                o.screenPosition = ComputeScreenPos(o.vertex); // Compute screen position
                o.noiseUV = TRANSFORM_TEX(v.uv, _SurfaceNoise); // Transform noise texture coordinates
                o.distortUV = TRANSFORM_TEX(v.uv, _SurfaceDistortion); // Transform distortion texture coordinates

                return o;
            }

            // Fragment shader function
            float4 frag (v2f i) : SV_Target
            {
                // Calculate depth and water color based on depth
                float existingDepth01 = tex2Dproj(_CameraDepthTexture, UNITY_PROJ_COORD(i.screenPosition)).r;
                float existingDepthLinear = LinearEyeDepth(existingDepth01);
                float depthDifference = existingDepthLinear - i.screenPosition.w;
                float waterDepthDifference01 = saturate(depthDifference / _DepthMaxDistance);
                float4 waterColor = lerp(_DepthGradientShallow, _DepthGradientDeep, waterDepthDifference01);

                // Calculate distortion and noise for water surface
                float2 distortSample = (tex2D(_SurfaceDistortion, i.distortUV).xy * 2 - 1) * _SurfaceDistortionAmount;
                float2 noiseUV = float2((i.noiseUV.x + _Time.y * _SurfaceNoiseScroll.x) + distortSample.x, (i.noiseUV.y + _Time.y * _SurfaceNoiseScroll.y) + distortSample.y);
                float surfaceNoiseSample = tex2D(_SurfaceNoise, noiseUV).r;

                // Calculate foam effect based on normals and depth
                float3 existingNormal = tex2Dproj(_CameraNormalsTexture, UNITY_PROJ_COORD(i.screenPosition));
                float3 normalDot = saturate(dot(existingNormal, i.viewNormal));
                float foamDistance = lerp(_FoamMaxDistance, _FoamMinDistance, normalDot);
                float foamDepthDifference01 = saturate(depthDifference / foamDistance);
                float surfaceNoiseCutoff = foamDepthDifference01 * _SurfaceNoiseCutoff;
                float surfaceNoise = smoothstep(surfaceNoiseCutoff - SMOOTHSTEP_AA, surfaceNoiseCutoff + SMOOTHSTEP_AA, surfaceNoiseSample);
                float4 surfaceNoiseColour = _FoamColour;
                surfaceNoiseColour.a *= surfaceNoise;

                return alphaBlend(surfaceNoiseColour, waterColor); // Return final blended color
            }
            ENDCG
        }
    }
}