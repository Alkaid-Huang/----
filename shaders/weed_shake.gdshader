shader_type canvas_item;

uniform float shake_intensity : hint_range(0.0, 1.0) = 0.0;

void vertex() {
	float offset_x = sin(TIME * 35.0 + VERTEX.y * 0.3) * shake_intensity * 4.0;
	float offset_y = cos(TIME * 40.0 + VERTEX.x * 0.25) * shake_intensity * 3.0;
	VERTEX.x += offset_x;
	VERTEX.y += offset_y;
}
