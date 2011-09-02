//
#version 130

uniform int raining;
uniform int rainingTransition;
uniform sampler2D sampler0;
uniform int handItemId;

uniform float displayWidth;
uniform float displayHeight;
uniform int worldTime;

vec4 TexCoord0 = gl_TexCoord[0];

float
getTime ()
{
    float DAY = 0.8;
    float time;

    if (worldTime >= 22000)
    {
        time = clamp ((float (24000 - worldTime)) /10000.0, 0.0, 1.0);
        DAY = 0.8 + time;
    }
    else if (worldTime >= 13000)
    {
        time = clamp ((float (14000 - worldTime)) /5000.0, 0.0, 1.0);
        DAY = 1.0 - time;
    }
    return DAY;
}

void
main ()
{
    vec4 baseColor = texture2D (sampler0, TexCoord0.st);

#ifdef GAMMA
    float G = GAMMA * getTime ();
    if (baseColor[3] == 0.0)
    {
        baseColor = gl_Fog.color;
    }
    else
    {
        baseColor.rgb = pow (baseColor.rgb, vec3 (1.0 / G));
    }
#endif

#ifdef THERMAL_VISION
    if (handItemId == thermal_vision_itemid)
    {
        vec2 uv = TexCoord0.xy;
        vec3 pixcol = baseColor.rgb;
        vec3 colors[3];
        colors[0] = vec3 (0., 0., 1.);
        colors[1] = vec3 (1., 1., 0.);
        colors[2] = vec3 (1., 0., 0.);
//    float lum = (pixcol.r+pixcol.g+pixcol.b)/3.;
        float lum = dot (vec3 (0.30, 0.59, 0.11), pixcol.rgb);
        int ix = (lum < 0.5) ? 0 : 1;
        vec3 tc =
            mix (colors[ix], colors[ix + 1], (lum - float (ix) * 0.5) /0.5);
        baseColor = vec4 (tc, 1.0);
    }
#endif

#ifdef NIGHTVISION
    if (handItemId == nightvision_itemid)
    {
        //Noise
        float noise =
            (fract
             (sin (dot (TexCoord0.st, vec2 (12.0, 78.0) + float (worldTime)))
              * 43758.0));
        //Nightvision
        vec4 texcolor = baseColor;  // texture2D(sampler0, TexCoord0.st);
        float gray = dot (texcolor.rgb, vec3 (1.0, 1.0, 1.0));  //The gray
        //vignette
        float dist_nv_left = distance (TexCoord0.xy, vec2 (0.3, 0.5));
        float dist_nv_right = distance (TexCoord0.xy, vec2 (0.7, 0.5));
        vec4 vigfin_l =
            vec4 (smoothstep (lensRadius.x, lensRadius.y, dist_nv_left));
        vec4 vigfin_r =
            vec4 (smoothstep (lensRadius.x, lensRadius.y, dist_nv_right));
        baseColor =
            (vec4 (gray * nvcol, texcolor.a) +
             noise * noiseamount) * vec4 (mix (vigfin_l.rgb, vigfin_r.rgb,
                                               0.5), 1.0);
    }
#endif

#ifdef BW_DREAMS
    vec2 uv3 = TexCoord0.xy;
    vec4 c = baseColor;
    c += texture2D (sampler0, uv3 + 0.001);
    c += texture2D (sampler0, uv3 + 0.003);
    c += texture2D (sampler0, uv3 + 0.005);
//    c += texture2D(sampler0, uv3+0.007);
//    c += texture2D(sampler0, uv3+0.009);
//    c += texture2D(sampler0, uv3+0.011);
    c += texture2D (sampler0, uv3 - 0.001);
    c += texture2D (sampler0, uv3 - 0.003);
    c += texture2D (sampler0, uv3 - 0.005);
//    c += texture2D(sampler0, uv3-0.007);
//    c += texture2D(sampler0, uv3-0.009);
//    c += texture2D(sampler0, uv3-0.011);
    c.rgb = vec3 ((c.r + c.g + c.b) / 3.0);
    c = c / 9.5;
    baseColor = c;
#endif

#ifdef LENS
    vec2 lensRadius2 = vec2 (LENS_OUTRAD, LENS_INRAD);
    vec4 Color = baseColor;
    float dist = distance (TexCoord0.xy, vec2 (0.5, 0.5));
    Color.rgb *= smoothstep (lensRadius2.x, lensRadius2.y, dist);
    baseColor = Color;
#endif

#ifdef WANT_PIXELS
    const float pixel_w = wp_pixel_width;  // 15.0
    const float pixel_h = wp_pixel_height;  // 10.0

    vec2 uv2 = TexCoord0.xy;
    float dx = pixel_w * (1. / displayWidth);
    float dy = pixel_h * (1. / displayHeight);
    vec2 coord = vec2 (dx * floor (uv2.x / dx),
                       dy * floor (uv2.y / dy));
    vec3 tc = texture2D (sampler0, coord).rgb;
    baseColor = vec4 (tc, 1.0);
#endif

#ifdef MOVING_BLACKHOLE
    vec2 cen = vec2 (0.5, 0.5) - TexCoord0.xy;
    vec2 mcen = -               // delete minus for implosion effect
        0.07 * log (length (cen)) * normalize (cen);
    baseColor *= texture2D (sampler0, TexCoord0.xy + mcen);
#endif
    gl_FragColor = baseColor;
}
