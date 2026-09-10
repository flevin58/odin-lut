package lut

// =================[TESTING]===================== \\

import "core:fmt"
import "core:testing"

@(test)
test_color_parse :: proc(t: ^testing.T) {
	color, ok := color_parse("0.5 0.45 0.333")
	testing.expect(t, ok == true)
	testing.expect(t, color == {0.5, 0.45, 0.333})
}

@(test)
test_color_to_string :: proc(t: ^testing.T) {
	color := LutColor{0.6, 0.127, 0.758}
	expected := "0.600000 0.127000 0.758000"
	color_str := color_to_string(color)
	defer delete(color_str)
	testing.expect(t, color_str == expected)
}
