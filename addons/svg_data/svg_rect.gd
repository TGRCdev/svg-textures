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
	# 2-7: 3x2 Transform matrix
	var inv_trns = transform.affine_inverse();
	for x in range(0,3):
		for y in range(0,2):
			buffer.put_float(inv_trns[x][y]);
	# 8-9: Offset from pivot
	buffer.put_float(offset.x);
	buffer.put_float(offset.y);
	# 10: Fill type
	buffer.put_float(fill_type);
	match(fill_type):
		# 11-14: Flat color
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
