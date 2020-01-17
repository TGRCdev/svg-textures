tool
extends MeshInstance

var SVGData = preload("res://addons/svg_data/svg_data.gd");

export var svg : Resource;

var mat;
var tex;
var img;

func _update_svg():
	print("Updating SVG");
	var data = svg.get_svg_data();
	img.create_from_data(data.size() / 4, 1, false, Image.FORMAT_RF, data);
	tex.create_from_image(img, 0);
	
	mat.set_shader_param("svg_elements", tex);

func _init():
	svg = SVGData.new();
	mat = get_surface_material(0);
	if not mat:
		mat = ShaderMaterial.new();
		mat.shader = preload("res://addons/svg_data/basic_svg_spatial.shader");
		set_surface_material(0, mat);
	img = Image.new();
	tex = ImageTexture.new();

func _ready():
	svg.connect("svg_update", self, "_update_svg");
	_update_svg();
