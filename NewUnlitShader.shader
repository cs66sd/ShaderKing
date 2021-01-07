Shader "Unlit/NewUnlitShader" {
    Properties {
        [Header(Texture)]
            _MainTex ("BaseCol",2D) = "white"{}
            _NormalTex("Normal",2D) = "bump"{}
            _SpeculTex("Specular",2D) = "black"{}
            _AOTex("AO",2D) = "_skybox"{}
            _CubeMap("CubeMap",Cube)    =   "_skybox"{}
            _Dirty("Dirty",2D)  =   "white"{}
        [Header(Diffuse)]
            [HDR]_MainCol("BaseCol", COLOR) = (0,0,0,1)
            _EnvDiffInt("EnvDiffInt",range(0,5)) = 0.2
            [Gamma]_EnvUpCol("EnvTopCol",COLOR) = (0,0,0,1)
            [Gamma]_EnvSideCol("EnvSideCol",COLOR) = (0,0,0,1)
            [Gamma]_EnvDownCol("EnvDownCol",COLOR) = (0,0,0,1)
        [Header(Specular)]
            _SpecPow("SpecPow",range(1,300)) = 20
            _SpecInt("SpecInt",range(0,1))=1
            _EnvSpecInt("EnvSpec",range(0,5)) = 0.4
            _FresnelPow("FresnelPow",range(0,2)) = 1
            _CubeMip("CubeMip",range(1,15)) = 1
        [Header(Additional)]
            _AO("AO",range(1,10)) = 1
            _DirtyCol("DirtyCol",COLOR) = (0,0,0,1)
            [PowerSlider(15)]_DIrtyInt("Dirty",range(1,400))=10


    }
    SubShader {    
        Tags {
            "RenderType"="Opaque"
           
        }
        Pass {
            Name "FORWARD"
            Tags{
                 "LightMode"="ForwardBase"
            }
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            #include "AutoLight.cginc"
            #include "Lighting.cginc"
            #pragma multi_compile_fwdbase_fullshadows
            #pragma target 3.0

			uniform sampler2D _MainTex ;
            uniform fixed4  _MainTex_ST;
			uniform sampler2D _NormalTex;
			uniform sampler2D _SpeculTex;
			uniform sampler2D _AOTex;
            uniform sampler2D _Dirty;
            uniform fixed4  _Dirty_ST;
            uniform samplerCUBE _CubeMap;
			uniform fixed4 _MainCol;
			uniform fixed _EnvDiffInt;
			uniform fixed4 _EnvUpCol;
			uniform fixed4 _EnvSideCol;
			uniform fixed4 _EnvDownCol;
			uniform fixed _SpecPow;
			uniform fixed _EnvSpecInt;
			uniform fixed _FresnelPow;
			uniform fixed _CubeMip;
			uniform fixed _AO;
            uniform fixed _SpecInt;
            uniform fixed4 _DirtyCol;
            uniform fixed   _DIrtyInt;

			struct VertexInput {
                float4 vertex        :       POSITION;   // 将模型顶点信息输入进来
                float3 normal      :    NORMAL;     // 将模型法线信息输入进来
                float2 uv0            :     TEXCOORD0;
                fixed4 tangent     :    TANGENT;
            };
            // 输出结构
            struct VertexOutput {
                float4 pos : SV_POSITION;   // 由模型顶点信息换算而来的顶点屏幕位置
                half3 nDirWS : TEXCOORD0;  // 由模型法线信息换算来的世界空间法线信息
                float2 uv0 : TEXCOORD1;
                float3 posWS    :    TEXCOORD2;
                half3 tDirWS   :   TEXCOORD3;
                half3 bDirWS   :   TEXCOORD4;
                LIGHTING_COORDS(5,6)
            };

            // 输入结构>>>顶点Shader>>>输出结构
            VertexOutput vert (VertexInput v) {
                VertexOutput o = (VertexOutput)0;               // 新建一个输出结构
                    o.pos = UnityObjectToClipPos( v.vertex );       // 变换顶点信息 并将其塞给输出结构
                    o.uv0 = TRANSFORM_TEX(v.uv0,_MainTex);
                    o.posWS = mul(unity_ObjectToWorld,v.vertex);
                    o.nDirWS = UnityObjectToWorldNormal(v.normal);  // 变换法线信息 并将其塞给输出结构
                    o.tDirWS = normalize(mul(unity_ObjectToWorld,fixed4(v.tangent.xyz , 0.0)).xyz);
                    o.bDirWS = normalize(cross(o.nDirWS, o.tDirWS) * v.tangent.w);
                    TRANSFER_VERTEX_TO_FRAGMENT(o)
                return o;                                       // 将输出结构 输出
            }
            // 输出结构>>>像素
            fixed4 frag(VertexOutput i) : COLOR {

                //准备向量
                fixed3 nDirTS   =   UnpackNormal(tex2D(_NormalTex,i.uv0)).rgb;
                fixed3x3 TBN    =   fixed3x3(i.tDirWS, i.bDirWS, i.nDirWS);
                fixed3 nDirWS = normalize(mul(nDirTS ,TBN)); 

                fixed3 vDirWS = normalize(_WorldSpaceCameraPos.xyz - i.posWS.xyz);
                fixed3 vrDirWS = reflect(-vDirWS ,nDirWS);
                fixed3 lDirWS = _WorldSpaceLightPos0.xyz;
                fixed3 lrDirWS = reflect(lDirWS,nDirWS);

                //准备点积,lambert,phpng,fresneal
                fixed ndotl = dot(nDirWS,   lDirWS);
                fixed vdotr = dot(vDirWS,   lDirWS);
                fixed vdotn = dot(vDirWS,   nDirWS);

                //纹理采样
                fixed4 var_MainTex  =   tex2D(_MainTex,i.uv0);
                fixed4 var_SpecTex  =   tex2D(_SpeculTex, i.uv0);
                fixed4  var_Dirty   =   tex2D(_Dirty,i.uv0);
                
                fixed   dirtyint =  lerp(1.0,_DIrtyInt,var_Dirty);
                fixed   dirty =  pow(max(0.0,vdotr),dirtyint);
                fixed   dity_col    =   dirty*_DirtyCol;
                
                fixed3 var_AOTex  =   tex2D(_AOTex,i.uv0).rgb;
                fixed cubemapMip = lerp(_CubeMip, 1.0, var_SpecTex*0.3);
                fixed3 var_Cubemap  =   texCUBElod(_CubeMap, fixed4(vrDirWS, cubemapMip)).rgb;

                //光照模型
                fixed3 ambi =   UNITY_LIGHTMODEL_AMBIENT.xyz;
                    //光照漫反射
                    fixed3 basecol  =   var_MainTex.rgb * _MainCol;
                    fixed3 lambert   =   0.5*ndotl+0.5;
                    //光滑镜面反射
                    fixed3 specCol   =   var_SpecTex.r*_SpecInt*basecol ;
                    fixed specPow= lerp(1.0,_SpecPow,    var_SpecTex);
                    fixed phong =  pow(max(0.0, vdotr), specPow);
                    //光源反射混合
                    fixed shadow = LIGHT_ATTENUATION(i);
                    fixed3  direct_l    =   (basecol*lambert+phong +specCol ) *   _LightColor0  *   pow(shadow,300);

                    //环境漫反射
                    fixed up_mask   =   max(0.0,    nDirWS.g);
                    fixed down_mask =   max(0.0 ,  nDirWS.r);
                    fixed   side_mask   =   1.0-up_mask-down_mask;
                    fixed3 EnvCol = up_mask*_EnvUpCol   +   side_mask   *   _EnvSideCol +   down_mask   *   _EnvDownCol;
                    fixed3 encDiff  =   EnvCol  *   basecol *   _EnvDiffInt;

                    //环境镜面反射
                    fixed fresnel = pow(max(0.0,1.0-vdotn), _FresnelPow);
                    fixed3  envspec =   var_Cubemap *   fresnel *   _EnvSpecInt *   2;
                    fixed3  envspec1    =   lerp(0.0,envspec,var_SpecTex);
                    //环境反射混合
                    fixed oculusion = var_AOTex;
                    fixed3 envLighting  =   (encDiff+envspec1);
                    //自发光
                    //最终
                    fixed3  final   =   (envLighting +   direct_l)  *   oculusion   +  dirty*_DirtyCol*0.6;

                
                 return fixed4(final,1.0);  // 输出最终颜色
            }
            ENDCG
        }
    }
    FallBack "Diffuse"
}
