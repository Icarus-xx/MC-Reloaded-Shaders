//
#version 130 // This will always get moved to the top of the code in pre-processing.

/* Bump mapping shader by daxnitro.  
   This shader implements parallax occlusion and specular mapping.  It requires terrain_nh.png and terrain_s.png to be included in the current texture pack. */

// To disable a particular feature of this shader, add two forward slashes to the beginning its line:

//#define ENABLE_PARALLAX_OCCLUSION
//#define ENABLE_SPECULAR_MAPPING
//#define ENABLE_FOG

#define INTESTINE
#define SOULSAND
#define PORTAL

//#define ENABLE_ALT_SPEC				// higly volatile material - pure alpha test - credits to SnapImaX  from Youtube - not finished yet - you still haven't understood? =) Oh, and better to de-activate the regular spec mapping beforehand.
//#define ENABLE_PARALLAX_SELFSHADOW

   
#ifdef ENABLE_PARALLAX_OCCLUSION
const float HEIGHT_MULT = 1.2;															// Height multiplier for the bump
const float PARALLAX_OCCLUSION_SHADOW_MULT = .75;					// Multiplier for the shadowing effect, in the vaities of the bump texture. Note this won't look good on relatively "flat" bump maps, with low alpha values ( alpha value define the height )
																											// 0 for no effect, 1.0 for full effect, beyond 1.0 is achievable

#endif
   
#ifdef _ENABLE_GL_TEXTURE_2D

uniform sampler2D sampler0;
centroid in vec4 texCoord;

const float SQUIRM_DISTANCE = 30.0;

#ifdef _ENABLE_BUMP_MAPPING

uniform sampler2D sampler1;
uniform sampler2D sampler2;

vec3 intervalMult;

// !!!!!!!! THE TYPICAL USER DOESN'T NEED TO LOOK AT ANYTHING BELOW HERE !!!!!!!!

in vec4 specMultiplier;
in float useCelestialSpecularMapping;
in vec3 lightVector;
in vec3 viewVector;

const float MAX_DISTANCE = 100.0;
const int MAX_POINTS = 50;

#ifdef ENABLE_PARALLAX_OCCLUSION
	#ifdef ENABLE_PARALLAX_SELFSHADOW
		const int SELFSHADOW_LOOP = 50;
		const float SELFSHADOW_ROUGHNESS = 2.0;
	#endif
#endif

#endif // ENABLE_GL_BUMP_MAPPING
#endif // ENABLE_GL_TEXTURE_2D

uniform float near;
uniform float far;
uniform int worldTime;
uniform int renderType;
uniform int fogMode;

in float FogFragCoord;
in float distance;
in float texID;
in float blockID;

struct lightSource {
	int itemId;
	float magnitude;
	vec4 specular;
};

uniform lightSource heldLight;

const int GL_LINEAR = 9729;
const int GL_EXP = 2048;

const float PI = 3.1415926535897932384626433832795;
const float PI2 = 6.283185307179586476925286766559;

in vec4 vertColor;

