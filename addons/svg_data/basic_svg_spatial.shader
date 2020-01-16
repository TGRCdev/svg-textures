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

vec4 calc_gradient_final(int index, float offset)
{
	// Quick check for if offset lands out of range
	float min_offset = read_float(index, 14);
	vec4 min_color = read_vec4(index, 15);
	if(offset <= min_offset)
	{
		return min_color;
	}
	int stop_count = read_int(index, 13);
	float max_offset = read_float(index, 14+(5*(stop_count-1)));
	vec4 max_color = read_vec4(index, 15+(5*(stop_count-1)));
	if(offset >= max_offset)
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
		if(midval < offset) // Move to right
		{
			start = mid;
		}
		else if(midval > offset)
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
	float t = (offset - startval) / (endval - startval);
	
	//return mix(vec4(1.0,0.0,0.0,1.0), vec4(0.0,1.0,0.0,1.0), -1.0);
	
	vec4 startcol = read_vec4(index, 15+(5*start));
	vec4 endcol = read_vec4(index, 15+(5*end));
	//return endcol;
	return mix(startcol, endcol, t);
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
	
	return calc_gradient_final(index, dotP);
}

vec4 calc_radial_gradient(int index, vec2 uv)
{
	int stop_count = read_int(index, 13);
	vec2 center = read_vec2(index, 5);
	vec2 focal = read_vec2(index, 7);
	float radius = read_float(index, 12);
	float dist = read_float(index, 11);
	
	float offset = distance(center, uv) / radius;
	
	offset = calc_spread_method(index, offset);
	return calc_gradient_final(index, offset);
}

vec4 calc_gradient(int index, vec2 uv)
{
	if(index < 0)
	{
		return vec4(0.0,0.0,0.0,1.0);
	}
	int gradient_type = read_int(index, 3);
	int stop_count = read_int(index, 13);
	if (stop_count == 0) // No color stops defined
	{
		return vec4(0.0,0.0,0.0,1.0);
	}
	else if(stop_count == 1) // Only one color, no lerp
	{
		return read_vec4(index, 15);
	}
	float dist = read_float(index, 11);
	if(dist == 0.0)
	{
		return read_vec4(index, 15);
	}
	return gradient_type == 0 ? calc_linear_gradient(index, uv) :
		(gradient_type == 1 ? calc_radial_gradient(index, uv) :
		vec4(0.0,0.0,0.0,1.0));
}

// Fill common attributes
// 0-1: Common SVG attributes
// 2: Fill type
vec4 calc_fill(int index, vec2 uv)
{
	if(index < 0)
	{
		return vec4(0.0,0.0,0.0,1.0);
	}
	int fill_type = read_int(index, 2);
	return fill_type == 1 ? read_vec4(index, 3) : // FLAT
		(fill_type == 2 ? calc_gradient(index, uv) : // GRADIENT
			vec4(0.0,0.0,0.0,1.0)); // NONE / unimplemented
}

// Stroke attributes
// 0-1: Common SVG attributes
// 2: Width
// 3: Fill stack position
// 4: Dash array size
// 5: Pre-calculated sum of dash array
// 6-?: Dash array data
vec4 calc_stroke(int index, vec2 uv, float dist, float offset)
{
	// dist is the distance of the fragment from the closest border on the shape
	// offset is the x position on the unwrapped form of the stroke
	if(index < 0)
	{
		return vec4(0.0);
	}
	
	float width = read_float(index, 2);
	if(dist > width)
	{
		return vec4(0.0);
	}
	
	int fill_index = read_int(index, 3);
	int dash_count = read_int(index, 4);
	if(dash_count <= 0)
	{
		return calc_fill(fill_index, uv);
	}
	
	float dash_sum = read_float(index, 5);
	if(dash_sum <= 0.0)
	{
		return calc_fill(fill_index, uv);
	}
	
	float dash_loc = mod(offset, dash_sum);
	int i = 0;
	bool visib = true;
	float dash_len = read_float(index, 6+i);
	while(dash_len < dash_loc)
	{
		dash_loc -= dash_len;
		i += 1;
		if(i == dash_count)
		{
			i = 0;
		}
		visib = !visib;
	}
	if(visib)
	{
		return calc_fill(fill_index, uv);
	}
	else
	{
		return vec4(0.0);
	}
}

