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
            float lightRadius = 0.1;

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


            float Calculate_Avg_Dblockreceiver(float2 projCoords_xy , float AvgTextureSize)
            {
                float2 texelSize = float2(1.0/TexturePixel,1.0/TexturePixel);
                float result=0.0;
                for(float i=-AvgTextureSize;i<=AvgTextureSize;++i)
                {
                    for(float j=-AvgTextureSize;j<=AvgTextureSize;j++)
                    {
                        float2 samplePos = projCoords_xy + float2(i,j)*texelSize;
						float4 depthRGBA = tex2D(DepthTexture,samplePos);
						float depth = DecodeFloatRGBA(depthRGBA);
                        result += depth; 
                    }
                }
                return result/(AvgTextureSize*AvgTextureSize*2*2);
            }

            //PCSS
            float PercentageCloserSoftShadowCalculation(float4 projCoords,float depth,float bias)
            {
                float shadow=0;
                
                float texelSize = 1.0/TexturePixel;

                fixed4 dcol = tex2D(DepthTexture, projCoords.xy);
                // 采样ShadowMap中的深度
                float closestDepth = DecodeFloatRGBA(dcol);


                // 获取当前着色点的深度
                float currentDepth = depth;
  
                //计算着色点与平均遮挡物的距离 dr
                float D_light_block=Calculate_Avg_Dblockreceiver(projCoords.xy,7);
                float D_block_receiver= (currentDepth-D_light_block);
                // 检查当前点是否在阴影中
                if( D_light_block<0.01f)
                    return 0.0;
                //利用平均遮挡物距离dr计算PCF用到的采样范围 Wsample
                float fliterArea=D_block_receiver/(D_light_block*projCoords.w) *lightRadius;
                float fliterSingleX=float(fliterArea);
                float count=0;
                fliterSingleX = fliterSingleX >40?40: fliterSingleX;
                fliterSingleX = fliterSingleX <1?10: fliterSingleX;
                //计算PCF

                [unroll(40)]
                for(float i=-fliterSingleX;i<=fliterSingleX;++i)
                {
                    count++;
                    [unroll(40)]
                    for(float j=-fliterSingleX;j<=fliterSingleX;j++)
                    {
                        //  采样周围点在ShadowMap中的深度
                        float4 samplePos = projCoords + float4(i,j,0,0)*texelSize;
						float4 depthRGBA = tex2Dproj(DepthTexture,samplePos);
						float closestDepth = DecodeFloatRGBA(depthRGBA);

                        shadow += currentDepth-bias > closestDepth?1.0:0.0;
                    }
                }
                count = count >0? count :1;
                shadow = shadow/float(count*count);
    
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



				//float shadowScale = pcfShadow(v.proj.xy,depth,bias);

                float shadowScale = PercentageCloserSoftShadowCalculation(v.proj,depth,bias);

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
