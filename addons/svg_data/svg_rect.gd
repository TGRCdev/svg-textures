tool
extends "svg_element.gd"

# This class represents a <rect> SVG element.

func _element_type():
	return ELEMENT_TYPE.RECT; #RECT

export var transform : Transform2D setget set_transform, get_transform;
export var offset : Vector2 = Vector2.ZERO setget set_offset, get_offset;
export var fill_id : String setget set_fill_id, get_fill_id;

func set_transform(trns):
	transform = trns;
	emit_signal("svg_attribute_changed", "transform", transform);
func get_transform():
	return transform;
func set_offset(value):
	offset = value;
	emit_signal("svg_attribute_changed", "offset", value);
func get_offset():
	return offset;
func set_fill_id(id):
	fill_id = id;
	emit_signal("svg_attribute_changed", "fill_id", id);
func get_fill_id():
	return fill_id;

func _get_svg_data() -> PoolByteArray:
	var buffer = StreamPeerBuffer.new();
	# 0-1 filled by base SVG data
	# 2-7: 3x2 Inverse Transform matrix
	var invr_trns = transform.affine_inverse();
	for x in range(0,3):
		for y in range(0,2):
			buffer.put_float(invr_trns[x][y]);
	# 8-9: Scale (computed from matrix)
	var scale = transform.get_scale();
	buffer.put_float(scale.x);
	buffer.put_float(scale.y);
	# 10-11: Offset from pivot
	buffer.put_float(offset.x);
	buffer.put_float(offset.y);
	# 12: Stack position of Fill object
	buffer.put_float(_svg_data.get_element_index(fill_id));
	return buffer.data_array;
