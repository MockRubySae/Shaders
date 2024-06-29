Shader "Unlit/ToonShader"
{
    Properties
    {
        _Colour("Colur", Color) = (1, 1,1, 1)
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "RenderPipeline" = "UniversalPipeline" }

        Pass
        {
            HLSLPROGRAM
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fog
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
            
            sampler2D _MainTex;
            float4 _MainTex_ST;
            half3 _Colour;
            v2f vert (AppData IN)
            {
                v2f o;

                o.screemPos = TransformObjectToHClip(IN.positionObj.xyz);
                o.normal = TransformObjectToWorldNormal(IN.normal);
                o.worldPos = mul(unity_ObjectToWorld, IN.positionObj);
                o.viewDir = normalize(GetWorldSpaceViewDir(o.worldPos));
                o.uv = TRANSFORM_TEX(IN.uv, _MainTex);
                return o;
            };

            half4 frag(v2f IN) : SV_Target
            {
                float dorProduct = dot(IN.normal, IN.viewDir);
                dorProduct = step(0.3, dorProduct);
                half3 col = tex2D(_MainTex, IN.uv);
                half3 colour = (_Colour.rgb);
                half3 finalColour = col * colour * dorProduct;
                return half4(finalColour,1);
            };
            
            ENDHLSL
        }
    }
}
