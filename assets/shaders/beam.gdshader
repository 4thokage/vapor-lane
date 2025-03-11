shader_type spatial;
render_mode unshaded, depth_draw_always, cull_disabled;

vec3 fresnel_glow(float amount, float intensity, vec3 color, vec3 normal, vec3 view)
{
    return pow(1.0 - dot(normalize(normal), normalize(view)), amount) * color * intensity;
}

void fragment()
{
    vec3 base_color = vec3(0.5, 0.2, 0.9); 
    vec3 fresnel_color = vec3(0.0, 0.7, 0.9);
    
    float fresnel = pow(1.0 - dot(normalize(NORMAL), normalize(VIEW)), 4.0);
    
    // Base object is transparent, edges glow
    ALBEDO = fresnel_color * 4.5 * fresnel;
    ALPHA = fresnel * 2.5; // Increase ALPHA to make glow stronger

    // Prevent fully black parts (use clamp to avoid complete invisibility on edges)
    ALPHA = clamp(ALPHA, 0.0, 1.0);
}
