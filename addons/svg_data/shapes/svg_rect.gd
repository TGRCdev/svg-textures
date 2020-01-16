tool
extends "../svg_element.gd"

# This class represents a <rect> SVG element.

func _element_type():
	return ELEMENT_TYPE.RECT; #RECT

export var transform : Transform2D setget set_transform, get_transform;
export var corner_radii : Vector2 = Vector2.ZERO setget set_corner_radii, get_corner_radii;
export var fill_id : String setget set_fill_id, get_fill_id;
export var stroke_id : String setget set_stroke_id, get_stroke_id;

func set_transform(trns):
	transform = trns;
	emit_signal("svg_attribute_changed", "transform", transform);
func get_transform():
	return transform;
func set_corner_radii(radii):
	corner_radii = radii;
	emit_signal("svg_attribute_changed", "corner_radii", radii);
func get_corner_radii():
	return corner_radii;
func set_fill_id(id):
	fill_id = id;
	emit_signal("svg_attribute_changed", "fill_id", id);
func get_fill_id():
	return fill_id;
func set_stroke_id(id):
	stroke_id = id;
	emit_signal("svg_attribute_changed", "stroke_id", id);
func get_stroke_id():
	return stroke_id;

func _get_svg_data() -> PoolByteArray:
	var buffer = StreamPeerBuffer.new();
	# 0-1 filled by base SVG data
	# 2-7: 3x2 Inverse Transform matrix
	var invr_trns = transform.affine_inverse();
	for x in range(0,3):
		for y in range(0,2):
			buffer.put_float(invr_trns[x][y]);
	# 8-9: Corner radii (scaled)
	var scaled_radii = corner_radii;
	if(scaled_radii.x <= 0.0):
		if(scaled_radii.y > 0.0):
			scaled_radii.x = scaled_radii.y;
		else:
			scaled_radii = Vector2();
	elif(scaled_radii.y <= 0.0):
		scaled_radii.y = scaled_radii.x;
	var scale = transform.get_scale() / 2;
	scaled_radii = Vector2(min(scaled_radii.x, scale.x), min(scaled_radii.y, scale.y));
	scaled_radii *= invr_trns.get_scale();
	buffer.put_float(scaled_radii.x);
	buffer.put_float(scaled_radii.y);
	# 10: Stack position of Fill object
	buffer.put_float(_svg_data.get_element_index(fill_id) if _svg_data else -1);
	# 11: Stack position of Stroke object
	buffer.put_float(_svg_data.get_element_index(stroke_id) if _svg_data else -1);
	return buffer.data_array;
