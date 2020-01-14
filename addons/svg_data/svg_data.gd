tool
extends Resource

# This class represents the <svg> root tag.

# TODO: Possibly extend from "svg_element.gd" to support embedded
# SVG roots?

var file_path : String;

export var _elements : Array;
var size : Vector2 = Vector2.ONE;

var _objects_by_id : Dictionary; # [id] = Reference
var _index_by_id : Dictionary; # [id] = elements index, updated when elements are added/removed

signal svg_update; # Emitted when the contained SVG data has changed somehow. Use this to pass data to the shader.
signal svg_element_changed(element, attribute); # Emitted when a contained element is changed.

func _element_changed(element, attribute, value):
	emit_signal("svg_element_changed", element, attribute);
	emit_signal("svg_update");

func recalculate_id_indexes():
	_index_by_id.clear();
	for i in range(0, _elements.size()):
		_index_by_id[_elements[i].id] = i;

func add_element(element):
	if(element._svg_data): return;
	if(element.id.empty()): return; # "" is not a valid ID
	if(_objects_by_id.has(element.id)): return;
	
	_index_by_id[element.id] = _elements.size();
	_objects_by_id[element.id] = element;
	_elements.append(element);
	element._svg_data = self;
	element.connect("svg_attribute_changed", self, "_element_changed", [element]);
	emit_signal("svg_update");

func remove_element(element):
	if(element._svg_data != self): return;
	_elements.erase(element);
	_objects_by_id.erase(element.id);
	_index_by_id.erase(element.id);
	element._svg_data = null;
	if element.is_connected("svg_attribute_changed", self, "_element_changed"):
		element.disconnect("svg_attribute_changed", self, "_element_changed");
	recalculate_id_indexes();
	emit_signal("svg_update");

func get_element_index(id) -> int:
	if not id.empty() and _index_by_id.has(id):
		return _index_by_id[id];
	else:
		return -1;

func get_element_by_id(id):
	if not id.empty() and _objects_by_id.has(id):
		return _objects_by_id[id];
	else:
		return null;

# SVG Header
# 0-1: Relative size of the SVG image
# 2: Number of elements
# 3-?: Array of indices pointing to the first float of each element, offset
#      by the total size of the SVG header. (i.e. 0 would be the first float
#      after the SVG header)
func get_svg_data() -> PoolByteArray:
	var buffer = StreamPeerBuffer.new();
	buffer.put_float(size.x);
	buffer.put_float(size.y); # Relative SVG "size"
	buffer.put_float(float(_elements.size())); # Element count
	var heap = StreamPeerBuffer.new();
	for elem in _elements:
		if (not elem or not elem.has_method("get_svg_data")) and _elements.has(elem):
			self.remove_element(elem);
			continue;
		else:
			buffer.put_float(heap.data_array.size() / 4); # Index to element beginning
			heap.put_data(elem.get_svg_data());
	buffer.put_data(heap.data_array);
	return buffer.data_array;
