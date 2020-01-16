tool
extends "../svg_element.gd"

export var color : Color setget set_color, get_color;

func set_color(value):
	color = value;
	emit_signal("svg_attribute_changed", "color", value);
func get_color():
	return color;

func _element_type():
	return ELEMENT_TYPE.FILL;

func _fill_type():
	return FILL_TYPE.FLAT;

# Flat fill data structure
# 0-1: Common SVG attributes
# 2: Fill type
# 3-6: RGBA color
func _get_svg_data():
	var buf = StreamPeerBuffer.new();
	buf.put_float(FILL_TYPE.FLAT);
	buf.put_float(color.r);
	buf.put_float(color.g);
	buf.put_float(color.b);
	buf.put_float(color.a);
	return buf.data_array;
