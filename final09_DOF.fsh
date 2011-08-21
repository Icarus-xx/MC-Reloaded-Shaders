//
#version 130

uniform sampler2D sampler0;
uniform sampler2D sampler1;
uniform sampler2D sampler2;
uniform sampler2D cleanDepth;

uniform float aspectRatio;
uniform float near;
uniform float far;

vec4 TexCoord0 = gl_TexCoord[0];

float INFINITY = 1000.0;

#ifdef DOF_ENABLED

float getDepth( vec2 coord ) {
	float depth = texture2D( cleanDepth, coord ).x;
	float depth2 = texture2D( sampler2, coord ).x;
	if ( depth2 < 1.0 ) {
		depth = depth2;
	}
	if ( depth == 1.0 ) {
		return INFINITY;
	}
	depth = (2.0 * near) / (far + near - depth * (far - near));
	return depth;

}

	float samples = float( 0 );
	vec2 space;

	float getCursorDepth( vec2 coord ) {
		return (2.0 * near) / (far + near - texture2D( cleanDepth, coord ).x * (far - near));
	}

	vec4 getSampleWithBoundsCheck(vec2 offset) {
		vec2 coord = TexCoord0.st + offset;
		if (coord.s <= 1.0 && coord.s >= 0.0 && coord.t <= 1.0 && coord.t >= 0.0) {
			samples += 1.0;
			return texture2D(sampler0, coord);
		} else {
			return vec4(0.0);
		}
	}

	vec4 getBlurredColor() {
		vec4 blurredColor = vec4( 0.0 );
		float depth = getDepth( TexCoord0.xy );
		vec2 aspectCorrection = vec2( 1.0, aspectRatio ) * 0.005;

		vec2 ac0_4 = 0.4 * aspectCorrection;	// 0.4
		vec2 ac0_29 = 0.29 * aspectCorrection;	// 0.29
		vec2 ac0_15 = 0.15 * aspectCorrection;	// 0.15
		vec2 ac0_37 = 0.37 * aspectCorrection;	// 0.37
		
		vec2 lowSpace = TexCoord0.st;
		vec2 highSpace = 1.0 - lowSpace;
		space = vec2( min( lowSpace.s, highSpace.s ), min( lowSpace.t, highSpace.t ) );
			
		if (space.s >= ac0_4.s && space.t >= ac0_4.t) {

			blurredColor += texture2D(sampler0, TexCoord0.st + vec2(0.0, ac0_4.t));
			blurredColor += texture2D(sampler0, TexCoord0.st + vec2(ac0_4.s, 0.0));   
			blurredColor += texture2D(sampler0, TexCoord0.st + vec2(0.0, -ac0_4.t)); 
			blurredColor += texture2D(sampler0, TexCoord0.st + vec2(-ac0_4.s, 0.0)); 
			blurredColor += texture2D(sampler0, TexCoord0.st + vec2(ac0_29.s, -ac0_29.t));
			blurredColor += texture2D(sampler0, TexCoord0.st + vec2(ac0_29.s, ac0_29.t));
			blurredColor += texture2D(sampler0, TexCoord0.st + vec2(-ac0_29.s, ac0_29.t));
			blurredColor += texture2D(sampler0, TexCoord0.st + vec2(-ac0_29.s, -ac0_29.t));
			blurredColor += texture2D(sampler0, TexCoord0.st + vec2(ac0_15.s, ac0_37.t));
			blurredColor += texture2D(sampler0, TexCoord0.st + vec2(-ac0_37.s, ac0_15.t));
			blurredColor += texture2D(sampler0, TexCoord0.st + vec2(ac0_37.s, -ac0_15.t));
			blurredColor += texture2D(sampler0, TexCoord0.st + vec2(-ac0_15.s, -ac0_37.t));
			blurredColor += texture2D(sampler0, TexCoord0.st + vec2(-ac0_15.s, ac0_37.t));
			blurredColor += texture2D(sampler0, TexCoord0.st + vec2(ac0_37.s, ac0_15.t)); 
			blurredColor += texture2D(sampler0, TexCoord0.st + vec2(-ac0_37.s, -ac0_15.t));
			blurredColor += texture2D(sampler0, TexCoord0.st + vec2(ac0_15.s, -ac0_37.t));
			blurredColor /= 16.0;
			
		} else {
			
			blurredColor += getSampleWithBoundsCheck(vec2(0.0, ac0_4.t));
			blurredColor += getSampleWithBoundsCheck(vec2(ac0_4.s, 0.0));   
			blurredColor += getSampleWithBoundsCheck(vec2(0.0, -ac0_4.t)); 
			blurredColor += getSampleWithBoundsCheck(vec2(-ac0_4.s, 0.0)); 
			blurredColor += getSampleWithBoundsCheck(vec2(ac0_29.s, -ac0_29.t));
			blurredColor += getSampleWithBoundsCheck(vec2(ac0_29.s, ac0_29.t));
			blurredColor += getSampleWithBoundsCheck(vec2(-ac0_29.s, ac0_29.t));
			blurredColor += getSampleWithBoundsCheck(vec2(-ac0_29.s, -ac0_29.t));
			blurredColor += getSampleWithBoundsCheck(vec2(ac0_15.s, ac0_37.t));
			blurredColor += getSampleWithBoundsCheck(vec2(-ac0_37.s, ac0_15.t));
			blurredColor += getSampleWithBoundsCheck(vec2(ac0_37.s, -ac0_15.t));
			blurredColor += getSampleWithBoundsCheck(vec2(-ac0_15.s, -ac0_37.t));
			blurredColor += getSampleWithBoundsCheck(vec2(-ac0_15.s, ac0_37.t));
			blurredColor += getSampleWithBoundsCheck(vec2(ac0_37.s, ac0_15.t)); 
			blurredColor += getSampleWithBoundsCheck(vec2(-ac0_37.s, -ac0_15.t));
			blurredColor += getSampleWithBoundsCheck(vec2(ac0_15.s, -ac0_37.t));
			blurredColor /= samples;
			
		}

		return blurredColor;
	}
#endif

void main() {
	vec4 baseColor = texture2D( sampler0, TexCoord0.st );
	
#ifdef DOF_ENABLED
	float depth = getDepth( TexCoord0.st );
	float cursorDepth = getCursorDepth( vec2( 0.5, 0.5 ) );
	if ( depth < cursorDepth )
		baseColor = mix( baseColor, getBlurredColor(), clamp(2.0 * ((clamp(cursorDepth, 0.0, HYPERFOCAL) - depth) / (clamp(cursorDepth, 0.0, HYPERFOCAL))), 0.0, 1.0));
	else
		baseColor = mix( baseColor, getBlurredColor(), 1.0 - clamp( ( ( ( cursorDepth * HYPERFOCAL ) / ( HYPERFOCAL - cursorDepth ) ) - ( depth - cursorDepth ) ) / ((cursorDepth * HYPERFOCAL) / (HYPERFOCAL - cursorDepth)), 0.0, 1.0));
#endif
	gl_FragColor = baseColor;
}