//
//  Shaders.metal
//  Segregation
//
//  Created by Yoshimi Shingai on 2018/11/30.
//  Copyright © 2018 SHINGAI YOSHIMI. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

struct Object {
    uint group;
    float x;
    float y;
    float angle;
};

float getDistance(float2 pos1, float2 pos2) {
    float2 d = pos1 - pos2;
    return sqrt(d.x*d.x+d.y*d.y);
}

kernel void simulate(const device Object *in [[ buffer(0) ]],
                     const device uint &count [[ buffer(1) ]],
                     const device float &width [[ buffer(2) ]],
                     const device float &height [[ buffer(3) ]],
                     device Object *out [[ buffer(4) ]],
                     uint id [[ thread_position_in_grid ]]) {
    Object object = in[id];
    out[id] = object;

    float2 objectPos = float2(object.x,object.y);

    int total = 0;
    int group = 0;
    for (uint i=0; i<count; i++){
        if (i == id){
            continue;
        };

        Object other = in[i];

        float2 otherPos = float2(other.x,other.y);
        float dist = getDistance(objectPos,otherPos);

        int near = step(dist,20);
        total += near;
        group += (object.group == other.group) * near;
    }
    
    int stay = step(1.0,total)*step(total*0.5, group);
    if (stay) {
        return;
    }
    
    float translationX = sin(object.angle);
    float translationY = cos(object.angle);

    float x = object.x + translationX;
    x -= (x > width) ? width : 0;
    x += (x < 0) ? width : 0;

    float y = object.y + translationY;
    y -= (y > height) ? height : 0;
    y += (y < 0) ? height : 0;

    out[id].x = x;
    out[id].y = y;
}
