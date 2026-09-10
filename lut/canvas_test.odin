package lut

// =================[TESTING]===================== \\

import "base:runtime"
import "core:fmt"
import "core:testing"

@(test)
test_canvas_create :: proc(t: ^testing.T) {
	canvas := canvas_create(5, 5)
	defer canvas_destroy(canvas)
	testing.expect(t, canvas.width == 5)
	testing.expect(t, canvas.height == 5)
	for i in 0 ..< 25 {
		testing.expect(t, canvas.pixels[i] == BLACK)
	}
}

@(test)
test_canvas_clear :: proc(t: ^testing.T) {
	canvas := canvas_create(5, 5)
	defer canvas_destroy(canvas)
	canvas_clear(canvas, WHITE)
	for i in 0 ..< 25 {
		testing.expect(t, canvas.pixels[i] == WHITE)
	}
}

@(test)
test_canvas_get_hald_level :: proc(t: ^testing.T) {
	canvas := canvas_create(512, 512)
	defer canvas_destroy(canvas)
	level := canvas_get_hald_level(canvas)
	testing.expect(t, level == 8)
}

@(test)
test_canvas_are_equal :: proc(t: ^testing.T) {
	canvas := canvas_create(2, 2, {18, 42, 69})
	defer canvas_destroy(canvas)
	expected_canvas := &Canvas{2, 2, {{18, 42, 69}, {18, 42, 69}, {18, 42, 69}, {18, 42, 69}}}
	result := canvas_are_equal(canvas, expected_canvas)
	testing.expect(t, result)
}
