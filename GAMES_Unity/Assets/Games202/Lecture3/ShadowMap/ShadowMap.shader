Shader "Unlit/ShadowMap"
{
    Properties
    {
        _MainTex("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            sampler2D _MainTex;
            float4 _MainTex_ST;

            struct v2f {
                float4 pos:SV_POSITION;
                float2 uv:TEXCOORD0;
                float4 proj : TEXCOORD3;
                float2 depth : TEXCOORD4;
            };


            float4x4 ProjectionMatrix;
            sampler2D DepthTexture;

            v2f vert(appdata_full v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);

                //动态阴影
                o.depth = o.pos.zw;
                ProjectionMatrix = mul(ProjectionMatrix, unity_ObjectToWorld);
                o.proj = mul(ProjectionMatrix, v.vertex);
                //--------------------------------------------------
                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
                return o;
            }

            fixed4 frag(v2f v) : COLOR
            {

                fixed4 col = tex2D(_MainTex, v.uv);
                float depth = v.depth.x / v.depth.y;

				//核心代码,变换到0-1
				#if defined (SHADER_TARGET_GLSL)
                    //(-1,1)-->(0,1)
                    depth = depth*0.5+0.5;
                #elif defined (UNITY_REVERSED_Z)
                    //(1,0)-->(0,1)
                    depth = 1-depth;
                #endif

                fixed4 dcol = tex2Dproj(DepthTexture, v.proj);
                float d = DecodeFloatRGBA(dcol);
                float shadowScale = 1;
                if(depth > d)
                {
                    shadowScale = 0.55;
                }
                return col*shadowScale;
            }
            ENDCG
        }
    }
}
