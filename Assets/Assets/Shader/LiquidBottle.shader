Shader "Unlit/LiquidBottle"
{
    Properties
    {
        _Height("Liquid Height", Range(0, 1)) = 0
        _MinHeight("Minimum Height", Float) = 0
        _MaxHeight("Maximum Height", Float) = 0
        _WobbleX("WobbleX", Float) = 0
        _WobbleZ("WobbleZ", Float) = 0
        _FrontFaceColor("Front Face Color", Color) = (1,1,1,1)
        _BackFaceColor("Back Face Color", Color) = (1,1,1,1)
        
        _FresnelColor ("Fresnel Color", Color) = (0,0.99,0.91,1)
        _FresnelExponent("Fresnel Exponent", Int) = 1
        
        [Enum(UnityEngine.Rendering.BlendMode)]
        _SrcBlend("Source Blend Factor", Int) = 1
        
        [Enum(UnityEngine.Rendering.BlendMode)]
        _DstBlend("Destination Blend Factor", Int) = 1
        
        [Header(Sine)]
        _Freq ("Frequency", Range(0,15)) = 8
        _Amplitude ("Amplitude", Range(0,0.5)) = 0.15
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" "RenderPipeline"="UniversalRenderPipeline" "Queue"="Transparent" }

        Cull Off
        Pass
        {
            ZWrite Off
            Blend [_SrcBlend] [_DstBlend]
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fog

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct appdata
            {
                float4 positionOS : POSITION;
                float3 normal : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float3 positionWS : TEXCOORD0;
                float2 uv : TEXCOORD1;
                float3 viewDir : TEXCOORD2;
                float3 normalWS : TEXCOORD3;
            };

            float _Height;
            float _MinHeight;
            float _MaxHeight;
            float _WobbleX;
            float _WobbleZ;
            float4 _BackFaceColor;
            float4 _FrontFaceColor;

            float4 _FresnelColor;
            float _FresnelExponent;

            float _Freq;
            float _Amplitude;
            
             float3 Unity_RotateAboutAxis_Degrees(float3 In, float3 Axis, float Rotation)
            {
                Rotation = radians(Rotation);
                float s = sin(Rotation);
                float c = cos(Rotation);
                float one_minus_c = 1.0 - c;
 
                Axis = normalize(Axis);
                float3x3 rot_mat = 
                {   one_minus_c * Axis.x * Axis.x + c, one_minus_c * Axis.x * Axis.y - Axis.z * s, one_minus_c * Axis.z * Axis.x + Axis.y * s,
                    one_minus_c * Axis.x * Axis.y + Axis.z * s, one_minus_c * Axis.y * Axis.y + c, one_minus_c * Axis.y * Axis.z - Axis.x * s,
                    one_minus_c * Axis.z * Axis.x - Axis.y * s, one_minus_c * Axis.y * Axis.z + Axis.x * s, one_minus_c * Axis.z * Axis.z + c
                };
                float3 Out = mul(rot_mat,  In);
                return Out;
            }
            
            v2f vert (appdata inputData)
            {
                v2f output;
                output.vertex = mul(UNITY_MATRIX_MVP, inputData.positionOS);

                 float3 worldPos = mul (UNITY_MATRIX_M, inputData.positionOS.xyz);  
                float3 worldPosOffset = float3(worldPos.x, worldPos.y , worldPos.z) - _Height;
                // rotate it around XY
                float3 worldPosX= Unity_RotateAboutAxis_Degrees(worldPosOffset, float3(0,0,1),90);
                // rotate around XZ
                float3 worldPosZ = Unity_RotateAboutAxis_Degrees(worldPosOffset, float3(1,0,0),90);
                // combine rotations with worldPos, based on sine wave from script
                float3 worldPosAdjusted = worldPos + (worldPosX  * _WobbleX)+ (worldPosZ* _WobbleZ);
                 output.viewDir = _WorldSpaceCameraPos - worldPos;
                output.normalWS = mul(UNITY_MATRIX_M, float4(inputData.normal, 0));
                output.positionWS = worldPosAdjusted;
                output.uv = inputData.uv;
          

                
                return output;
            }

            float4 frag (v2f i, half facing : VFACE) : SV_Target
            {
                    float mappedHeight = lerp(_MinHeight, _MaxHeight, _Height);
                    float liquidPosition = smoothstep(mappedHeight, mappedHeight - 0.01, i.positionWS.y);

                    float wobbleIntensity =  abs(_WobbleX) + abs(_WobbleZ);            
                    float wobble = sin((liquidPosition * _Freq) + (liquidPosition * _Freq ) + ( _Time.y)) * (_Amplitude *wobbleIntensity);               
                    liquidPosition = liquidPosition + wobble;

                    float fresnel = pow(1 - saturate(dot(normalize(i.normalWS), normalize(i.viewDir))), _FresnelExponent);
                    fresnel+=liquidPosition;
                    float4 fresnelColor = _FresnelColor * fresnel;
                
                    float liquidPositionBack = smoothstep(mappedHeight + 0.01, mappedHeight - 0.01, i.positionWS.y);
    
                    float4 color = _FrontFaceColor * liquidPosition + fresnelColor;
                    float4 backColor = _BackFaceColor * liquidPositionBack + fresnelColor;
             
                
                    return facing > 0 ? color : backColor;
            }
            ENDHLSL
        }
    }
}
