tool
extends Node

var _cache : Dictionary; # Dictionary of Resource

func get_svg_data(path):
	if _cache.has(path):
		return _cache[path];
	else:
		return null;

func set_svg_data(path:String, data:Resource):
	_cache[path] = data;

func clear_cache():
	_cache.clear();

func remove_svg_data(path:String):
	_cache.erase(path);
