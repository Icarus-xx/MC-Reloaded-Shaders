//
#version 130

uniform sampler2D sampler0;

vec4 TexCoord0 = gl_TexCoord[0];

const float blurSize = 1.0 / 512.0; // I've chosen this size because this will result in that every step will be one pixel wide if the RTScene texture is of size 512x512

void main(void)
{
    vec4 baseColor = texture2D( sampler0, TexCoord0.st );

#ifdef BLUR_SP

   vec4 sum = vec4(0.0);

   // blur in y (vertical)
   // take nine samples, with the distance blurSize between them
   sum += texture2D(sampler0, vec2(TexCoord0.x, TexCoord0.y - 4.0*blurSize)) * 0.05;
   sum += texture2D(sampler0, vec2(TexCoord0.x, TexCoord0.y - 3.0*blurSize)) * 0.09;
   sum += texture2D(sampler0, vec2(TexCoord0.x, TexCoord0.y - 2.0*blurSize)) * 0.12;
   sum += texture2D(sampler0, vec2(TexCoord0.x, TexCoord0.y - blurSize)) * 0.15;
   sum += texture2D(sampler0, vec2(TexCoord0.x, TexCoord0.y)) * 0.16;
   sum += texture2D(sampler0, vec2(TexCoord0.x, TexCoord0.y + blurSize)) * 0.15;
   sum += texture2D(sampler0, vec2(TexCoord0.x, TexCoord0.y + 2.0*blurSize)) * 0.12;
   sum += texture2D(sampler0, vec2(TexCoord0.x, TexCoord0.y + 3.0*blurSize)) * 0.09;
   sum += texture2D(sampler0, vec2(TexCoord0.x, TexCoord0.y + 4.0*blurSize)) * 0.05;

    baseColor = sum;
#endif

   gl_FragColor = baseColor;
}
