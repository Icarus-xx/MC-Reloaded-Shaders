//
#version 130

uniform sampler2D sampler0;
uniform sampler2D sampler1;
uniform sampler2D sampler2;
uniform sampler2D cleanDepth2;

uniform float aspectRatio;
uniform float near;
uniform float far;
uniform vec3 sunPosition;
uniform vec3 moonPosition;
uniform int worldTime;

vec4 TexCoord0 = gl_TexCoord[0];

#ifdef GOD_RAYS

vec2 timeFlies() {

		float time;
		float D = 1.0;
		float E = 1.0;
		
		if (worldTime >= 22000.0) {															// sunrise!
			time = min(max((23000.0 - worldTime)/1000.0, -1.0), 1.0);
				if ( time > 0 ) {												// Sky starts to colorize
					D = 1.0 - ( 0.3 * ( 1.0 - time ));		//	.7
					E = 0.01 + ( 0.04 * ( 1.0 - time ));	//  .05
				} else {														// Sun rises
					D = 0.7 - ( 0.1 * abs(time));			//	.7 -> .6
					E = 0.05 + ( 0.05 * abs(time));			//	.05 -> .1
				}
			} else if (worldTime >= 12000) {												// night time !
			time = min(max((13000.0 - worldTime)/1000.0, -1.0), 1.0);
				if ( time > 0 ) {												// Sunset
					D = 0.7 - ( 0.2 * (1.0 - time ));		// .7 -> .5	
					E = 0.1 + ( 0.1* ( 1.0 - time ));		// .1 -> .2
				} else {														// Night begins
					D = 0.5 + ( 0.5	 * abs(time));			// .5 -> 1.0					
					E = 0.2 - ( 0.19 * abs(time)); 			// .2 -> .01
				}
			} else if (worldTime >= 0) {													// Day time, from dusk til dawn!
			time = min(max((6000.0 - worldTime)/6000.0, -1.0), 1.0);
				if ( time > 0 ) {												// Morning
					D = 0.6 + ( 0.25 * ( 1.0 - time ));	//	.75 -> .85
					E = 0.1 + ( 0.1 * ( 1.0 - time ));		//	.1 -> .2
				} else {														// Afternoon
					D = 0.85 - ( 0.15 * abs(time));			//	.9 -> .7
					E = 0.2 - ( 0.1 * abs(time));			//	.2 -> .1
				}
			}
		D *= GR_DENSITY;
		E *= GR_EXPOSURE;
		return vec2(D,E);
	}


vec2 getDepthGR( vec2 coord ) {
	float depth = texture2D( cleanDepth2, coord ).x;
	float depth2 = texture2D( sampler2, coord ).x;
	   float fg = -1.0;
	if ( depth2 < 1.0 ) {
		depth = depth2;
        fg = 1.0;
	}
	depth = (2.0 * near) / (far + near - depth * (far - near));
	return vec2(depth, fg);
}

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

#ifdef GOD_RAYS
	float threshold = 0.99;
	bool foreground = false;
	vec2 depthGR = getDepthGR(TexCoord0.st);
	vec3 celestPosition = sunPosition;
/*	if (worldTime > 13300 && worldTime < 22000) {			// kept for future tweaks
		celestPosition = moonPosition;
	}*/

    if (celestPosition.z < 0 && depthGR.x < threshold && depthGR.y < 0.0)				//(worldTime < 14000 || worldTime > 22000) && 
	{
		vec2 lightPos = celestPosition.xy / -celestPosition.z;
		lightPos.y *= aspectRatio; 
		lightPos = (lightPos + 1.0)/2.0;
		vec2 texCoord = TexCoord0.st;
		vec2 delta = (texCoord - lightPos) * timeFlies().s / float(GR_SAMPLES);
		float decay = -celestPosition.z / 100.0;
		
		vec3 color = vec3(0.0);
		
		for (int i = 0; i < GR_SAMPLES; i++)
		{
			texCoord -= delta;
			if (texCoord.x < 0.0 || texCoord.x > 1.0) {
				if (texCoord.y < 0.0 || texCoord.y > 1.0) {
					break;
				}
			}
			vec3 sample = vec3(0.0);
			if (getDepthGR(texCoord).x > threshold) sample = texture2D(sampler0, texCoord).rgb;
			sample *= decay;
			if (distance(texCoord, lightPos) > 0.05) sample *= 0.2;
			color += sample;
			decay *= GR_DECAY;
		}
		baseColor = mix(baseColor, vec4(1.0) * getAmbient(), timeFlies().t * vec4(color, 1.0));
	}
#endif
    gl_FragColor = baseColor;

}