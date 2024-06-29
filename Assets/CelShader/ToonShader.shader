Shader "Unlit/ToonShader"
{
    
    Properties
    {
        [MainTexture] _BaseMap("Texture", 2D) = "white" {}
        [MainColor] _BaseColor("Color", Color) = (1, 1, 1, 1)
        _Cutoff("AlphaCutout", Range(0.0, 1.0)) = 0.5

        // BlendMode
        _Surface("__surface", Float) = 0.0
        _Blend("__mode", Float) = 0.0
        _Cull("__cull", Float) = 2.0
        [ToggleUI] _AlphaClip("__clip", Float) = 0.0
        [HideInInspector] _BlendOp("__blendop", Float) = 0.0
        [HideInInspector] _SrcBlend("__src", Float) = 1.0
        [HideInInspector] _DstBlend("__dst", Float) = 0.0
        [HideInInspector] _SrcBlendAlpha("__srcA", Float) = 1.0
        [HideInInspector] _DstBlendAlpha("__dstA", Float) = 0.0
        [HideInInspector] _ZWrite("__zw", Float) = 1.0
        [HideInInspector] _AlphaToMask("__alphaToMask", Float) = 0.0

        // Editmode props
        _QueueOffset("Queue offset", Float) = 0.0
    }

    SubShader
    {
        Tags
        {
            "RenderType" = "Opaque"
            "IgnoreProjector" = "True"
            "UniversalMaterialType" = "Unlit"
            "RenderPipeline" = "UniversalPipeline"
        }

        // -------------------------------------
        // Render State Commands
        Blend [_SrcBlend][_DstBlend], [_SrcBlendAlpha][_DstBlendAlpha]
        ZWrite [_ZWrite]
        Cull [_Cull]
        Pass
        {
            Name "Toon"
            // -------------------------------------
            // Render State Commands
            AlphaToMask[_AlphaToMask]

            HLSLPROGRAM
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fog
             // Material Keywords
            #pragma shader_feature_local_fragment _SURFACE_TYPE_TRANSPARENT
            #pragma shader_feature_local_fragment _ALPHATEST_ON
            #pragma shader_feature_local_fragment _ALPHAMODULATE_ON

            // -------------------------------------
            // Unity defined keywords
            #pragma multi_compile_fog
            #pragma multi_compile_fragment _ _SCREEN_SPACE_OCCLUSION
            #pragma multi_compile_fragment _ _DBUFFER_MRT1 _DBUFFER_MRT2 _DBUFFER_MRT3
            #pragma multi_compile _ DEBUG_DISPLAY
            #pragma multi_compile_fragment _ LOD_FADE_CROSSFADE

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing

            // toon shader code
            struct AppData
            {
                float4 positionObj : POSITION;
                half3 normal : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 screemPos : SV_POSITION;
                half3 normal : TEXCOORD0;
                half3 worldPos : TEXCOORD1;
                half3 viewDir : TEXCOORD2;
                float2 uv : TEXCOORD3;
            };
            
            sampler2D _BaseMap;
            float4 _BaseMap_ST;
            half4 _BaseColor;
            v2f vert (AppData IN)
            {
                v2f o;

                o.screemPos = TransformObjectToHClip(IN.positionObj.xyz);
                o.normal = TransformObjectToWorldNormal(IN.normal);
                o.worldPos = mul(unity_ObjectToWorld, IN.positionObj);
                o.viewDir = normalize(GetWorldSpaceViewDir(o.worldPos));
                o.uv = TRANSFORM_TEX(IN.uv, _BaseMap);
                return o;
            };

            half4 frag(v2f IN) : SV_Target
            {
                float dorProduct = dot(IN.normal, IN.viewDir);
                dorProduct = step(0.3, dorProduct);
                half4 col = tex2D(_BaseMap, IN.uv);
                half4 colour = (_BaseColor.rgba);
                half4 finalColour = col * colour * dorProduct;
                return half4(finalColour);
            };
            
            
            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing
            ENDHLSL
        }
        
    }
    CustomEditor "UnityEditor.Rendering.Universal.ShaderGUI.UnlitShader"
}
