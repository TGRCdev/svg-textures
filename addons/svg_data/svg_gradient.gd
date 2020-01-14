tool
extends "svg_element.gd"

export(GRADIENT_TYPE) var gradient_type : int;
export(GRADIENT_SPREAD_METHOD) var spread_method : int = GRADIENT_SPREAD_METHOD.PAD setget set_spread_method, get_spread_method;
export var p1 : Vector2 = Vector2(0,0) setget set_p1, get_p1; # begin when LINEAR, center when RADIAL
export var p2 : Vector2 = Vector2(1,0) setget set_p2, get_p2; # end when LINEAR, focal point when RADIAL
export var radius : float = 1.0; # used when RADIAL, ignored with LINEAR

export var _color_stops : Dictionary; # [offset] = Flat color

# Note about implementation:
# I'm not supporting offsets outside of [0..1] to simplify my math later on
# Fix your god damn offsets yourself

func set_p1(pos):
	p1 = pos;
	emit_signal("svg_attribute_changed", "p1", pos);
func get_p1():
	return p1;
func set_p2(pos):
	p2 = pos;
	emit_signal("svg_attribute_changed", "p2", pos);
func get_p2():
	return p2;
func set_spread_method(method):
	spread_method = method;
	emit_signal("svg_attribute_changed", "spread_method", method);
func get_spread_method():
	return spread_method;

func set_stop(offset:float, color:Color):
	if(offset < 0.0 or offset > 1.0):
		printerr("Color stop offset was out of range 0.0 to 1.0 (Actual value: %f)! Color stop was not added." % offset)
		return;
	_color_stops[offset] = color;
	emit_signal("svg_attribute_changed", "_color_stops", _color_stops);
func remove_stop(offset:float):
	_color_stops.erase(offset);
	emit_signal("svg_attribute_changed", "_color_stops", _color_stops);
func get_stop_offsets():
	return _color_stops.keys();
func clear_stops():
	_color_stops.clear();
	emit_signal("svg_attribute_changed", "_color_stops", _color_stops);

func _element_type():
	return ELEMENT_TYPE.FILL;

func _fill_type():
	return FILL_TYPE.GRADIENT;

# Gradient data structure
# 0-1: Common SVG attributes
# 2: Fill type (GRADIENT)
# 3: Gradient type
# 4: Spread method
# 5-6: Position one (begin when LINEAR, center when RADIAL/FOCAL)
# 7-8: Position two (end when LINEAR, radius when RADIAL, focal when FOCAL)
# 9-10: Pre-calculated normalized direction vector
# 11: Pre-calculated distance
# 12: Radius
# 13: Stop count
# 14-?: Color stops, ordered by offset
func _get_svg_data():
	# Developer note
	# I pre-calculate the direction vector and the distance
	# because it's much more efficient to calculate those
	# once and store it in the buffer rather than
	# calculate it per pixel in the shader.
	var buffer = StreamPeerBuffer.new();
	buffer.put_float(float(FILL_TYPE.GRADIENT));
	buffer.put_float(float(gradient_type));
	buffer.put_float(float(spread_method));
	buffer.put_float(p1.x);
	buffer.put_float(p1.y);
	buffer.put_float(p2.x);
	buffer.put_float(p2.y);
	var dir = (p2 - p1).normalized();
	buffer.put_float(dir.x);
	buffer.put_float(dir.y);
	buffer.put_float(p1.distance_to(p2));
	buffer.put_float(radius);
	buffer.put_float(_color_stops.size());
	var offsets = _color_stops.keys();
	offsets.sort();
	# Color stop data structure
	# 0: Offset, usually [0..1] but outside of the range is allowed
	# 1-4: RGBA color
	for offset in offsets:
		buffer.put_float(offset);
		var col = _color_stops[offset];
		buffer.put_float(col.r);
		buffer.put_float(col.g);
		buffer.put_float(col.b);
		buffer.put_float(col.a);
	return buffer.data_array;
