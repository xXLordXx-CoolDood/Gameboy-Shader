Shader "Screen/PixelArtShader" {
    Properties {
        _MainTex ("Texture", 2D) = "white" {}
    }

    SubShader {

        CGINCLUDE
            #include "UnityCG.cginc"

            struct VertexData {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            Texture2D _MainTex;
            SamplerState point_clamp_sampler;
            float4 _MainTex_TexelSize;

            v2f vp(VertexData v) {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }
            ENDCG

            Pass{
                CGPROGRAM
                #pragma vertex vp
                #pragma fragment fp

            float4 _ToneVeryLight, _ToneLight, _ToneDark, _ToneVeryDark;
            float _Spread, _Contrast, _BrightnessMultiplier;
            int _DitherColorCount, _BayerLevel, _Palettize, _ApplyPalettize;

            static const int bayer2[2 * 2] = {
                0, 2,
                3, 1
            };

            static const int bayer4[4 * 4] = {
                0, 8, 2, 10,
                12, 4, 14, 6,
                3, 11, 1, 9,
                15, 7, 13, 5
            };

            static const int bayer8[8 * 8] = {
                0, 32, 8, 40, 2, 34, 10, 42,
                48, 16, 56, 24, 50, 18, 58, 26,  
                12, 44,  4, 36, 14, 46,  6, 38, 
                60, 28, 52, 20, 62, 30, 54, 22,  
                3, 35, 11, 43,  1, 33,  9, 41,  
                51, 19, 59, 27, 49, 17, 57, 25, 
                15, 47,  7, 39, 13, 45,  5, 37, 
                63, 31, 55, 23, 61, 29, 53, 21
            };

            float GetBayer2(int x, int y) {
                return float(bayer2[(x % 2) + (y % 2) * 2]) * (1.0f / 4.0f) - 0.5f;
            }

            float GetBayer4(int x, int y) {
                return float(bayer4[(x % 4) + (y % 4) * 4]) * (1.0f / 16.0f) - 0.5f;
            }

            float GetBayer8(int x, int y) {
                return float(bayer8[(x % 8) + (y % 8) * 8]) * (1.0f / 64.0f) - 0.5f;
            }

            fixed4 fp(v2f i) : SV_Target {
                float4 col = _MainTex.Sample(point_clamp_sampler, i.uv);
                //Calculate dither values
                int x = i.uv.x * _MainTex_TexelSize.z;
                int y = i.uv.y * _MainTex_TexelSize.w;

                float _brightness = dot(col.rgb, float3(0.299, 0.587, 0.114));

                float bayerValues[3] = { 0, 0, 0 };
                bayerValues[0] = GetBayer2(x, y);
                bayerValues[1] = GetBayer4(x, y);
                bayerValues[2] = GetBayer8(x, y);

                //Apply dither effect
                _Spread *= _brightness;

                float4 output = half4(col.r, col.g, col.b, col.a) + _Spread * bayerValues[_BayerLevel];

                output.r = floor((_DitherColorCount - 1.0f) * output.r + 0.5) / (_DitherColorCount - 1.0f);
                output.g = floor((_DitherColorCount - 1.0f) * output.g + 0.5) / (_DitherColorCount - 1.0f);
                output.b = floor((_DitherColorCount - 1.0f) * output.b + 0.5) / (_DitherColorCount - 1.0f);

                //Apply 4 color palette if enabled
                if (_Palettize > 0) {
                    //Greyscale colors in image, convert to HSL, set our saturation
                    half gray = dot(output.rgb, float3(0.299, 0.587, 0.114));

                    //Brighten the image (make brighter spots MUCH brighter)
                    gray *= _BrightnessMultiplier * clamp(gray, 1, 255);
                    
                    //Round the greyscale color to the nearest tone
                    gray = floor((4 - 1.0f) * gray + 0.5) / (4 - 1.0f);

                    //Map the output to the desired color depending on it's nearest tone.
                    if (gray < 0.25) { output = _ToneVeryDark; }
                    else if (gray < 0.5) { output = _ToneDark; }
                    else if (gray < 0.75) { output = _ToneLight; }
                    else { output = _ToneVeryLight; }
                }

                return output;
            }
            ENDCG
        }

        Pass {
            CGPROGRAM
            #pragma vertex vp
            #pragma fragment fp

            fixed4 fp(v2f i) : SV_Target {
                return _MainTex.Sample(point_clamp_sampler, i.uv);
            }
            ENDCG
        }
    }
}