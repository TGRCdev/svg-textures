tool
extends "../svg_element.gd"

export var transform : Transform2D = Transform2D() setget set_transform, get_transform;
export var fill_id : String = "" setget set_fill_id, get_fill_id;
export var stroke_id : String = "" setget set_stroke_id, get_stroke_id;

func set_transform(trns):
	transform = trns;
	emit_signal("svg_attribute_changed", "transform", transform);
func get_transform():
	return transform;
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

func _get_svg_data():
	var buffer = StreamPeerBuffer.new();
	# 0-1: Common SVG Attributes
	# 2: Shape type
	buffer.put_float(self.call("_shape_type"));

	# 3-8: 3x2 Inverse Transform matrix
	var invr_trns = transform.affine_inverse();
	for x in range(0,3):
		for y in range(0,2):
			buffer.put_float(invr_trns[x][y]);
	
	var _svg_data = self.get("_svg_data");

	# 9: Stack position of Fill object
	buffer.put_float(_svg_data.get_element_index(fill_id) if _svg_data else -1);

	# 10: Stack position of Stroke object
	buffer.put_float(_svg_data.get_element_index(stroke_id) if _svg_data else -1);
	
	# 11-?: Derived data
	if self.has_method("_get_shape_data"):
		buffer.put_data(self.call("_get_shape_data"));
	
	return buffer.data_array;
