//
#version 130                    // This will always get moved to the top of the code in pre-processing.

/* Bump mapping shader by daxnitro.
   This shader implements parallax occlusion and specular mapping.  It requires terrain_nh.png and terrain_s.png to be included in the current texture pack. */

// Comment => disable effect
// Uncomment => enable effect
#define ENABLE_WORLD_CURVATURE
//#define ENABLE_ACID_EFFECT     // Need to enable ENABLE_WORLD_CURVATURE to make it work
//#define ENABLE_INCEPTION     // Need to enable ENABLE_WORLD_CURVATURE to make it work

#define WAVING_WHEAT
#define WAVING_PLANTS
#define WAVING_LEAVES
#define SHORT_GRASS
#define TALL_GRASS
#define WAVING_PORTAL

#define WEATHER_MAYHEM
//#define BFINDER

#define SHADOW_FIX

//WAVE SETTINGS
#define WAVING_WATER
#define WAVING_LAVA
const float WAVE_PITCH = 10.0;  //Decrease to grow wave effect

//BFINDER SETTINGS
#define BFINDER_RED 8.0
#define BFINDER_GREEN 9.0
#define BFINDER_BLUE 18.0

const float BEND_AMOUNT = 0.003;

// !!!!!!!! THE TYPICAL USER DOESN'T NEED TO LOOK AT ANYTHING BELOW HERE !!!!!!!!

attribute vec4 mc_Entity;
uniform sampler2D sampler0;
uniform float posX;
uniform float posY;
uniform float posZ;

out vec4 vertColor;
out float FogFragCoord;
out float distance;

#ifdef _ENABLE_GL_TEXTURE_2D
centroid out vec4 texCoord;
#ifdef _ENABLE_BUMP_MAPPING

out vec3 lightVector;
out vec4 specMultiplier;
out vec3 viewVector;
out vec3 viewVectorSpec;
out vec3 normal;
uniform vec3 sunPosition;
uniform vec3 moonPosition;

#endif
#endif

#ifdef ENABLE_WORLD_CURVATURE
const float WORLD_RADIUS = 2000.0;  //2500.0;
const float WORLD_RADIUS_SQUARED = 4000000.0;   //6250000.0;
#endif

#ifdef WEATHER_MAYHEM
uniform int biomeType;
uniform int raining;
uniform int thundering;
uniform int rainingTransition;

float rT = float (rainingTransition) / 100.0;
float wR = float (raining);
float wT = float (thundering);
#else
float wR = 0.0;
float wT = 0.0;
float rT = 0.0;
#endif

int
getTextureID (vec2 coord)
{
    int i = int (floor (16 * coord.s));
    int j = int (floor (16 * coord.t));
    return i + 16 * j;
}

uniform int worldTime;
uniform int renderType;

out float texID;
out float useCelestialSpecularMapping;

out float blockID;

const float PI = 3.1415926535897932384626433832795;
const float PI2 = 6.283185307179586476925286766559;

float t = 24000.0 - (2.0 * abs (12000.0 - float (worldTime)));

