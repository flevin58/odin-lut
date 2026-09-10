package lut

import "core:flags/example"
import "core:fmt"
import "core:strconv"
import "core:strings"

LutColor :: #type [3]f32
RGBColor :: #type [3]u8

LBLACK :: LutColor{0, 0, 0}
LWHITE :: LutColor{1, 1, 1}
BLACK :: RGBColor{0, 0, 0}
WHITE :: RGBColor{255, 255, 255}


color_parse :: proc(str: string) -> (color: LutColor, ok: bool) {
	parts, err := strings.fields(str)
	defer delete(parts)
	if err != nil || len(parts) != 3 do return {}, false

	for i in 0 ..< 3 {
		color[i], ok = strconv.parse_f32(parts[i])
		if !ok do return {}, false
	}

	return color, ok
}

color_to_string :: proc(color: LutColor) -> string {
	buf: strings.Builder
	str := fmt.sbprintf(&buf, "%.6f %.6f %.6f", color.r, color.g, color.b)
	return str
}

color_to_RGB :: proc(color: LutColor) -> RGBColor {
	return {u8(color.r * 255), u8(color.g * 255), u8(color.b * 255)}
}

color_from_RGB :: proc(color: RGBColor) -> LutColor {
	return {f32(color.r) / 255.0, f32(color.g) / 255.0, f32(color.b) / 255.0}
}
