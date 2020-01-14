tool
extends Node

var SVGFlat = load("res://addons/svg_data/svg_flat.gd");

var element;
var svg_data;

export var fill : Color setget set_fill, get_fill;

func set_fill(col):
	fill = col;
	if element:
		element.color = col;

func get_fill():
	return fill;

func _ready():
	print("child ready!");
	element = SVGFlat.new();
	element.id = self.name;
	element.color = fill;
	
	yield(get_tree(), "idle_frame");
	svg_data = get_parent().svg_elements;
	svg_data.add_element(element);
