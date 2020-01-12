tool
extends "res://addons/svg_data/svg_element.gd"

func _element_type():
	return 1; #RECT

var transform : Transform2D;
var offset : Vector2 = Vector2.ZERO;

var fill_type : int;
var fill; # Either Color or Gradient

func _init():
	transform = Transform2D();
	fill_type = 0; # FILL
	fill = Color(0.0,0.0,0.0,1.0);

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
	# 12: Fill type
	buffer.put_float(fill_type);
	match(fill_type):
		# 13-16: Flat color
		0: # Flat
			buffer.put_float(fill.r);
			buffer.put_float(fill.g);
			buffer.put_float(fill.b);
			buffer.put_float(fill.a);
		1: # Gradient
			# TODO
			pass
		_:
			pass
	return buffer.data_array;
