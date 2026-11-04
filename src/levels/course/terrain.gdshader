// Course ground. Each vertex carries surface weights in COLOR
// (r = concrete, g = grass, b = gravel, a = rock), so each surface gets its
// own unmistakable look and a painted line marks where the fast concrete ends.
// Readability rule: design/levels/copperline-mountain.md §2.12 ground palette,
// "bright = fast".
shader_type spatial;
render_mode cull_back, diffuse_burley;

uniform vec3 concrete_color : source_color = vec3(0.80, 0.78, 0.74);
uniform vec3 grass_dark : source_color = vec3(0.13, 0.27, 0.10);
uniform vec3 grass_light : source_color = vec3(0.30, 0.46, 0.18);
uniform vec3 gravel_color : source_color = vec3(0.46, 0.40, 0.33);
uniform vec3 rock_color : source_color = vec3(0.27, 0.26, 0.29);
uniform vec3 edge_color : source_color = vec3(0.97, 0.97, 0.95);
uniform float joint_spacing = 4.0;

varying vec3 world_pos;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x),
		mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec4 w = COLOR;
	vec2 p = world_pos.xz;

	// Concrete: smooth and pale with expansion joints, so speed reads.
	vec2 g = abs(fract(p / joint_spacing) - 0.5);
	float joint = smoothstep(0.475, 0.495, max(g.x, g.y));
	vec3 conc = concrete_color * (0.95 + 0.05 * vnoise(p * 2.0)) * (1.0 - 0.3 * joint);

	// Grass: dark, blotchy and streaky; clearly not something you roll on.
	float n = vnoise(p * 0.35) * 0.5 + vnoise(p * 2.3) * 0.3 + vnoise(vec2(p.x * 9.0, p.y * 1.5)) * 0.2;
	vec3 grass = mix(grass_dark, grass_light, n);

	// Gravel: coarse brown-grey speckle.
	float s = hash(floor(p * 5.0));
	vec3 grav = gravel_color * (0.6 + 0.7 * s);

	vec3 rock = rock_color * (0.8 + 0.35 * vnoise(p * 0.7));

	float total = max(w.r + w.g + w.b + w.a, 0.001);
	vec3 col = (conc * w.r + grass * w.g + grav * w.b + rock * w.a) / total;

	// Painted edge line where concrete meets slow ground (not rock).
	float edge = 1.0 - abs(w.r / total * 2.0 - 1.0);
	float rough = (w.g + w.b) / total;
	edge *= step(0.05, rough);
	col = mix(col, edge_color, smoothstep(0.6, 0.85, edge));

	ALBEDO = col;
	ROUGHNESS = mix(1.0, 0.75, w.r / total);
}
