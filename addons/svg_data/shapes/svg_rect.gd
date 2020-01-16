tool
extends "svg_shape.gd"

# This class represents a <rect> SVG element.

func _element_type():
	return ELEMENT_TYPE.SHAPE;

func _shape_type():
	return SHAPE_TYPE.RECT;

export var corner_radii : Vector2 = Vector2.ZERO setget set_corner_radii, get_corner_radii;

func set_corner_radii(radii):
	corner_radii = radii;
	emit_signal("svg_attribute_changed", "corner_radii", radii);
func get_corner_radii():
	return corner_radii;

func _get_shape_data() -> PoolByteArray:
	var buffer = StreamPeerBuffer.new();
	# 0-1: Common SVG Attributes
	# 2: Shape type
	# 3-8: 3x2 Inverse Transform matrix
	# 9: Stack position of Fill object
	# 10: Stack position of Stroke object
	
	# 11-12: Corner radii (scaled)
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
	var invr_trns = transform.affine_inverse();
	scaled_radii *= invr_trns.get_scale();
	buffer.put_float(scaled_radii.x);
	buffer.put_float(scaled_radii.y);

	return buffer.data_array;
