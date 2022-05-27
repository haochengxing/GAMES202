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
                float4 proj : TEXCOORD1;
                float2 depth : TEXCOORD2;
				float3 worldPos :TEXCOORD3;
				float3 normal : TEXCOORD4;
            };


            float4x4 ProjectionMatrix;
            sampler2D DepthTexture;
			float4 LightPos;
			float TexturePixel;

			float pcfShadow(float2 pos,float depth,float bias){
				float shadow = 0.0;
				float2 texelSize = float2(1.0/TexturePixel,1.0/TexturePixel);
				for(float x=-1;x<=1;x++){
					for(float y=-1;y<=1;y++){
						float2 samplePos = pos + float2(x,y)*texelSize;
						float4 pcfDepthRGBA = tex2D(DepthTexture,samplePos);
						float pcfDepth = DecodeFloatRGBA(pcfDepthRGBA);
						shadow += depth - bias > pcfDepth ? 1.0:0.0;
					}
				}
				

				shadow /=  9.0;

				float shadowScale = 1-shadow;

				return shadowScale;
			}



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
				o.worldPos = mul(unity_ObjectToWorld,v.vertex).xyz;
				o.normal = v.normal;
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

                //fixed4 dcol = tex2Dproj(DepthTexture, v.proj);
                //float d = DecodeFloatRGBA(dcol);
                

				float3 lightDir = normalize(LightPos - v.worldPos);
				float bias = max(0.05 * (1.0 - dot(v.normal, lightDir)), 0.005);



				float shadowScale = pcfShadow(v.proj.xy,depth,bias);

				//float shadowScale = 1;
                //if(depth-bias > d)
                //{
                    //shadowScale = 0.55;
                //}
                return col*shadowScale;
            }

			
            ENDCG
        }
    }
}
