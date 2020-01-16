tool
extends "svg_shape.gd"

func _element_type():
	return ELEMENT_TYPE.SHAPE;

func _shape_type():
	return SHAPE_TYPE.ELLIPSE;

# _get_shape_data isn't needed cause Ellipse doesn't have any additional
# information
