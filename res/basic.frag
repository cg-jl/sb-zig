// vim:ft=glsl
#version 330 core

#define MAX_TRACES 100

layout(location = 0) out vec4 color;
uniform float u_time;

vec3 flat_orbit(in vec3 center, float radius, float t) {
    float z = radius * sin(t);
    float x = radius * cos(t);
    float y = center.y;

    return vec3(x, y, z);
}


vec3 rotate_along_z_axis(in vec3 v, float theta) {
    float cost = cos(theta);
    float sint = sin(theta);
    return vec3(v.x * cost + v.y * sint, v.y * cost - v.x * sint, v.z);
}

float dist_to_sphere(in vec3 point, in vec3 center, float r) {
    return length(point - center) - r;
}



float sdf(in vec3 point) {
    const float SPHERE_RADIUS = 0.3;

    return dist_to_sphere(point, vec3(0.0), SPHERE_RADIUS);


}


vec3 getnormal(in vec3 p) {
    const vec3 small_step = vec3(0.001, 0.0, 0.0);

    // get gradient in all directions
    float gx = sdf(p + small_step.xyy) - sdf(p - small_step.xyy);
    float gy = sdf(p + small_step.yxy) - sdf(p - small_step.yxy);
    float gz = sdf(p + small_step.yyx) - sdf(p - small_step.yyx);

    return normalize(vec3(gx, gy, gz));
}


vec3 march(in vec3 ro, in vec3 rd) {
    const float MAX_TRACE_DIST = 1000.0;
    const float MIN_TRACE_DIST = 0.001;
    const int NO_STEPS = 32;

    float total_distance_traveled = 0.0;


    for (int i = 0; i < NO_STEPS ; ++i) {
        vec3 current_pos = ro + total_distance_traveled * rd;

        float dist_to_closest = sdf(current_pos);
        if (dist_to_closest < MIN_TRACE_DIST) {
            vec3 normal = getnormal(current_pos);

            // make light orbit around
            // x+ -> left
            // y+ -> down
            // z+ -> towards viewer
            vec3 light_pos = rotate_along_z_axis(flat_orbit(vec3(0.0), 0.5,
                        u_time), 0.05 * u_time);

            vec3 dir_to_light = normalize(current_pos - light_pos);

            // use dot to know how much light does this thing receive.
            float diffuse_intentsity = max(0.0, dot(normal, dir_to_light));

            return vec3(diffuse_intentsity, 0.0, 0.0);
        }
        if (total_distance_traveled > MAX_TRACE_DIST) break;
        
        total_distance_traveled += dist_to_closest;

    }


    // we didn't hit anything, so just get black for background
    return vec3(0.0);

}



void main() {
    const vec2 resolution = vec2(640.0, 480.0);
    const float SPHERE_RADIUS = 0.3;

    // let's start by drawing  the current state


    vec2 uv = gl_FragCoord.xy/resolution.xy - 0.5;
    // multiply by the aspect ratio
    uv.x *= resolution.x / resolution.y;

    // we have a camera at the front, 5 points away
    const float CAMERA_Z = 5.0;
    const vec3 CAMERA_ORIGIN = vec3(0.0, 0.0, -CAMERA_Z);



    vec3 col = march(CAMERA_ORIGIN, normalize(vec3(uv, 0.0) - CAMERA_ORIGIN));


    /* vec3 col = vec3(uv, 0.5+0.5*sin(u_time)); */

    //float sm = smoothstep(0.01, 0.0, length(uv));

    //col = vec3(sm) + col * (1.0 - sm); 
         


    color = vec4(col, 1.0);
}
