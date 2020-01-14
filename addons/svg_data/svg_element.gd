tool
extends Resource

# This class is the base of all SVG element types and handles ID's, 
# inheritance and overall data handling.

enum ELEMENT_TYPE {
	NONE = 0 # Default behaviour: Skips processing of the element
	RECT = 1,
	CIRCLE = 2,
	PATH = 3,
	FILL = 4
}

enum FILL_TYPE {
	NONE = 0 # Default behaviour: flat black
	FLAT = 1,
	GRADIENT = 2,
	PATTERN = 3, # We aren't implementing this right now, but we'll keep the enum reserved in case we do later 
}

signal svg_attribute_changed(attribute, value);

var _svg_data;

var id : String setget set_id, get_id;
var parent_id : String setget set_parent_id, get_parent_id;

func set_id(newid):
	id = newid;
	emit_signal("svg_attribute_changed", "id", newid);
func get_id():
	return id;
func set_parent_id(newid):
	parent_id = newid;
	emit_signal("svg_attribute_changed", "parent_id", newid);
func get_parent_id():
	return parent_id;

func get_svg_data() -> PoolByteArray:
	if not self.has_method("_element_type") or not self.has_method("_get_svg_data"):
		return PoolByteArray(); # Malformed
	var buffer = StreamPeerBuffer.new();
	# Step 1: Common SVG elements
	# 0: Element type
	buffer.put_float(float(self.call("_element_type")));
	
	# 1: Parent index
	if _svg_data and parent_id:
		buffer.put_float(_svg_data._index_by_id[parent_id])
	else:
		buffer.put_float(-1);
	
	# 2-?: Derived class SVG data
	buffer.put_data(self.call("_get_svg_data"));
	return buffer.data_array;

# To extend svg_element.gd:
# 1: Define the function "_get_svg_data() -> PoolByteArray", which returns the SVG data of the element to pass to the shader
# 2: Define the function "_element_type() -> int", which returns the relevant ELEMENT_TYPE enum