// Ellipse attributes
// 0-1: Common SVG attributes
// 2: Shape type
// 3-8: 3x2 Inverse Transform matrix
// 9: Stack position of fill object (-1 if no fill, which will default to flat black)
// 10: Stack position of stroke object (-1 if no stroke)
vec4 calc_ellipse(int index, vec2 uv)
{
	if(index < 0)
	{
		return vec4(0.0);
	}
	
	vec4 result = vec4(0.0);
	if(distance(uv+vec2(0.5,0.5), vec2(0.5,0.5)) < 0.5)
	{
		int fill_pos = read_int(index, 9);
		result = calc_fill(fill_pos, uv);
	}
	
	// TODO: Handle stroke
	
	return result;
}

// Rect attributes
// 0-1: Common SVG attributes
// 2: Shape type
// 3-8: 3x2 Inverse Transform matrix
// 9: Stack position of fill object (-1 if no fill, which will default to flat black)
// 10: Stack position of stroke object (-1 if no stroke)
// 11-12: Corner radii
vec4 calc_rect(int index, vec2 uv)
{
	vec4 result = vec4(0.0);
	if(
		uv.x < 1.0 && uv.x > 0.0 &&
		uv.y < 1.0 && uv.y > 0.0
	)
	{
		vec2 corner_radii = read_vec2(index, 11);
		int fill_pos = read_int(index, 9);
		if(corner_radii.x > 0.0 && corner_radii.y > 0.0)
		{
			vec2 circ_uv = uv;
			if(circ_uv.x > 0.5)
			{
				circ_uv.x = 1.0 - circ_uv.x;
			}
			if(circ_uv.y > 0.5)
			{
				circ_uv.y = 1.0 - circ_uv.y;
			}
			if(circ_uv.x < corner_radii.x && circ_uv.y < corner_radii.y)
			{
				float p = (pow(circ_uv.x - corner_radii.x, 2) / pow(corner_radii.x, 2)) + (pow(circ_uv.y - corner_radii.y, 2) / pow(corner_radii.y, 2));
				if(p <= 1.0)
				{
					return calc_fill(fill_pos, uv);
				}
			}
			else
			{
				return calc_fill(fill_pos, uv);
			}
		}
		else
		{
			result = calc_fill(fill_pos, uv);
		}
	}
	
	// TODO: Calculate stroke
	
	return result;
}

// Shape attributes
// 0-1: Common SVG attributes
// 2: Shape type
// 3-8: 3x2 Inverse Transform matrix
// 9: Stack position of fill object (-1 if no fill, which will default to flat black)
// 10: Stack position of stroke object (-1 if no stroke)
vec4 calc_shape(int index, vec2 uv)
{
	int shape_type = read_int(index, 2);
	//int parent = read_int(index, 1);
	mat3 invr_trns = read_3x2mat(index, 3);
	// TODO: Parent matrix transforming
	uv = (invr_trns * vec3(uv, 1.0)).xy;
	
	return shape_type == 1 ? calc_rect(index, uv) : // RECT
		(shape_type == 2 ? calc_ellipse(index, uv) : // ELLIPSE
			vec4(0.0)); // UNHANDLED
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
		vec4 result = (element_type == 1) ? calc_shape(i, UV * svg_size) :  // SHAPE
			vec4(0.0); // default
		
		ALBEDO = mix(ALBEDO, result.rgb, result.a);
		ALPHA = min(ALPHA + result.a, 1.0);
	}	
	
	ALBEDO = pow(ALBEDO, vec3(2.2)); // Convert to sRGB
}