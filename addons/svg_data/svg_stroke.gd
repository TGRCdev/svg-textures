extends "svg_element.gd"

export var width : float setget set_width, get_width;
export var fill_id : String setget set_fill_id, get_fill_id;

# Dashes are scaled by the SVG's total size
export(Array, float) var dash_array : Array setget set_dash_array, get_dash_array;

func set_dash_array(arr):
	dash_array = arr;
	emit_signal("svg_attribute_changed", "dash_array", arr);
func get_dash_array():
	return dash_array;
func set_width(newwidth):
	width = newwidth;
	emit_signal("svg_attribute_changed", "width", newwidth);
func get_width():
	return width;
func set_fill_id(id):
	fill_id = id;
	emit_signal("svg_attribute_changed", "fill_id", id);
func get_fill_id():
	return fill_id;

func _element_type():
	return ELEMENT_TYPE.STROKE;

# Stroke data structure
# 0-1: Common SVG attributes
# 2: Width
# 3: Fill stack position
# 4: Dash array size
# 5: Pre-calculated sum of dash array
# 6-?: Dash array data
func _get_svg_data():
	var buffer = StreamPeerBuffer.new();
	buffer.put_float(width);
	buffer.put_float(_svg_data.get_element_index(fill_id) if _svg_data else -1);
	var d_sum = 0.0;
	for dash in dash_array: # Check for negatives and calculate the sum
		if dash < 0.0:
			d_sum = -1.0;
			break;
		d_sum += dash;
	if(d_sum > 0.0):
		buffer.put_float(dash_array.size());
		buffer.put_float(d_sum);
		for dash in dash_array:
			buffer.put_float(dash);
	else:
		buffer.put_float(0.0);
		buffer.put_float(0.0);
	return buffer.data_array;
