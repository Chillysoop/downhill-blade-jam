// City buildings (CityKit "solids", style building). Each box carries its
// paint colour in COLOR; the walls get a grid of windows and storey bands from
// world position, roofs are a darker tar colour. Hillcrest Drop look:
// design/levels/hillcrest-drop.md (Look and landmarks).
shader_type spatial;
render_mode cull_back, diffuse_burley;

uniform float storey = 3.4;
uniform float bay = 3.0;
uniform vec3 glass : source_color = vec3(0.20, 0.27, 0.36);
uniform vec3 roof : source_color = vec3(0.30, 0.29, 0.30);

varying vec3 world_pos;
varying vec3 world_n;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_n = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	vec3 col = COLOR.rgb;
	if (world_n.y > 0.7) {
		ALBEDO = roof;
		ROUGHNESS = 0.95;
	} else {
		float along = abs(world_n.x) > abs(world_n.z) ? world_pos.z : world_pos.x;
		vec2 cell = vec2(fract(along / bay), fract(world_pos.y / storey));
		float win = step(0.22, cell.x) * step(cell.x, 0.78) * step(0.3, cell.y) * step(cell.y, 0.82);
		float trim = step(0.93, cell.y);
		col = mix(col, glass, win * 0.85);
		col = mix(col, col * 1.18 + 0.08, trim);
		ALBEDO = col;
		ROUGHNESS = mix(0.85, 0.25, win);
		METALLIC = win * 0.2;
	}
}
