tool
extends MeshInstance

var SVGData = preload("res://addons/svg_data/svg_data.gd");

export var svg : Resource;

var mat;
var tex;
var img;

func _update_svg():
	var data = svg.get_svg_data();
	img.create_from_data(data.size() / 4, 1, false, Image.FORMAT_RF, data);
	tex.create_from_image(img, 0);
	
	mat.set_shader_param("svg_elements", tex);

func _init():
	svg = SVGData.new();
	mat = get_surface_material(0);
	img = Image.new();
	tex = ImageTexture.new();

func _ready():
	svg.connect("svg_update", self, "_update_svg");
	_update_svg();
