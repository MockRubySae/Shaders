Shader "Custom/Water"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _NormalTex1 ("Normal texture 1", 2D) = "bump" {}
        _NormalTex2 ("Normal texture 2", 2D) = "bump" {}
        _NoiseTex ("Noise texture", 2D) = "white" {}
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.0
        
        _Scale ("Noise Scale", Range(0.01,0.1)) = 0.03
        _Amplitude ("Amplitude", Range(0.01,0.1)) = 0.015
        _Speed("Speed", Range(0.01, 0.3)) = 0.15
        _NormalStrength("Normal Strength", Range(0,1)) = 0.5
        _Transparentcy("Transparentcy", Range(0.01,3.0)) = 1.0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "ForceNoShadowCasting" = "True"}
        LOD 200

        CGPROGRAM
        #pragma surface surf Standard fullforwardshadows alpha vertex:vert 
         #include "UnityCG.cginc"
        #pragma target 3.0

        sampler2D _NormalTex1;
        sampler2D _NormalTex2;
        sampler2D _NoiseTex;
        sampler2D _CameraDepthTexture;

        float _Scale;
        float _Amplitude;
        float _Speed;
        float _NormalStrength;
        float _Transparentcy;

        half _Glossiness;
        half _Metallic;
        fixed4 _Color;
        
        // Define the Input struct to hold input data for the shader
        struct Input
        {
            float2 uv_NormalTex1; // UV coordinates for normal texture 1
            float4 screenPos; // Screen position
            float eyeDepth; // Eye depth
        };

        // Vertex shader function to manipulate vertices
        void vert (inout appdata_full v, out Input o)
        {
            // Calculate NoiseUV based on texture coordinates, time, speed, and scale
            float2 NoiseUV = float2(v.texcoord.xy + _Time * _Speed * _Scale);
            // Calculate NoiseValue using Noise texture and amplitude
            float NoiseValue = tex2Dlod(_NoiseTex, float4(NoiseUV, 0, 0)).x * _Amplitude;

            // Modify vertex position by adding noise
            v.vertex = v.vertex + float4(0, NoiseValue, 0, 0);

            // Initialise the output struct
            UNITY_INITIALIZE_OUTPUT(Input, o);
            // Compute eye depth
            COMPUTE_EYEDEPTH(o.eyeDepth);
        }

        // Surface shader function to define surface properties
        void surf (Input IN, inout SurfaceOutputStandard o)
        {
            // Set the base color from _Color property
            fixed4 c =  _Color;
            o.Albedo = c.rgb; // Set surface albedo
            o.Metallic = _Metallic; // Set metallic property
            o.Smoothness = _Glossiness; // Set smoothness property
            
            // Sample depth texture and calculate fade based on transparency
            float rawZ = SAMPLE_DEPTH_TEXTURE_PROJ(_CameraDepthTexture, UNITY_PROJ_COORD(IN.screenPos));
            float camZ = LinearEyeDepth(rawZ);
            float originalZ = IN.eyeDepth;
            float fade = saturate(_Transparentcy * (camZ - originalZ));

            o.Alpha = fade * 0.5; // Set alpha value based on fade

            // Calculate modified normals based on texture coordinates and time
            float normalX = IN.uv_NormalTex1.x + sin(_Time) * 5;
            float normalY = IN.uv_NormalTex1.y + sin(_Time) * 5;
            float2 normal1 = float2(normalX, IN.uv_NormalTex1.y);
            float2 normal2 = float2(IN.uv_NormalTex1.x, normalY);
            
            // Set the final normal value based on texture sampling and properties
            o.Normal = UnpackNormal((tex2D(_NormalTex1, normal1) + tex2D(_NormalTex2, normal2)) * _NormalStrength * fade);
        }
        ENDCG
    }
    FallBack "Diffuse"
}
