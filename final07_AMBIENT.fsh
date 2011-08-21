//
#version 130

uniform sampler2D sampler0;
uniform int worldTime;

vec4 TexCoord0 = gl_TexCoord[0];

#ifdef AMBIENT

vec4 getAmbient() {
		vec4 tint = vec4(1.0, 1.0, 1.0, 1.0 );
		float time;
		if (worldTime >= 22000.0) {															// sunrise!
			time = min(max((23000.0 - worldTime)/1000.0, -1.0), 1.0);
				if ( time > 0 ) {												// Sky starts to colorize
					tint[0] = 0.95 + ( 0.15 * ( 1.0 - time ) );		// .95 to 1.1
					tint[1] = 0.95 - ( 0.05 * ( 1.0 - time ) );		// .95 to .9
					tint[2] = 1.1 - ( 0.1 * ( 1.0 - time ) );		// 1.1 to 1.0
				} else {														// Sun rises
					tint[0] = 1.1 - ( 0.05 * ( abs(time) ) );		// 1.1 to 1.05
					tint[1] = 0.9 + ( 0.0 * ( abs(time) ) );		// .9 to .9
					tint[2] = 1.0 + ( 0.05 * ( abs(time) ) );		// 1.0 to 1.05
				}
			} else if (worldTime >= 12000) {												// night time !
			time = min(max((13000.0 - worldTime)/1000.0, -1.0), 1.0);
				if ( time > 0 ) {												// Sunset
					tint[0] = 1.1 + ( 0.15 * ( 1.0 - time ) );		// 1.1 to 1.25
					tint[1] = 1.0 - ( 0.05 * ( 1.0 - time ) );		// 1.0 to 0.95
					tint[2] = 0.9 - ( 0.15 * ( 1.0 - time ) );		// .9 to .75
				} else {														// Night begins
					tint[0] = 1.25 - ( 0.3 * ( abs(time) ) );		// 1.25 to .95
					tint[1] = 0.95 - ( 0.0 * ( abs(time) ) );		// .95 to .95
					tint[2] = 0.75 + ( 0.35 * ( abs(time) ) );		// .65 to 1.1
				}
			} else if (worldTime >= 0) {													// Day time, from dusk til dawn!
			time = min(max((6000.0 - worldTime)/6000.0, -1.0), 1.0);
				if ( time > 0 ) {												// Morning
					tint[0] = 1.05 - ( 0.05 * ( 1.0 - time ) );		// 1.05 to 1
					tint[1] = 0.9 + ( 0.1 * ( 1.0 - time ) );		// .9 to 1
					tint[2] = 1.05 - ( 0.05 * ( 1.0 - time ) );		// 1.05 to 1
				} else {														// Afternoon
					tint[0] = 1 + ( 0.1 * ( abs(time) ) );			// 1 to 1.1
					tint[1] = 1 - ( 0.0 * ( abs(time) ) );			// 1 to 1
					tint[2] = 1 - ( 0.1 * ( abs(time) ) );			// 1 to .9
				}
			}
		return tint;
	}
#endif

void main() {
	vec4 baseColor = texture2D( sampler0, TexCoord0.st );

#ifdef AMBIENT
	baseColor *= getAmbient();
#endif

	gl_FragColor = baseColor;
}