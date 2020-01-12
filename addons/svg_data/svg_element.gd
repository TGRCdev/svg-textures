tool
extends Reference

#enum ELEMENT_TYPE {
#	NONE = 0
#	RECT = 1,
#	CIRCLE = 2,
#	PATH = 3,
#}

#enum FILL_TYPE {
#	FLAT = 0,
#	GRADIENT = 1
#}

var _svg_data;# : SVGData;

var id : String;
var parent_id : String;

func get_svg_data() -> PoolByteArray:
	var buffer = StreamPeerBuffer.new();
	# Step 1: Common SVG elements
	# 0: Element type
	if self.has_method("_element_type"):
		buffer.put_float(float(self.call("_element_type")));
	else:
		buffer.put_float(float(0)); # NONE
	# 1: Parent index
	if _svg_data and parent_id:
		buffer.put_float(_svg_data._index_by_id[parent_id])
	else:
		buffer.put_float(-1);
	
	# 2-?: Derived class SVG data
	if self.has_method("_get_svg_data"):
		buffer.put_data(self.call("_get_svg_data"));
	return buffer.data_array;
