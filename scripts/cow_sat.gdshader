shader_type canvas_item;
uniform float saturation : hint_range(0.0, 1.0) = 1.0;

void fragment() {
    vec4 col = texture(TEXTURE, UV);
    float grey = dot(col.rgb, vec3(0.299, 0.587, 0.114));
    col.rgb = mix(vec3(grey), col.rgb, saturation);
    COLOR = col;
}