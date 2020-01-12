tool
extends EditorPlugin

var svg_cache : Dictionary;
var cache_node : Node;

func _enter_tree():
	self.add_autoload_singleton("SVGCache", "svg_cache.gd");
	pass

func _exit_tree():
	self.remove_autoload_singleton("SVGCache");
	pass
