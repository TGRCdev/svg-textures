shader_type spatial;
render_mode unshaded;

uniform sampler2D svg_elements;

// const int HEADER_SIZE = 4; // Only works in Godot 3.2 master branch WHOOPS

// SVG Header
// 0-1: SVG image scale
// 2: Number of elements
// 3-?: Array of indices on heap
// "Heap" data comes directly after the header

int get_element_count()
{
	return int(texelFetch(svg_elements, ivec2(2,0), 0).r);
}

int get_header_size() // this also doubles as the offset to the beginning of the heap
{
	int elems = get_element_count();
	return 3 + elems; // one float per element in the header array
}

vec2 get_svg_size()
{
	return vec2(
		texelFetch(svg_elements, ivec2(0, 0), 0).r,
		texelFetch(svg_elements, ivec2(1, 0), 0).r
	);
}

int get_heap_offset(int index)
{
	return int(texelFetch(svg_elements, ivec2(3+index, 0), 0).r);
}

float read_float(int index, int offset)
{
	return texelFetch(svg_elements, ivec2(get_heap_offset(index)+offset+get_header_size(), 0), 0).r;
}

int read_int(int index, int offset)
{
	return int(read_float(index, offset));
}

vec2 read_vec2(int index, int offset)
{
	return vec2(
		read_float(index, offset),
		read_float(index, offset+1)
	);
}

vec4 read_vec4(int index, int offset)
{
	return vec4(
		read_float(index, offset),
		read_float(index, offset+1),
		read_float(index, offset+2),
		read_float(index, offset+3)
	);
}

mat3 read_3x2mat(int index, int offset)
{
	mat3 ret;
	ret[0][0] = read_float(index, offset);
	ret[0][1] = read_float(index, offset+1);
	ret[0][2] = 0.0;
	ret[1][0] = read_float(index, offset+2);
	ret[1][1] = read_float(index, offset+3);
	ret[1][2] = 0.0;
	ret[2][0] = read_float(index, offset+4);
	ret[2][1] = read_float(index, offset+5);
	ret[2][2] = 1.0;
	return ret;
}

float calc_spread_method(int index, float dotP)
{
	float PI = 3.14159265359;
	int spread_method = read_int(index, 4);
	return spread_method == 1 ? mod(dotP, 1.0) : 
		(spread_method == 2 ? acos(cos(dotP * PI)) / PI :
			dotP);
}

// Gradient attributes
// 0-1: Common SVG attributes
// 2: Fill type
// 3: Gradient type
// 4: Spread method
// 5-6: Position one (begin when LINEAR, center when RADIAL/FOCAL)
// 7-8: Position two (end when LINEAR, radius when RADIAL, focal when FOCAL)
// 9-10: Pre-calculated normalized direction vector
// 11: Pre-calculated distance
// 12: Radius
// 13: Stop count
// 14-?: Color stops, ordered by offset
vec4 calc_linear_gradient(int index, vec2 uv)
{
	int stop_count = read_int(index, 13);
	float dist = read_float(index, 11);
	vec2 p1 = read_vec2(index, 5);
	vec2 p2 = read_vec2(index, 7);
	vec2 dir = read_vec2(index, 9);
	
	// First, we modify the UV to match our position handles
	uv = (uv - p1) / dist;
	
	// Now we determine the offset of our UV relative to the line segment
	vec2 lhs = uv - p1;
	float dotP = dot(lhs, dir);
	
	// Modify by the spread method
	dotP = calc_spread_method(index, dotP);
	
	if(stop_count == 2)
	{
		return mix(read_vec4(index, 15), read_vec4(index, 20), clamp(dotP, 0.0, 1.0));
	}
	
	// Quick check for if dotP lands out of range
	float min_offset = read_float(index, 14);
	vec4 min_color = read_vec4(index, 15);
	if(dotP <= min_offset)
	{
		return min_color;
	}
	float max_offset = read_float(index, 14+(5*(stop_count-1)));
	vec4 max_color = read_vec4(index, 15+(5*(stop_count-1)));
	if(dotP >= max_offset)
	{
		return max_color;
	}
	
	// We do a binary search of the offsets to get our color range
	int start = 0;
	int end = stop_count-1;
	int mid = start + ((end - start) / 2);
	while((end - start) > 1)
	{
		float midval = read_float(index, 14+(5*mid));
		if(midval < dotP) // Move to right
		{
			start = mid;
		}
		else if(midval > dotP)
		{
			end = mid;
		}
		else
		{
			return read_vec4(index, 15+(5*mid));
		}
		mid = start + ((end - start) / 2);
	}
	// Now, the index distance between start and end is 1
	float startval = read_float(index, 14+(5*start));
	float endval = read_float(index, 14+(5*end));
	
	// Calculate the offset between the two colors
	float t = (dotP - startval) / (endval - startval);
	
	vec4 startcol = read_vec4(index, 15+(5*start));
	vec4 endcol = read_vec4(index, 15+(5*end));
	return mix(startcol, endcol, t);
}

// Fill common attributes
// 0-1: Common SVG attributes
// 2: Fill type
vec4 calc_fill(int index, vec2 uv)
{
	int fill_type = read_int(index, 2);
	return fill_type == 1 ? read_vec4(index, 3) : // FLAT
		(fill_type == 2 ? calc_gradient(index, uv) : // GRADIENT
			vec4(0.0,0.0,0.0,1.0)); // NONE / unimplemented
}

// Rect attributes
// 0-1: SVG common attributes
// 2-7: 3x2 Inverse Transform matrix
// 8-9: Scale
// 10-11: Offset from pivot
// 12: Stack position of fill object (-1 if no fill, which will default to flat black)
vec4 calc_rect(int index, vec2 uv)
{
	//int parent = read_int(index, 1);
	mat3 invr_trns = read_3x2mat(index, 2);
	// TODO: Parent matrix transforming
	uv = (invr_trns * vec3(uv, 1.0)).xy;
	vec2 scale = read_vec2(index, 8);
	vec2 offset = read_vec2(index, 10);
	uv -= (offset / scale);// / get_svg_size());
	if(
		uv.x < 1.0 && uv.x > 0.0 &&
		uv.y < 1.0 && uv.y > 0.0
	)
	{
		int fill_pos = read_int(index, 12);
		if(fill_pos < 0)
		{
			return vec4(0.0,0.0,0.0,1.0);
		}
		else
		{
			return calc_fill(read_int(index, 12), uv);
		}
	}
	else
	{
		return vec4(0.0);
	}
}

// SVG Element Common Attributes
// 0: Element type enum
// 1: Parent index

void fragment()
{
	ALBEDO = vec3(0.0);
	ALPHA = 0.0;
	int elem_count = get_element_count();
	vec2 svg_size = get_svg_size();
	
	for(int i = 0; i < elem_count; i++)
	{
		int heap_index = get_heap_offset(i);
		int element_type = read_int(i, 0);
		//switch(element_type)
		//{
		//	case 1: // RECT
		//		vec4 result = calc_rect(i, UV * svg_size);
		//		ALBEDO = mix(ALBEDO, result.rgb, result.a);
		//		ALPHA = min(ALPHA + result.a, 1.0);
		//		break;
		//	default:
		//		break;
		//}
		vec4 result = (element_type == 1) ? calc_rect(i, UV * svg_size) :  // RECT
			vec4(0.0); // default
		
		ALBEDO = mix(ALBEDO, result.rgb, result.a);
		ALPHA = min(ALPHA + result.a, 1.0);
	}	
	
	ALBEDO = pow(ALBEDO, vec3(2.2)); // Convert to sRGB
}