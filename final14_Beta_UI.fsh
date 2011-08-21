// Beta UI damajor.
// todo:    item in hand...
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
    float stepSize = 0;
    float dist = 10000000.0;
    float emptyHealthCell = 0;
    float emptyArmorCell = 0;
    float screenSide = 0.0; // 0.0: left 1.0: right

    if (health >= 0 && health <= 20) {
        stepSize = 0.04; // 1/25
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
    }

    if( dist < (stepSize/8*2.5) ) {
        if( dist < (stepSize/8*2.3) ) {
            float att = mainCellTransp;
            if (screenSide == 1.0) {
                att = att - emptyArmorCell;
                color = mix(baseColor, armorColor, att);
            } else if (screenSide == 0.0) {
                att = att - emptyHealthCell;
                color = mix(baseColor, healthColor, att);
            }
        } else {
            if (screenSide == 1.0) {
                color = armorColor;
            } else if (screenSide == 0.0) {
                color = healthColor;
            }
        }
    }
#endif
    gl_FragColor = color;
}

