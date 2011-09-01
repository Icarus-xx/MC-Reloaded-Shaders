#version 130

uniform sampler2D sampler0;
uniform sampler2D sampler2;
uniform sampler2D cleanDepth;

uniform float far;
uniform float near;

uniform int biomeType;
uniform int inWater;
uniform int worldTime;
uniform int isWet;

vec4 TexCoord0 = gl_TexCoord[0];

float t = 24000.0 - ( 2.0 * abs(12000.0 - float(worldTime)));

const float PI2 = 6.283185307179586476925286766559;

#ifdef HEAT_HAZE
float getDepth( vec2 coord ) {
    float depth = texture2D( cleanDepth, coord ).x;
    depth = (2.0 * near) / (far + near - depth * (far - near));
    return depth;
}

float getTime() {
        float DAY = 1.0;
        float time;

    if (biomeType != 12) {
        if (worldTime >= 22000) {
            time = clamp((float(24000-worldTime))/2000.0, 0.0, 1.0);
            DAY = 1.0 - time;
        } else if (worldTime >= 12500) {
            time = clamp ((float(13500-worldTime))/1000.0, 0.0, 1.0);
            DAY = 0.0 + time;
        }
    }
        return DAY;
    }

float getMaskFromDepth( vec2 coord ) {

        float depth = texture2D( cleanDepth, coord ).x;
        float depth2 = texture2D( sampler2, coord ).x;

        float handMask = 1.0;
        if ( depth2 < 1.0 ) handMask = 0.0;

        depth = (2.0 * near) / (far + near - depth * (far - near));

        if ( coord.x-0.05 < 0.0 ) coord.x = coord.x+0.05;                        // should not sample outside the screen as there are no infos
        if ( coord.x+0.05 > 1.0 ) coord.x = coord.x-0.05;        // Telling the shader to go back on the tex
        if ( coord.y-0.1< 0.0 ) coord.y = coord.y+0.1;
        if ( coord.y+0.1 > 1.0 ) coord.y = coord.y-0.1;

        if (biomeType != 12) {
            if ( depth < 1.0 ) {
                float dComp1 =  texture2D( cleanDepth, coord+vec2(0.05, 0.1)).x;
                float dComp2 =  texture2D( cleanDepth, coord+vec2(-0.05, 0.1)).x;
                dComp1 = (2.0 * near) / (far + near - dComp1 * (far - near));
                dComp2 = (2.0 * near) / (far + near - dComp2 * (far - near));
                if ( dComp1 < 1.0 && dComp2 < 1.0 ) {
                    depth = 0;
                } else depth = 1.0;
            } else {
                float dComp1 =  texture2D( cleanDepth, coord+vec2(0.05, -0.1)).x;
                float dComp2 =  texture2D( cleanDepth, coord+vec2(-0.05, -0.1)).x;
                dComp1 = (2.0 * near) / (far + near - dComp1 * (far - near));
                dComp2 = (2.0 * near) / (far + near - dComp2 * (far - near));
                if ( dComp1 >= 1.0 && dComp2 >= 1.0 ) {
                    depth = 0;
                } else depth = 1.0;
            }
        } else {
            depth = (depth + 2.0) / 3.0;
        }

    return depth * handMask;

    }

    int icoolfFunc3d2( in int n )
    {
        n=(n<<13)^n;
        return (n*(n*n*15731+789221)+1376312589) & 0x7fffffff;
    }

    float coolfFunc3d2( in int n )
    {
        return float(icoolfFunc3d2(n));
    }

    float noise3f( in vec3 p )
    {
        ivec3 ip = ivec3(floor(p));
        vec3 u = fract(p);
        u = u*u*(3.0-2.0*u);

        int n = ip.x + ip.y*57 + ip.z*113;

        float res = mix(mix(mix(coolfFunc3d2(n+(0+57*0+113*0)),
                                coolfFunc3d2(n+(1+57*0+113*0)),u.x),
                            mix(coolfFunc3d2(n+(0+57*1+113*0)),
                                coolfFunc3d2(n+(1+57*1+113*0)),u.x),u.y),
                        mix(mix(coolfFunc3d2(n+(0+57*0+113*1)),
                                coolfFunc3d2(n+(1+57*0+113*1)),u.x),
                            mix(coolfFunc3d2(n+(0+57*1+113*1)),
                                coolfFunc3d2(n+(1+57*1+113*1)),u.x),u.y),u.z);

        return 1.0 - res*(1.0/1073741824.0);
    }

    float noise2f(vec2 p)
    {
      return noise3f(vec3(p,0));
    }
#endif

#ifdef WATER_BOBBLE

    vec2 getInWater() {
        vec3 coord = vec3(TexCoord0.st, 1.0);
        float N = 1.0;
        float D = 16.0;
        float T = 20.0;

        if (inWater == 1) { T = 150.0; N = 80.0; D = 1.0;
                t /= T;

                vec3 offset, base;
                    coord = modf(D*coord, base);
                    offset = vec3(sin(PI2*coord.s + t)*cos(PI2*(coord.t + t))*cos(PI2*t)/N,
                            -cos(PI2*(coord.s + t))*sin(2.0*PI2*(coord.t+ t))/N,0) ;


                    coord = mod(coord + offset, vec3(1.0)) + base;
                    coord = coord/D;

                    return coord.st;
        }
    }
#endif


void main() {

    vec4 baseColor = texture2D(sampler0, TexCoord0.st);

#ifdef WATER_BOBBLE
                baseColor = texture2D(sampler0, getInWater() );
#endif

#ifdef HEAT_HAZE
    if (biomeType == 5 || biomeType == 8 || biomeType == 12) {
        float n = noise3f(vec3(t*baseColor.r*0.2, t*baseColor.g*0.2,t*baseColor.b*0.2))*0.003;

        vec4 distort = texture2D(sampler0, TexCoord0.st+vec2(-2.0*n, -n));
        baseColor = mix(baseColor,distort,getTime()*getMaskFromDepth(TexCoord0.st)*0.5);
        }
#endif

    gl_FragColor = baseColor;

}