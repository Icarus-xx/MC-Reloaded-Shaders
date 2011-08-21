//
#version 130

uniform sampler2D sampler0;
uniform sampler2D sampler1;
uniform sampler2D sampler2;
uniform sampler2D stepSampler4;

uniform float displayWidth;
uniform float displayHeight;
uniform float aspectRatio;
uniform float near;
uniform float far;
uniform int worldTime;

uniform int raining;
uniform int rainingTransition;

vec4 TexCoord0 = gl_TexCoord[0];

#ifdef NEWBLOOM_ENABLED
					
float getBrightness(vec4 color) {
	float Brightness = color[0] * 0.299f + color[1] * 0.587f + color[2] * 0.114f;
        return Brightness;
}

	vec4 getBloom2() {
		vec2 texcoord = TexCoord0.st;
		float lumBase = getBrightness( texture2D(stepSampler4, TexCoord0.st) );
//		float depth = getDepth( TexCoord0.st );


		float displayScale = (displayWidth/854.0);
		float totalSize = BLOOM_SIZE*displayScale;

		float time;
		float DAY = 1.0;												// 1.0 for Daytime, 2.0 for nightime
		float BSt=1.0;
		float BSi=1.0;
		
		if (worldTime >= 22000.0) {										// sunrise! Bloom attenuation operations in order to safeguard our poor eyes.
			time = clamp((24000.0-worldTime)/2000.0, 0.0, 1.0);
			DAY = 1.0 + time ;
			BSi = (BSi*3/4)+((BSi*1/4)*time);
			BSt *= 1.2 - ( 0.1 * (1.0-abs(time)));
		} else if (worldTime >= 13000) {								// night time ! Bloom augmentation operations to get some free candies.
			time = clamp ((14000.0-worldTime)/1000.0, 0.0, 1.0);
			DAY = 2.0 - time;
			BSi = (BSi*3/4)+((BSi*1/4)*(1.0-time));
			BSt *= 1.1 + ( 0.1 * (1.0-abs(time)));
		} else if (worldTime >= 0 ) {
			time = min(max((6000.0 - worldTime)/6000.0, -1.0), 1.0);		// day Time! Bloom further attenuation to emulate the day "gamma"
			BSi += ((BSi*1/3)*(1.0-abs(time)));
			BSt *= 1.1 - ( 0.1 * (1.0-abs(time)));
		}
		
		BSt = BSt*(1.0+(float(rainingTransition)/100.0));
		
		float pwr = DAY + 0.5;

		float lumComp = 0.0;
		float lumContrib = 0.0;
		
		float pw = ( BLOOM_SIZE*BSi )/ ( B_SAMPLES*displayWidth);
		float ph = ( BLOOM_SIZE*BSi ) / ( B_SAMPLES*displayHeight);
		
	#ifdef FPS_GAIN
			for ( int i = 1; i <= B_SAMPLES; i++) {			// This loop will sample 4 pixels per iteration as opposed to 8 for the "higher rig" loop.														

			if ( BLUR_CROSS_TYPE >= 1 ) {
				lumContrib = pow(getBrightness( texture2D(stepSampler4, texcoord.st + vec2(pw,ph))), pwr );
				lumContrib += pow(getBrightness( texture2D(stepSampler4, texcoord.st + vec2(-pw,ph))), pwr );
				lumContrib += pow(getBrightness( texture2D(stepSampler4, texcoord.st + vec2(-pw,-ph))), pwr );
				lumContrib += pow(getBrightness( texture2D(stepSampler4, texcoord.st + vec2(pw,-ph))), pwr );
			} else {
				lumContrib = pow(getBrightness( texture2D(stepSampler4, texcoord.st + vec2(0.0,ph*1.5))), pwr );
				lumContrib += pow(getBrightness( texture2D(stepSampler4, texcoord.st + vec2(pw*-1.5,0.0))), pwr );
				lumContrib += pow(getBrightness( texture2D(stepSampler4, texcoord.st + vec2(0.0,ph*-1.5))), pwr );		
				lumContrib += pow(getBrightness( texture2D(stepSampler4, texcoord.st + vec2(pw*1.5,0.0))), pwr );
			}
		
			float gauss = 1-(i / B_SAMPLES);
			gauss = pow(gauss, 3);
			lumContrib *= gauss;
		
			pw*=pow((totalSize), 1.0/B_SAMPLES);
			ph*=pow((totalSize), 1.0/B_SAMPLES);
			lumComp += lumContrib / (4.0 * B_SAMPLES);
			BSt += (( 1.2 - DAY ) / 30.0);			// Bloom is a tad too strong at night and too weak at day with the "low rig" func
													// this line modulates the bloom Strength
		}
		
	#else
		for ( int i = 1; i <= B_SAMPLES; i++) {			// This loop will sample 8 pixels per iterations around the
														// present pixel. Then with some maths it will take a global 
														// lum contribution factor. The more bright pixels are around,
														// the more bonus illumination this pixel will get

		lumContrib = pow(getBrightness( texture2D(stepSampler4, texcoord.st + vec2(0.0,ph*1.5))), pwr );
		lumContrib += pow(getBrightness( texture2D(stepSampler4, texcoord.st + vec2(pw*-1.5,0.0))), pwr );
		lumContrib += pow(getBrightness( texture2D(stepSampler4, texcoord.st + vec2(0.0,ph*-1.5))), pwr );		
		lumContrib += pow(getBrightness( texture2D(stepSampler4, texcoord.st + vec2(pw*1.5,0.0))), pwr );
		lumContrib += pow(getBrightness( texture2D(stepSampler4, texcoord.st + vec2(pw,ph))), pwr );
		lumContrib += pow(getBrightness( texture2D(stepSampler4, texcoord.st + vec2(-pw,ph))), pwr );
		lumContrib += pow(getBrightness( texture2D(stepSampler4, texcoord.st + vec2(-pw,-ph))), pwr );
		lumContrib += pow(getBrightness( texture2D(stepSampler4, texcoord.st + vec2(pw,-ph))), pwr );
		
			float gauss = 1-(i / B_SAMPLES);
			gauss = pow(gauss, 2);
			lumContrib *= gauss;
		
			pw*=pow((totalSize), 1.0/B_SAMPLES);
			ph*=pow((totalSize), 1.0/B_SAMPLES);
			lumComp += lumContrib / (8.0 * B_SAMPLES);
		}
	#endif
	
		lumComp = clamp( lumComp, 0.0, 1.0 );
		lumComp = 1.0 - pow( 1.0 - lumComp, DAY * 5);
		lumBase = lumComp;
		lumBase *= BLOOM_STRENGTH*BSt*DAY;
				
		return vec4(lumBase,lumBase,lumBase,lumBase);

	}
	
#endif

void main() {
	vec4 blurColor = texture2D( sampler0, TexCoord0.st );
	vec4 baseColor = texture2D( stepSampler4, TexCoord0.st );
	
#ifdef NEWBLOOM_ENABLED

	vec4 bloom = getBloom2();
	baseColor = (1.0 - ((1.0 - baseColor) * (1.0 - ((blurColor * bloom) + (bloom * 0.1)))));
	
#endif

	gl_FragColor = baseColor;
}