void
main ()
{

    vec4 position = gl_Vertex;
    int tex = getTextureID (gl_MultiTexCoord0.st);


// Reserved for later usage, should stop most "weather mayhem" from occuring in snow lands
#ifdef WEATHER_MAYHEM
    if (biomeType >= 7 && biomeType < 8)
    {                           // || biomeType == 10 || biomeType ==11 ) {
        rT = 0.0;
        wR = 0.0;
        wT = 0.0;
    }
#endif


#ifdef WAVING_WHEAT
    if (87 < tex && tex < 96 && renderType != 0)
    {
        t /= 200.0 - ((float (wR) * (25.0 + (float (wT) * 75.0))));
        vec2 pos = position.xz / 16.0;
        if (floor ((16.0 * gl_MultiTexCoord0.t) + 0.5) <=
            floor (16.0 * gl_MultiTexCoord0.t))
        {
            position.x +=
                ((sin (PI2 * (2.0 * pos.x + pos.y - 3.0 * t)) + 0.6) * (1.0 +
                                                                        ((1.0
                                                                          +
                                                                          wT *
                                                                          4) *
                                                                         rT)))
                / 20.0;
        }
    }
#endif

#ifdef WAVING_WATER
// Using Water ID yields very strange result, so I'd rather exclude pistons ( 29, 33, 34 ) as well as all "living entities ( -1 ).

    if (((tex >= 204 && tex <= 207) || (tex >= 221 && tex <= 223)
         || tex == 125) && (mc_Entity.x != 34.0 && mc_Entity.x != 29.0
                            && mc_Entity.x != 33.0 && mc_Entity.x != -1
                            && renderType == 0))
    {
        t /= 400.0 - (wR * (100.0 + (wT * 200.0)));
        vec2 pos = position.xz / 16.0;
        position.y +=
            (cos ((PI * 2.0) * (2.0 * (pos.x + pos.y) + PI * t)) + 0.2 -
             2.6 * rT) / WAVE_PITCH * (1.0 + ((1.0 + wT * 4.0) * rT));
        position.y +=
            cos (2.0 * PI * (pos.y + pos.x + rT) +
                 2.0 * PI * t) * rT * WAVE_PITCH / 50.0;
    }
#endif

#ifdef WAVING_LAVA
    if (((tex >= 236 && tex <= 239) || (tex >= 253 && tex <= 255))
        && mc_Entity.x != -1.0)
    {
        t /= 700.0;
        vec2 pos = position.xz / 16.0;
        position.y +=
            (cos ((PI * 2.0) * (2.0 * (pos.x + pos.y) + PI * t)) +
             0.2) / WAVE_PITCH;
    }
#endif

#ifdef WAVING_LEAVES
    if ((tex == 52 || tex == 53 || tex == 132 || tex == 133)
        && renderType == 1)
    {
        t /= 800.0 - ((wR * (250.0 + (wT * 420.0))));
//        t = (24000.0 - ( 2.0 * abs(12000.0 - float(worldTime)))) / 800.0;
//        if (wR == 1) t = (24000.0 - ( 2.0 * abs(12000.0 - float(worldTime)))) / (800.0 - 200*wRTransition);
        vec2 pos = (position.xz / 16.0);
        if (floor (8.0 * gl_MultiTexCoord0.t + 0.5) <=
            floor (16.32 * gl_MultiTexCoord0.t))
        {
/*            position.x -= (sin(PI2*(2.0*pos.x + pos.y - 3.0*t))*float(wRTransition+200)/200.0 + 0.6) / 24.0;
            position.y -= (sin(PI2*(3.0*pos.x + pos.y - 4.0*t))*float(wRTransition+200)/200.0 + 1.2) / 32.0;
            position.z -= (sin(PI2*(1.0*pos.x + pos.y - 1.5*t))*float(wRTransition+200)/200.0 + 0.3) / 8.0; */

            position.x -=
                ((sin (PI2 * (2.0 * pos.x + pos.y - 3.0 * t)) + 0.6) * (1.0 + ((3.0 + (wT * 6.0)) * rT))) / 24.0;
            position.y -=
                ((sin (PI2 * (3.0 * pos.x + pos.y - 4.0 * t)) + 1.2) * (1.0 + ((1.0 + wT) * rT))) / 32.0;
            position.z -=
                (sin (PI2 * (1.0 * pos.x + pos.y - 1.5 * t)) + 0.3) / 8.0;
        }
    }
#endif

#ifdef TALL_GRASS
    if ((tex == 127 || tex == 143 || tex == 111) && renderType == 1)
    {
        t /= 400.0 - (wR * (100.0 + (wT * 200.0)));
        vec2 pos = position.xz / 16.0;
        if (round (16.0 * gl_MultiTexCoord0.t) <=
            floor (16.0 * gl_MultiTexCoord0.t))
        {
            position.x -=
                ((sin (PI2 * (2.0 * pos.x + pos.y - 3.0 * t)) + 0.6) * (1.0 +
                                                                        ((1.0
                                                                          +
                                                                          wT)
                                                                         *
                                                                         rT)))
                / 12.0;
        }
    }
#endif

#ifdef SHORT_GRASS
    if (((87 < tex && tex < 93) || (186 < tex && tex < 192))
        && renderType == 1)
    {
        t /= 200.0 - (wR * (50.0 + (wT * 100.0)));
        vec2 pos = position.xz / 16.0;
        if (round (16.0 * gl_MultiTexCoord0.t) <=
            floor (16.0 * gl_MultiTexCoord0.t))
        {
            position.x -=
                ((sin (PI2 * (2.0 * pos.x + pos.y - 3.0 * t)) + 0.6) * (1.0 +
                                                                        ((1.0
                                                                          +
                                                                          wT)
                                                                         *
                                                                         rT)))
                / 32.0;
        }
    }
#endif

#ifdef WAVING_PLANTS
    if ((tex == 12 || tex == 13 || tex == 15 || tex == 28 || tex == 29
         || tex == 39 || tex == 56 || tex == 63 || tex == 79 || tex == 126
         || tex == 157 || tex == 158 || tex == 173 || tex == 174)
        && renderType == 1)
    {
        t /= 500.0 - (wR * (150.0 + (wT * 250.0)));
        vec2 pos = position.xz / 16.0;
        if (floor ((16.0 * gl_MultiTexCoord0.t) + 0.5) <=
            floor (16.0 * gl_MultiTexCoord0.t))
        {
            position.x -=
                ((sin (PI2 * (3.0 * pos.x + pos.y - 3.0 * t)) + 0.6) * (1.0 +
                                                                        ((1.0
                                                                          +
                                                                          wT)
                                                                         *
                                                                         rT)))
                / 8.0;
        }
    }
#endif

#ifdef WAVING_CANES
    if ((tex == 73) && renderType == 1)
    {
        float t = t / (500.0 - (float (wR) * 150.0) -(float (wT) * 250.0));
        vec2 pos = position.xz / 16.0;
        if (round (16.0 * gl_MultiTexCoord0.t) <=
            floor (16.0 * gl_MultiTexCoord0.t))
        {
            position.x -=
                ((sin (PI2 * (2.0 * pos.x + pos.y - 3.0 * t)) + 0.6) * (1.0 +
                                                                        ((3.0
                                                                          +
                                                                          wT *
                                                                          4.0)
                                                                         *
                                                                         rT)))
                / 24.0;
            position.z -=
                (sin (PI2 * (1.0 * pos.x + pos.y - 1.5 * t)) + 0.3) / 8.0;
        }
    }
#endif

#ifdef WAVING_PORTAL
    if (mc_Entity.x == 90)
    {
//if (tex == 14) {
        t /= 300.0;
        vec3 pos = (position.xyz / 4.0);
        if ((gl_Normal.x >= 1.0) || (gl_Normal.x < 0.0))
        {
            position.x -=
                (sin (PI2 * (2.0 * pos.x + pos.y - 4.0 * t)) + 0.1) / 12.0;
        }
        else if ((gl_Normal.z >= 1.0) || (gl_Normal.z < 0.0))
        {
            position.z -=
                (sin (PI2 * (2.0 * pos.z + pos.y - 4.0 * t)) + 0.1) / 12.0;
        }
        position.y -=
            (sin (PI2 * (3.0 * (pos.x + pos.z) + pos.y - 4.0 * t)) +
             1.2) / 32.0;

    }
#endif

#ifdef ENABLE_WORLD_CURVATURE
    position = gl_ModelViewMatrix * position;
    if (gl_Color.a != 0.8)
    {
        // Not a cloud.
        float flatDistanceSquared =
            position.x * position.x + position.z * position.z;
#ifdef ENABLE_INCEPTION
        mat4 unrotate = gl_ModelViewMatrix;
        unrotate[3] = vec4 (0.0, 0.0, 0.0, 1.0);
        mat4 rotate = gl_ModelViewMatrixInverse;
        rotate[3] = vec4 (0.0, 0.0, 0.0, 1.0);
        position = position * unrotate;
        position.y += flatDistanceSquared * BEND_AMOUNT;
        position = position * rotate;
#endif
#ifdef ENABLE_ACID_EFFECT
        position.y +=
            5 * sin (flatDistanceSquared * sin (float (worldTime) / 143.0) /
                     1000);
        float y = position.y;
        float x = position.x;
        float om =
            sin (flatDistanceSquared * sin (float (worldTime) / 256.0) /
                 5000) * sin (float (worldTime) / 200.0);
        position.y = x * sin (om) + y * cos (om);
        position.x = x * cos (om) - y * sin (om);
#else
        position.y -=
            WORLD_RADIUS -
            sqrt (max (1.0 - flatDistanceSquared / WORLD_RADIUS_SQUARED, 0.0))
            * WORLD_RADIUS;
#endif

#ifdef _ENABLE_BUMP_MAPPING

        distance = sqrt (flatDistanceSquared + position.y * position.y);

#endif
    }
    gl_Position = gl_ProjectionMatrix * position;

#else

    position = gl_ModelViewMatrix * position;
    distance =
        sqrt (position.x * position.x + position.y * position.y +
              position.z * position.z);
    gl_Position = gl_ProjectionMatrix * position;

#endif // ENABLE_WORLD_CURVATURE

    vertColor = gl_Color;

#ifdef SHADOW_FIX
    int squareTex = 0;
    if (textureSize (sampler0, 0).x == textureSize (sampler0, 0).y)
        squareTex = 1;
    if ((mc_Entity.x == -1 && gl_Color.a == 1.0)
        && !(gl_Color.r != gl_Color.g || gl_Color.g != gl_Color.b)
        && squareTex == 0)
    {                           // works ok for entities that calls a non square texture - quick n dirty solution
        vec3 normalFix = gl_NormalMatrix * gl_Normal;
        vertColor *= gl_LightModel.ambient;
        for (int i = 0; i < 2; ++i)
        {
            vec3 posFix = (gl_LightSource[i].position).xyz;
            gl_LightSourceParameters ls = gl_LightSource[i];
            vertColor += ls.diffuse * max (dot (normalFix, posFix), 0.0) * gl_Color;    //gl_FrontMaterial.diffuse;
        }
    }
    else if (((mc_Entity.x == -1 && gl_Color.a == 1.0) && squareTex == 1)
             && !(tex >= 106 && tex <= 110))
    {                           // I hate pistons. Why won't they just work ? Looks like there is too much to ithem for now
//            vec3 normalFix = gl_NormalMatrix * gl_Normal;
        vec3 normalFix = gl_Normal * gl_NormalMatrix;   // for whatever reason, multiplying normals by the inverse matrix works better for pistons. Yields un-realistic results for every other dropped blocks though. Although better for particles.
        vertColor *= gl_LightModel.ambient;
        for (int i = 0; i < 2; ++i)
        {
            vec3 posFix = (gl_LightSource[i].position).xyz;
            gl_LightSourceParameters ls = gl_LightSource[i];
            vertColor += ls.diffuse * max (dot (normalFix, posFix), 0.0) * gl_Color;    //gl_FrontMaterial.diffuse;
        }
    }

#endif

#ifdef _ENABLE_GL_TEXTURE_2D
    texCoord = gl_MultiTexCoord0;
#ifdef _ENABLE_BUMP_MAPPING

    normal = gl_Normal;         //normalize(gl_NormalMatrix * gl_Normal);
    vec3 tangent;
    vec3 binormal;
    if (biomeType == 12)
    {
        useCelestialSpecularMapping = 0.0;
    }
    else
    {
        useCelestialSpecularMapping = 1.0;
    }

    if (gl_Normal.x > 0.5)
    {
        //  1.0,  0.0,  0.0
        tangent = vec3 (0.0, 0.0, -1.0);
        binormal = vec3 (0.0, -1.0, 0.0);
    }
    else if (gl_Normal.x < -0.5)
    {
        // -1.0,  0.0,  0.0
        tangent = vec3 (0.0, 0.0, 1.0);
        binormal = vec3 (0.0, -1.0, 0.0);
    }
    else if (gl_Normal.y > 0.5)
    {
        //  0.0,  1.0,  0.0
        tangent = vec3 (1.0, 0.0, 0.0);
        binormal = vec3 (0.0, 0.0, 1.0);
    }
    else if (gl_Normal.y < -0.5)
    {
        //  0.0, -1.0,  0.0
        useCelestialSpecularMapping = 0.0;
        tangent = vec3 (1.0, 0.0, 0.0);
        binormal = vec3 (0.0, 0.0, 1.0);
    }
    else if (gl_Normal.z > 0.5)
    {
        //  0.0,  0.0,  1.0
        tangent = vec3 (1.0, 0.0, 0.0);
        binormal = vec3 (0.0, -1.0, 0.0);
    }
    else if (gl_Normal.z < -0.5)
    {
        //  0.0,  0.0, -1.0
        tangent = vec3 (-1.0, 0.0, 0.0);
        binormal = vec3 (0.0, -1.0, 0.0);
    }

    mat3 tbnMatrix = mat3 (tangent.x, binormal.x, normal.x,
                           tangent.y, binormal.y, normal.y,
                           tangent.z, binormal.z, normal.z);

    vec3 cameraPosition =
        vec3 (gl_ModelViewMatrixInverse * vec4 (0.0, 0.0, 0.0, 1.0));
    cameraPosition = cameraPosition - gl_Vertex.xyz;
    viewVectorSpec = normalize (tbnMatrix * cameraPosition);    // As the name strongly implies, different viewVector calculations for specular reflections in the fragment shader. Should not be required to do, so I hope to find what's wrong with the base.fsh, some day.

    vec3 N = normalize (gl_NormalMatrix * gl_Normal);
    tangent = normalize (gl_NormalMatrix * tangent);
    binormal = normalize (gl_NormalMatrix * binormal);
    mat3 tbnNormMatrix = mat3 (tangent.x, binormal.x, N.x,
                               tangent.y, binormal.y, N.y,
                               tangent.z, binormal.z, N.z);

    viewVector = normalize (vec3 (gl_ModelViewMatrix * gl_Vertex));
    viewVector = normalize (tbnNormMatrix * viewVector);    // Original view vector computation for the bump part of the parallax occlusion. See above note.

    if (worldTime < 12000 || worldTime > 23250)
    {
        lightVector = normalize (tbnMatrix * -sunPosition);
        specMultiplier = vec4 (1.0, 1.0, 1.0, 1.0);
    }
    else
    {
        lightVector = normalize (tbnMatrix * -moonPosition);
        specMultiplier = vec4 (0.5, 0.5, 0.5, 0.5);
    }

    specMultiplier *=
        clamp (abs (float (worldTime) / 500.0 - 46.0), 0.0,
               1.0) * clamp (abs (float (worldTime) / 500.0 - 24.5), 0.0,
                             1.0) * clamp ((vertColor.r - 0.5) * 2.0, 0.0,
                                           1.0);



#endif // _ENABLE_GL_BUMP_MAPPING
#endif // _ENABLE_GL_TEXTURE_2D

#ifdef BFINDER
    if (mc_Entity.x == BFINDER_RED)
    {

        gl_Position.z = 0.0;
        vertColor = vec4 (1.0, 0.0, 0.0, 1.0);
    }
    else if (mc_Entity.x == BFINDER_GREEN)
    {
        gl_Position.z = 0.0;
        vertColor = vec4 (0.0, 1.0, 0.0, 1.0);
    }
    else if (mc_Entity.x == BFINDER_BLUE)
    {
        gl_Position.z = 0.0;
        vertColor = vec4 (0.0, 0.0, 1.0, 1.0);
    }
    else
    {
        vertColor = gl_Color;
    }
#endif

    if (renderType != 0 || mc_Entity.x == 90)
    {                           // 90 is the portal block ID, we want to carry this info to the frag
        texID = float (getTextureID (gl_MultiTexCoord0.st));
    }
    else
    {
        texID = -1.0;
    }

    blockID = mc_Entity.x;

    FogFragCoord = gl_Position.z;

}
