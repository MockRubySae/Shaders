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
            // Define input structure for vertex shader
            struct AppData
            {
                float4 positionObj : POSITION; // Object space position
                half3 normal : NORMAL; // Object space normal
                float2 uv : TEXCOORD0; // Texture coordinates
            };

            // Define output structure for vertex shader
            struct v2f
            {
                float4 screemPos : SV_POSITION; // Screen space position
                half3 normal : TEXCOORD0; // Interpolated normal
                half3 worldPos : TEXCOORD1; // World space position
                half3 viewDir : TEXCOORD2; // View direction
                float2 uv : TEXCOORD3; // Interpolated texture coordinates
            };

            // Define shader properties
            sampler2D _BaseMap; // Main texture
            float4 _BaseMap_ST; // Texture tiling and offset
            half4 _BaseColor; // Base color

            // Vertex shader function
            v2f vert (AppData IN)
            {
                v2f o;

                // Transform object position to homogeneous clip space
                o.screemPos = TransformObjectToHClip(IN.positionObj.xyz);

                // Transform object normal to world space
                o.normal = TransformObjectToWorldNormal(IN.normal);

                // Calculate world space position
                o.worldPos = mul(unity_ObjectToWorld, IN.positionObj);

                // Calculate view direction
                o.viewDir = normalize(GetWorldSpaceViewDir(o.worldPos));

                // Transform texture coordinates
                o.uv = TRANSFORM_TEX(IN.uv, _BaseMap);

                return o;
            };

            // Fragment shader function
            half4 frag(v2f IN) : SV_Target
            {
                // Calculate dot product between normal and view direction
                float dorProduct = dot(IN.normal, IN.viewDir);
                dorProduct = step(0.3, dorProduct);

                // Sample main texture
                half4 col = tex2D(_BaseMap, IN.uv);

                // Apply base color
                half4 colour = (_BaseColor.rgba);

                // Final color calculation
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
