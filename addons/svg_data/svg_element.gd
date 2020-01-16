tool
extends Resource

# This class is the base of all SVG element types and handles ID's, 
# inheritance and overall data handling.

enum ELEMENT_TYPE {
	NONE = 0, # Default behaviour: Skips processing of the element
	RECT = 1,
	STROKE = 2,
	PATH = 3,
	FILL = 4
}

enum FILL_TYPE {
	NONE = 0, # Default behaviour: flat black
	FLAT = 1,
	GRADIENT = 2,
	PATTERN = 3, # We aren't implementing this right now, but we'll keep the enum reserved in case we do later 
}

enum GRADIENT_TYPE {
	LINEAR = 0 # Default behaviour: Linear
	RADIAL = 1,
}

enum GRADIENT_SPREAD_METHOD {
	PAD = 0, # Default behaviour: Pad
	REPEAT = 1,
	REFLECT = 2
}

signal svg_attribute_changed(attribute, new_value);
signal svg_id_changed(old_id, new_id);

var _svg_data;

export var id : String setget set_id, get_id;
export var parent_id : String setget set_parent_id, get_parent_id;

func set_id(new_id):
	var old_id = id;
	id = new_id;
	emit_signal("svg_id_changed", old_id, new_id);
	emit_signal("svg_attribute_changed", "id", new_id);
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
		buffer.put_float(_svg_data.get_element_index(parent_id))
	else:
		buffer.put_float(-1);
	
	# 2-?: Derived class SVG data
	buffer.put_data(self.call("_get_svg_data"));
	return buffer.data_array;

# To extend svg_element.gd:
# 1: Define the function "_get_svg_data() -> PoolByteArray", which returns the SVG data of the element to pass to the shader
# 2: Define the function "_element_type() -> int", which returns the relevant ELEMENT_TYPE enum
