// Beta UI damajor.
// todo: rewrite this poor code
//
#version 130

uniform sampler2D sampler0;

uniform float aspectRatio;
uniform float displayWidth;
uniform float displayHeight;
uniform int health;
uniform int armor;

void main() {
    vec4 baseColor = texture2D(sampler0, gl_TexCoord[0].st);
    vec4 color = baseColor;
#ifdef BETA_UI
    float cellInSize = cellSize - cellBorderSize;
    float dist = 10000000.0;
    float emptyHealthCell = 0.0;
    float emptyArmorCell = 0.0;
    float screenSide = 0.0; // 0.0: left 1.0: right

    float d = -1.0;
    float d2 = -1.0;
    for(int i=1; i<=20; i++) {
        float d = distance(gl_TexCoord[0].xy, vec2(stepSize, stepSize * i));
        float d2 = distance(gl_TexCoord[0].xy, vec2(1 - stepSize, stepSize * i));
        if (d2 < d) {
            screenSide = 1.0;
            d = d2;
        }
        if (d<dist) {
            dist = d;
            if (i>health)
                emptyHealthCell = emptyHealthCellTransp;
            if (i>armor)
                emptyArmorCell = emptyArmorCellTransp;
        }
    }

    if( dist < cellSize ) {
        if( dist < cellInSize ) {
            float att = mainCellTransp;
            if ((screenSide == 1.0) && (armor >= 0 && armor <= 20)) {
                att = att - emptyArmorCell;
                color = mix(baseColor, armorColor, att);
            } else if ((screenSide == 0.0) && (health >= 0 && health <= 20)) {
                att = att - emptyHealthCell;
                color = mix(baseColor, healthColor, att);
            }
        } else {
            if ((screenSide == 1.0) && (armor >= 0 && armor <= 20)) {
                color = armorColor;
            } else if ((screenSide == 0.0) && (health >= 0 && health <= 20)) {
                color = healthColor;
            }
        }
    }
#endif
    gl_FragColor = color;
}

