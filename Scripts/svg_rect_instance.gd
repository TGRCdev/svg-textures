tool
extends Node

var SVGRect = load("res://addons/svg_data/svg_rect.gd");

var element;
var svg_data;

export var origin : Vector2 = Vector2.ZERO setget set_origin, get_origin;
export var scale : Vector2 = Vector2.ONE setget set_scale, get_scale;
export var rotation : float = 0.0 setget set_rotation, get_rotation;

export var offset : Vector2 = Vector2.ZERO setget set_offset, get_offset;
export var fill_id : String setget set_fill_id, get_fill_id;

func _recalculate_transform():
	element.transform = Transform2D(Vector2(scale.x, 0.0), Vector2(0.0,scale.y), Vector2.ZERO);
	element.transform = element.transform.rotated(rotation);
	element.transform.origin = origin;

func set_origin(pos):
	origin = pos;
	if element:
		_recalculate_transform();
func get_origin():
	return origin;
func set_scale(value):
	scale = value;
	if element:
		_recalculate_transform();
func get_scale():
	return scale;
func set_rotation(value):
	rotation = value;
	if element:
		_recalculate_transform();
func get_rotation():
	return rotation;
func set_offset(value):
	offset = value;
	if element:
		element.offset = value;
func get_offset():
	return offset;
func set_fill_id(id):
	fill_id = id;
	if element:
		element.fill_id = id;
func get_fill_id():
	return fill_id;

func _ready():
	
	print("child ready!");
	element = SVGRect.new();
	element.id = self.name;
	element.offset = offset;
	element.fill_id = fill_id;
	_recalculate_transform();
	
	yield(get_tree(), "idle_frame");
	svg_data = get_parent().svg_elements;
	svg_data.add_element(element);
