//
#version 130


uniform sampler2D sampler0;
uniform sampler2D sampler1;
uniform sampler2D sampler2;
uniform sampler2D stepSampler0;
uniform sampler2D cleanDepth;

uniform float displayWidth;
uniform float displayHeight;
uniform float aspectRatio;
uniform float near;
uniform float far;

vec4 TexCoord0 = gl_TexCoord[0];

float getDepth( vec2 coord ) {

    if ( coord.x < 0.0 ) coord.x = -coord.x;                // should not sample outside the screen as there are no infos
    if ( coord.x > 1.0 ) coord.x = (1.0-coord.x)+1.0;        // Telling the shader to go back on the tex
    if ( coord.y < 0.0 ) coord.y = -coord.y/2.0;
    if ( coord.y > 1.0 ) coord.y = (1.0-coord.y)+1.0;

    float depth = texture2D( cleanDepth, coord ).x;

    depth = (2.0 * near) / (far + near - depth * (far - near));
    return depth;

}

#ifdef SSAO_ENABLED // Stuff only SSAO uses

vec4 getSSAO() {

   float depth = getDepth( TexCoord0.xy );
   float d;

    if (texture2D( sampler2, TexCoord0.xy ).x < 1.0) { return vec4(1.0, 1.0, 1.0, 1.0); }

   float depthN = depth;
   float Rp = clamp(DISTANCE_DECAY_BEGINS, 0.0, far) / far;
   float Rp2 = clamp(DISTANCE_DECAY_ENDS, 0.0, far) / far;
   if ( Rp > Rp2 ) { Rp = Rp2*0.99; }
   float depthPush = ( depthN - Rp ) / ( Rp2 - Rp );

    float ao = 0.0;

   if ( depthN*depthPush < 1.0 ) {                 // If max_distance is not reached, then go ahead

    float aoCap = 1.0;
    float aoMultiplier=512.0;
    float depthTolerance = 0.000015;

    float displayScale = (displayWidth/854);    // scale ratio for you guys playing in fullscreen, 854 is the native width

    float totalSize = EFFECT_SIZE*displayScale;     // size of the ssao "envelope", modified by your resolution ( higher resolution tend to "compress" the effect )
                                                    // this is actually used to do some maths below
                                                    // in order to calculate the offset between each iteration.


    float pw = (EFFECT_SIZE) / ( SAMPLES*displayWidth*depth*20);       // retake on the code to allow depth to have a saying and not get
    float ph = (EFFECT_SIZE) / ( SAMPLES*displayHeight*depth*20);        // the exact same envelope on a near object and a far object.


#ifdef FPS_GAIN
//    for( int i = 1; i <= (floor(SAMPLES*(1-(depthN*depthPush))+1)); i++ ){    // Temp code; waiting to be used for some FPS optimization - not working great yet
    for( int i = 1; i <= SAMPLES+1; i++ ) {                                    // retake on the original code to allow more "blur"
                                                                            // and more "depth" in the occlusion effect

           d=getDepth( vec2(TexCoord0.x+pw,TexCoord0.y+ph));
           ao+=min(aoCap,max(0.0,depth-d-depthTolerance) * aoMultiplier);

           d=getDepth( vec2(TexCoord0.x-pw,TexCoord0.y+ph));
           ao+=min(aoCap,max(0.0,depth-d-depthTolerance) * aoMultiplier);

           d=getDepth( vec2(TexCoord0.x-pw,TexCoord0.y-ph));
           ao+=min(aoCap,max(0.0,depth-d-depthTolerance) * aoMultiplier);

           d=getDepth( vec2(TexCoord0.x+pw,TexCoord0.y-ph));
           ao+=min(aoCap,max(0.0,depth-d-depthTolerance) * aoMultiplier);

           pw*=pow((totalSize), 1.0/SAMPLES);
           ph*=pow((totalSize), 1.0/SAMPLES);
           aoMultiplier *= 1 - ( (i-1) / SAMPLES);
       }
       ao/=(SAMPLES*3.0);

#else
//    for( int i = 1; i <= (floor(SAMPLES*(1-(depthN*depthPush))+1)); i++ ){    // Temp code; waiting to be used for some FPS optimization - not working great yet
    for( int i = 1; i <= SAMPLES+1; i++ ) {                                    // retake on the original code to allow more "blur"
                                                                            // and more "depth" in the occlusion effect

           d=getDepth( vec2(TexCoord0.x+(pw*1.5),TexCoord0.y));
           ao+=min(aoCap,max(0.0,depth-d-depthTolerance) * aoMultiplier);

           d=getDepth( vec2(TexCoord0.x+pw,TexCoord0.y+ph));
           ao+=min(aoCap,max(0.0,depth-d-depthTolerance) * aoMultiplier);

           d=getDepth( vec2(TexCoord0.x,TexCoord0.y+(ph*1.5)));
           ao+=min(aoCap,max(0.0,depth-d-depthTolerance) * aoMultiplier);

           d=getDepth( vec2(TexCoord0.x-pw,TexCoord0.y+ph));
           ao+=min(aoCap,max(0.0,depth-d-depthTolerance) * aoMultiplier);

           d=getDepth( vec2(TexCoord0.x-(pw*1.5),TexCoord0.y));
           ao+=min(aoCap,max(0.0,depth-d-depthTolerance) * aoMultiplier);

           d=getDepth( vec2(TexCoord0.x-pw,TexCoord0.y-ph));
           ao+=min(aoCap,max(0.0,depth-d-depthTolerance) * aoMultiplier);

           d=getDepth( vec2(TexCoord0.x,TexCoord0.y-(ph*1.5)));
           ao+=min(aoCap,max(0.0,depth-d-depthTolerance) * aoMultiplier);

           d=getDepth( vec2(TexCoord0.x+pw,TexCoord0.y-ph));
           ao+=min(aoCap,max(0.0,depth-d-depthTolerance) * aoMultiplier);

           pw*=pow((totalSize), 1.0/SAMPLES);
           ph*=pow((totalSize), 1.0/SAMPLES);
           aoMultiplier *= 1 - ( (i-1) / SAMPLES);
       }
       ao/=(SAMPLES*5.0);

#endif

       ao=clamp(SSAO_MULT*ao,0.0, 1.0);    // multiplicator
       ao=clamp((1-ao)+(depthN*depthPush), 0.0, 1.0);

   } else {                    // If max_distance is reached, then ignore the long computation, and giev moar fps
       ao=1.0;
   }

   return vec4(ao,ao,ao,1.0);
}
#endif

void main() {
    vec4 baseColor = texture2D( sampler0, TexCoord0.st );

#ifdef SSAO_ENABLED
     baseColor *= getSSAO();
#endif
    gl_FragColor = baseColor;
}