shader_type spatial;
render_mode unshaded;

uniform sampler2D svg_elements;

// const int HEADER_SIZE = 4; // Only works in Godot 3.2 master branch WHOOPS

// SVG Header
// 0-1: SVG image scale
// 2: Element size
// 3: Number of elements

int get_max_elem_size()
{
	return int(texelFetch(svg_elements, ivec2(2,0), 0).r);
}

int get_element_count()
{
	return int(texelFetch(svg_elements, ivec2(3,0), 0).r);
}

vec2 get_svg_size()
{
	return vec2(
		texelFetch(svg_elements, ivec2(0, 0), 0).r,
		texelFetch(svg_elements, ivec2(1, 0), 0).r
	);
}

float read_float(int index, int offset)
{
	//return texelFetch(svg_elements, ivec2((index*get_max_elem_size())+offset+HEADER_SIZE, 0), 0).r;
	return texelFetch(svg_elements, ivec2((index*get_max_elem_size())+offset+4, 0), 0).r;
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

// Fill common attributes
// 0-1: Common SVG attributes
// 2: Fill type
vec4 calc_fill(int index, vec2 uv)
{
	int fill_type = read_int(index, 2);
	return fill_type == 1 ? read_vec4(index, 3) : // FLAT
			vec4(0.0,0.0,0.0,1.0); // NONE / unimplemented
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
		return calc_fill(read_int(index, 12), uv);
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
	int elem_size = get_max_elem_size();
	int elem_count = get_element_count();
	vec2 svg_size = get_svg_size();
	
	//if(offset.x < 8.0)
	//{
	//	ALBEDO = vec3(1.0,0.0,0.0);
	//	ALPHA = 1.0;
	//}
	
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
		vec4 result = (element_type == 1) ? calc_rect(i, UV * svg_size) :  // RECT
			vec4(0.0); // default
		
		ALBEDO = mix(ALBEDO, result.rgb, result.a);
		ALPHA = min(ALPHA + result.a, 1.0);
	}
}