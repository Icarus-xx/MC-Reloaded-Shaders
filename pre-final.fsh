//
#version 130
/*
//#define AA_ENABLED
*/
/*
-------------------------------------------------------
 The standard user should not mess with anything below
-------------------------------------------------------
*/

uniform sampler2D sampler0;
uniform sampler2D sampler1;
uniform sampler2D sampler2;
uniform float aspectRatio;
uniform float near;
uniform float far;

vec4 TexCoord0 = gl_TexCoord[0];

const float INFINITY = 1000.0;

#ifdef AA_ENABLED // Stuff only AA uses
	float expDepth2linearDepth( vec2 coord ) {
		float depth = texture2D( sampler1, coord ).x;
		float depth2 = texture2D( sampler2, coord ).x;
		if ( depth2 < 1.0 ) {
			depth = depth2;
		}
		if ( depth == 1.0 ) {
			return INFINITY;
		}
		return (2.0 * near) / (far + near - depth * (far - near));
	}

	vec4 getAA() {
		vec4 newColor = vec4(0.0);

		float depth = expDepth2linearDepth(TexCoord0.xy);
		vec2 aspectCorrection = vec2(1.0, aspectRatio) * 0.005;
		float offsetx = 0.12 * aspectCorrection.x;
		float offsety = 0.12 * aspectCorrection.y;
		float depthThreshold=0.01;

		if ( abs( depth - expDepth2linearDepth( TexCoord0.xy + vec2( offsetx, 0 ) ) ) > depthThreshold || abs( depth - expDepth2linearDepth( TexCoord0.xy + vec2( -offsetx, 0 ) ) ) > depthThreshold || abs( depth - expDepth2linearDepth( TexCoord0.xy + vec2( 0, offsety ) ) ) > depthThreshold || abs( depth - expDepth2linearDepth( TexCoord0.xy + vec2( 0, -offsety ) ) ) > depthThreshold ) {
			newColor += texture2D(sampler0, TexCoord0.st + vec2(-offsetx, offsety));
			newColor += texture2D(sampler0, TexCoord0.st + vec2(0, offsety));
			newColor += texture2D(sampler0, TexCoord0.st + vec2(offsetx, offsety));
			newColor += texture2D(sampler0, TexCoord0.st + vec2(-offsetx, 0));
			newColor += texture2D(sampler0, TexCoord0.st);
			newColor += texture2D(sampler0, TexCoord0.st + vec2(offsetx, 0));
			newColor += texture2D(sampler0, TexCoord0.st + vec2(-offsetx, -offsety));
			newColor += texture2D(sampler0, TexCoord0.st + vec2(0, -offsety));
			newColor += texture2D(sampler0, TexCoord0.st + vec2(offsetx, -offsety));
			newColor /= 9.0;
		} else
			newColor=texture2D(sampler0, TexCoord0.st);

		return newColor;
	}
#endif

void main() {
	vec4 baseColor = texture2D( sampler0, TexCoord0.st );
	
#ifdef AA_ENABLED
	baseColor = getAA();
#else
	baseColor = texture2D( sampler0, TexCoord0.st );
#endif

	gl_FragColor = baseColor;
}