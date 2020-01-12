tool
extends Resource

var file_path : String;

export var _elements : Array;
var size : Vector2 = Vector2.ONE;

var _objects_by_id : Dictionary; # [id] = Reference
var _index_by_id : Dictionary; # [id] = elements index, updated when elements are added/removed

func recalculate_id_indexes():
	_index_by_id.clear();
	for i in range(0, _elements.size()):
		_index_by_id[_elements[i].id] = i;

func add_element(element):
	if(element._svg_data): return;
	if(_objects_by_id.has(element.id)): return;
	
	_index_by_id[element.id] = _elements.size();
	_objects_by_id[element.id] = element;
	_elements.append(element);

func remove_element(element):
	if(element._svg_data != self): return;
	_elements.erase(element);
	_objects_by_id.erase(element.id);
	_index_by_id.erase(element.id);
	element._svg_data = null;
	recalculate_id_indexes();

# SVG Header
# 0-1: Relative size of the SVG image
# 2: Size of each element in floats 
# 3: Number of elements
func get_svg_data() -> PoolByteArray:
	var objs = Array();
	var max_size = 0;
	for elem in _elements:
		if not elem and _elements.has(elem):
			self.remove_element(elem);
			continue;
		if elem.has_method("get_svg_data"):
			var data = elem.get_svg_data()
			objs.append(data);
			max_size = max(max_size, data.size());
	var buffer = StreamPeerBuffer.new();
	buffer.put_float(size.x);
	buffer.put_float(size.y); # Relative SVG "size"
	buffer.put_float(float(max_size / 4)); # Element size
	buffer.put_float(float(_elements.size())); # Element count
	for obj in objs:
		obj.resize(max_size);
		buffer.put_data(obj);
	return buffer.data_array;
