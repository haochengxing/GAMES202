Shader "Unlit/DepthTexture"
{
    SubShader
    {
        Tags { "RenderType"="Opaque" }

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float2 depth : TEXCOORD1;
            };

            
            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.depth = o.vertex.zw;
                return o;
            }
            
            fixed4 frag (v2f i) : SV_Target
            {
                float depth = i.depth.x/i.depth.y;
				//核心代码,变换到0-1
				#if defined (SHADER_TARGET_GLSL)
					depth = depth*0.5+0.5;//(-1,1)-->(0,1)
				#elif defined (UNITY_REVERSED_Z)
					depth = 1-depth;//(1,0)-->(0,1)
				#endif
                fixed4 col = EncodeFloatRGBA(depth);
                return col;
            }
            ENDCG
        }
    }
}