vec3 getAmbient() {

		vec3 tint = vec3(1.0, 1.0, 1.0);
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

void main() {

float shadow_term=1.0;

#ifdef _ENABLE_GL_TEXTURE_2D

	vec3 coord = vec3(texCoord.st, 1.0);
	vec4 vC = vec4(0.0, 0.0, 0.0, 0.0);
	vec4 baseColor;
	
	#ifdef INTESTINE
		if (round(texID) == 103.0 && distance <= SQUIRM_DISTANCE) {
			float t = (24000.0 - ( 2.0 * abs(12000.0 - float(worldTime)))) / 250.0;
			vec3 offset, base;
			coord = modf(16.0*coord, base);
			offset = vec3(cos(PI2*coord.s)*cos(PI2*(coord.t + 2.0*t))*cos(PI2*t)/40.0,
					-cos(PI2*(coord.s + t))*sin(2.0*PI2*coord.t)/40.0,0);

			coord = mod(coord + offset, vec3(1.0)) + base;
			coord = coord/16;
		}
	#endif

	#ifdef SOULSAND
		if (round(texID) == 104.0 && distance <= SQUIRM_DISTANCE) {
			float t = (24000.0 - ( 2.0 * abs(12000.0 - float(worldTime)))) / 1000.0;
			vec3 offset, base;
			coord = modf(16.0*coord, base);
			offset = vec3(cos(PI2*coord.s)*cos(PI2*(coord.t + 2.0*t))*cos(PI2*t)/24.0,
					-cos(PI2*(coord.s + t))*sin(2.0*PI2*coord.t)/32.0,0);

			coord = mod(coord + offset, vec3(1.0)) + base;
			coord = coord/16;
		}
	#endif  
	
	#ifdef PORTAL
		if (round(texID) == 14.0 && distance <= SQUIRM_DISTANCE) {
			float t = (24000.0 - ( 2.0 * abs(12000.0 - float(worldTime)))) / 200.0;
				vec3 offset, base;
				coord = modf(16.0*coord, base);
				offset = vec3(cos(PI2*coord.s)*cos(PI2*(coord.t + 2.0*t))*cos(PI2*t)/6.0,
						-cos(PI2*(coord.s + t))*sin(2.0*PI2*coord.t)/18.0,0);

				coord = mod(coord + offset, vec3(1.0)) + base;
				coord = coord/16;
			
			vC = texture2D(sampler0, coord.st);
			float lum = vC[0] * 0.299 + vC[1] * 0.587 + vC[2] * 0.114;
			lum += clamp(sin((3.0*lum + 5.0*t))+0.5, 0.5, 3.0);
			vC = vec4(vC.rgb*lum, -0.2);
		}
	#endif  

	#ifdef _ENABLE_BUMP_MAPPING
	
		if (distance <= MAX_DISTANCE){ // && viewVector.z < 0.0) {
		
			int tSize = 0;
			tSize = textureSize(sampler1,0).x;
			float multTest = 1.0;
			if (tSize > 16 ) {		
				
				if (tSize >= 4096) {
					intervalMult = vec3(0.00008828125, 0.00008828125, 0.03);
				} else if (tSize >= 2048) {
					intervalMult = vec3(0.00048828125, 0.00048828125, 0.145);
				} else if (tSize >= 1024) {
					intervalMult = vec3(0.0009, 0.0009, 0.25);
				} else if (tSize >= 512) {
					intervalMult = vec3(0.0019, 0.0019, 0.5);
				} else if (tSize >= 256) {
					intervalMult = vec3(0.0039, 0.0039, 4.5);
				} else {
					intervalMult = vec3(0.00008828125, 0.00008828125, 0.03);
				}  
				
				#ifdef ENABLE_PARALLAX_OCCLUSION
					intervalMult[2] /= HEIGHT_MULT;
					if (texture2D(sampler1, coord.st).a < 1.0) {	
						vec2 minCoord = vec2(texCoord.s - mod(texCoord.s, 0.0625), texCoord.t - mod(texCoord.t, 0.0625));
						vec2 maxCoord = vec2(minCoord.s + 0.0625, minCoord.t + 0.0625);
						
						vec3 vt_delta = viewVector * intervalMult; 
						
						for (int loopCount = 0; texture2D(sampler1, coord.st).a < coord.z && loopCount < MAX_POINTS; ++loopCount) {
							coord += vt_delta;
							//boundary check and wrap correction
							if (coord.s < minCoord.s) {	coord.s += 0.0625;	} else if (coord.s >= maxCoord.s) {	coord.s -= 0.0625;	}
							if (coord.t < minCoord.t) {	coord.t += 0.0625;	} else if (coord.t >= maxCoord.t) {	coord.t -= 0.0625;	}
						}
					
				    #ifdef ENABLE_PARALLAX_SELFSHADOW
					//light trace step vector
					vec3 lt_delta = -lightVector * intervalMult * SELFSHADOW_ROUGHNESS;
//					//Initialize by doing 1 step (otherwise were still below depth from prior trace)
					vec3 lt_p= coord+lt_delta;
					float depth=0.0;
					for (int ltloop = 0; shadow_term>0.0 && lt_p.z>0.0 && lt_p.z<1.0 && ltloop < SELFSHADOW_LOOP; ++ltloop) {
						lt_p += lt_delta;
						//boundary check and wrap correction
						if (lt_p.s < minCoord.s) {	lt_p.s += 0.0625;	} else if (lt_p.s >= maxCoord.s) {	lt_p.s -= 0.0625;	}
						if (lt_p.t < minCoord.t) {	lt_p.t += 0.0625;	} else if (lt_p.t >= maxCoord.t) {	lt_p.t -= 0.0625;	}
						depth=texture2D(sampler1, lt_p.st).a;
						shadow_term*=smoothstep(depth*0.99,depth,lt_p.z);
					}
					#endif
				}
				multTest = clamp((pow(( texture2D(sampler1, coord.st).a + 1.2) * 0.6, 3) / ( 1.0 + PARALLAX_OCCLUSION_SHADOW_MULT)), 0.02, 1.0);
				#endif
			}

			vec4 matDiffuseColor =  texture2D(sampler0, coord.st); 
		#ifdef ENABLE_PARALLAX_SELFSHADOW
			baseColor = matDiffuseColor * vertColor;
		#else
			baseColor = matDiffuseColor * vertColor * multTest;
		#endif
			
		#ifdef ENABLE_SPECULAR_MAPPING
			tSize = 0;
			tSize = textureSize(sampler2,0).x;

			if (tSize > 16) {		
				vec4 specular = texture2D(sampler2, coord.st);
					vec3 bump = normalize(texture2D(sampler1, coord.st).xyz * 2.0 - 1.0);	
					// vec3 V = viewVector;
				if (specular.rgb != vec3(0.0,0.0,0.0)) {

					float shininess = 20.0 * texture2D(sampler2, coord.st).a;
					if (useCelestialSpecularMapping > 0.5) {
						float s = pow(max(dot(reflect(-lightVector, bump), viewVector), 0.0), shininess);
						baseColor += max(specular * s * (shininess/2.0)* specMultiplier, 0.0);
					}
					float intensity = 1.0 - min(distance / heldLight.magnitude, 1.0);
					float s = pow(max(dot(reflect(-viewVector, bump), viewVector), 0.0), shininess);	
					baseColor += max(intensity * specular * (shininess/5.0) * s * heldLight.specular, 0.0);
					baseColor.a = texture2D(sampler0, coord.st).a;
				}
				 // baseColor = vec4(viewVector, 1.0);
				 // baseColor = vec4( vec3(max(dot(reflect(-viewVector, bump), viewVector), 0.0)), 1.0);
			}
			#endif

	
			#ifdef ENABLE_PARALLAX_SELFSHADOW
			tSize = 0;
			tSize = textureSize(sampler2,0).x;
			if (tSize > 16) {				
				
				//Material attributes
				vec3 normalVector = normalize(texture2D(sampler1, coord.st).xyz * 2.0 - 1.0);
				float spec=0.0;
						
				//Sun light pass
				vec4 SunColorDiffuse =  matDiffuseColor*0.55;
					
				//Dim original ambient term
				baseColor.rgb *= getAmbient() * PARALLAX_OCCLUSION_SHADOW_MULT *0.5; 
					
				if(shadow_term>0.0){
					//Sunlight diffuse term
					baseColor += SunColorDiffuse * clamp( dot(-lightVector, normalVector), 0.0, 1.0) * shadow_term;
				// baseColor += SunColorDiffuse * clamp( dot(-lightVector, normalVector), 0.0, 1.0); 							// light result computation is amb + diff 

				}
				/*
				//Held light pass
				vec4 TorchColorDiffuse=vec4(1.0,0.62,0.0,1.0);
					
				//Use quadratic falloff...
				float falloff= (1.0 - min(1.3*distance / heldLight.magnitude, 1.0));		
				falloff *=falloff;		
					
				//Torch diffuse term
				baseColor += TorchColorDiffuse * ( matDiffuseColor * 0.8) * clamp( falloff * dot(-viewVector, normalVector) , 0.0, 1.0);
				
				//Restore transparency from material diffuse color
				baseColor.a=matDiffuseColor.a;
				// */
			}
			#endif

			#ifdef ENABLE_ALT_SPEC
			tSize = 0;
			tSize = textureSize(sampler2,0).x;
			if (tSize > 16) {				
				
				vec4 matSpecularColor = texture2D(sampler2, coord.st);
				
				if ( matSpecularColor.rgb != vec3(0.0,0.0,0.0)) {
					vec3 normalVector = texture2D(sampler1, coord.st).xyz * 2.0 - 1.0;
					float shininess = 30.0 * matSpecularColor.a;
					float spec=0.0;
					
					
					//Sun light pass
					vec4 SunColorSpecular = vec4(1.0,1.0,1.0,1.0);
						
					if(shadow_term>0.0){
						//Sunlight specular term
						spec = pow(max(dot(reflect(-lightVector, normalVector), viewVector), 0.0), shininess);
						baseColor +=  max(SunColorSpecular * matSpecularColor * spec * specMultiplier * shadow_term, 0.0);
					}
					
					//Held light pass
					vec4 TorchColorSpecular=vec4(0.8,0.21,0.0,1.0);
						
					//Use quadratic falloff...
					float falloff= (1.0 - min(1.0*distance / heldLight.magnitude, 1.0));		
					falloff *=falloff;
					
					//Torch specular term
					spec = pow(max(dot(reflect(-viewVector, normalVector), viewVector), 0.0), shininess);
					baseColor += max(TorchColorSpecular * matSpecularColor * falloff * spec, 0.0);
					
					//Restore transparency from material diffuse color
					baseColor.a=matDiffuseColor.a;
				}
			}
			#endif

		} else {
				 baseColor = texture2D(sampler0, coord.st) * vertColor;
		}
	#else
		baseColor = texture2D(sampler0, coord.st) * vertColor;
	#endif  // _ENABLE_BUMP_MAPPING
	gl_FragColor = baseColor + vC;
#else  // ENABLE_GL_TEXTURE_2D
	gl_FragColor = vertColor;
#endif // ENABLE_GL_TEXTURE_2D
  
#ifdef ENABLE_FOG
	if (fogMode == GL_EXP) {
		gl_FragColor.rgb = mix(gl_FragColor.rgb, gl_Fog.color.rgb, 1.0 - clamp(exp(-gl_Fog.density * FogFragCoord ), 0.0, 1.0));
	} else if (fogMode == GL_LINEAR) {
		gl_FragColor.rgb = mix(gl_FragColor.rgb, gl_Fog.color.rgb, clamp((FogFragCoord - gl_Fog.start) * gl_Fog.scale, 0.0, 1.0));
	}
#endif
}
