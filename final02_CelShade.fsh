//
#version 130

uniform sampler2D sampler0;
uniform sampler2D cleanDepth2;
uniform sampler2D sampler2;

uniform float displayWidth;
uniform float displayheight;
uniform float aspectRatio;
uniform float near;
uniform float far;

vec4 TexCoord0 = gl_TexCoord[0];

#ifdef CEL_SHADING

    float getEdgeDepth(vec2 coord) {

/*
    if ( coord.x < 0.0 ) coord.x = -coord.x;                // should not sample outside the screen as there are no infos
    if ( coord.x > 1.0 ) coord.x = (1.0-coord.x)+1.0;        // Telling the shader to go back on the tex
    if ( coord.y < 0.0 ) coord.y = -coord.y/2.0;
    if ( coord.y > 1.0 ) coord.y = (1.0-coord.y)+1.0;
*/

    float depth = texture2D( cleanDepth2, coord ).x;
    float depth2 = texture2D( sampler2, coord ).x;
    if ( depth2 < 1.0 ) {
        depth = depth2;
    }
    depth = (2.0 * near) / (far + near - depth * (far - near));
    return depth;

}

    vec4 edgeDetect( vec2 coord ) {
        vec2 o11 = vec2(1.0, aspectRatio)*CEL_EDGE_THICKNESS/displayWidth;
        vec4 color = vec4(0.0);

        float depth = getEdgeDepth(coord);
        float avg = 0.0;
        float laplace = 24.0 * depth;
        float sample;
        int n = 0;

        if (depth <1.0) {
            avg += depth;
            ++n;
        }

        for (int i = -2; i <= 2; ++i) {
            for (int j = -2; j <= 2; ++j) {
                if (i != 0 || j != 0) {
                    sample = getEdgeDepth(coord + vec2(float( i ) * o11.s, float( j ) * o11.t));
                    laplace -= sample;
                    if (sample < 1.0) {
                        ++n;
                        avg += sample;
                    }
                }
            }
        }

        avg = clamp( avg/ float( n ), 0.0, 1.0);

        if ( laplace > avg * CEL_EDGE_THRESHOLD ) {
            color.rgb = mix( vec3( 0.0 ), gl_Fog.color.rgb, 0.75 * avg * avg);
            color.a = 1.0;
        }

        return color;
    }
#endif

void main() {
    vec4 baseColor = texture2D( sampler0, TexCoord0.st );

#ifdef CEL_SHADING
    vec4 outlineColor = edgeDetect( TexCoord0.st );
    if (outlineColor.a != 0.0) {
        baseColor.rgb = outlineColor.rgb;
    }
#endif

    gl_FragColor = baseColor;
}