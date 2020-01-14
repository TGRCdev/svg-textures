tool
extends MeshInstance

var SVGData = load("res://addons/svg_data/svg_data.gd");

export var svg_elements : Resource;
export var svg_size : Vector2 = Vector2.ONE setget set_svg_size, get_svg_size;

func set_svg_size(size):
	svg_size = size;
	if svg_elements:
		svg_elements.size = svg_size;
func get_svg_size():
	return svg_size;

func _update_svg():
	print("updating SVG");
	var svg_data = svg_elements.get_svg_data();
	img.create_from_data(svg_data.size() / 4, 1, false, Image.FORMAT_RF, svg_data);
	texture.create_from_image(img, 0);
	
	material.set_shader_param("svg_elements", texture);

var img : Image;
var texture : ImageTexture;
var material : ShaderMaterial;

func _ready():
	print("parent ready!")
	img = Image.new();
	texture = ImageTexture.new();
	
	material = self.get_surface_material(0);
	svg_elements = SVGData.new();
	svg_elements.size = svg_size;
	$TextureRect.texture = texture;
	svg_elements.connect("svg_update", self, "_update_svg");
	_update_svg();
