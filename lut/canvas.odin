package lut

import "base:runtime"
import "core:fmt"
import "core:math"
import "core:os"
import "core:strings"
import stbi "vendor:stb/image"

Color :: #type [3]u8

// Pixels are f32 to make it more precise. We assume RGB (3 channels)
Canvas :: struct {
	width:  int,
	height: int,
	pixels: [^]f32,
}

BLACK :: Color{0, 0, 0}

canvas_destroy :: proc(pcanvas: ^Canvas) {
	free(pcanvas.pixels)
}

canvas_are_equal :: proc(c1, c2: ^Canvas) -> bool {
	if c1.width != c2.width || c1.height != c2.height {
		return false
	}
	// Avoid round errors checking u8 converted colors
	for i in 0 ..< c1.width * c1.height * 3 {
		if u8(c1.pixels[i] * 255) != u8(c2.pixels[i] * 255) {
			return false
		}
	}
	return true
}

canvas_create_clut :: proc(level: int) -> Canvas {
	cube_size := level * level
	width := cube_size * cube_size
	height := cube_size

	// Allocate the buffer
	size := width * height * 3
	buffer, err := make([^]f32, size)
	if err != nil {
		fmt.eprintln("Error allocating buffer for the canvas")
		os.exit(1)
	}

	// Set the natural Clut colors
	i := 0
	for g in 0 ..< cube_size {
		for b in 0 ..< cube_size {
			for r in 0 ..< cube_size {
				buffer[i + 0] = f32(r) / (f32)(cube_size - 1)
				buffer[i + 1] = f32(g) / (f32)(cube_size - 1)
				buffer[i + 2] = f32(b) / (f32)(cube_size - 1)
				i += 3
			}
		}
	}

	// Return the canvas
	return {width = width, height = height, pixels = buffer}
}

canvas_get_hald_level :: proc(pcanvas: ^Canvas) -> int {
	flevel := math.cbrt_f32(f32(pcanvas.width))
	level := int(flevel)
	if pcanvas.width != level * level * level do return 0
	return level
}

canvas_create_hald :: proc(level: int) -> Canvas {
	width := level * level * level
	height := width
	cube_size := level * level

	// Allocate the buffer
	size := width * height * 3
	buffer, err := make([^]f32, size)
	if err != nil {
		fmt.eprintln("Error allocating buffer for the canvas")
		os.exit(1)
	}

	// Set the natural Hald colors
	i := 0
	for b in 0 ..< cube_size {
		for g in 0 ..< cube_size {
			for r in 0 ..< cube_size {
				buffer[i + 0] = f32(r) / (f32)(cube_size - 1)
				buffer[i + 1] = f32(g) / (f32)(cube_size - 1)
				buffer[i + 2] = f32(b) / (f32)(cube_size - 1)
				i += 3
			}
		}
	}

	// Return the canvas
	return {width = width, height = height, pixels = buffer}
}

canvas_create :: proc(width, height: int, color: Color = BLACK) -> Canvas {
	// Allocate the buffer
	size := width * height * 3
	buffer, err := make([^]f32, size)
	if err != nil {
		fmt.eprintln("Error allocating buffer for the canvas")
		os.exit(1)
	}

	// Fill with given color
	for i := 0; i < size; i += 3 {
		buffer[i + 0] = f32(color.r) / 255
		buffer[i + 1] = f32(color.g) / 255
		buffer[i + 2] = f32(color.b) / 255
	}

	// Return the canvas
	return {width = width, height = height, pixels = buffer}
}

canvas_save :: proc(pcanvas: ^Canvas, file_name: string) -> int {
	// The stb library wants a cstring
	c_filename := strings.clone_to_cstring(file_name, context.allocator)
	defer delete(c_filename)

	// Convert the f32 data to 8bit png data
	size := pcanvas.width * pcanvas.height * 3
	png_buffer := make([^]u8, size)
	defer free(png_buffer)
	for i in 0 ..< size {
		png_buffer[i] = u8(pcanvas.pixels[i] * 255)
	}

	// Save to png file
	err := stbi.write_png(
		c_filename,
		i32(pcanvas.width),
		i32(pcanvas.height),
		3, // bytes per pixel
		png_buffer,
		i32(pcanvas.width * 3),
	)

	// Return eventual error
	return int(err)
}

canvas_load :: proc(file_name: string) -> (c: Canvas) {
	// The stb library wants a cstring
	c_filename := strings.clone_to_cstring(file_name, context.allocator)
	defer delete(c_filename)

	// Load the png_buffer and sizes
	width, height, chans: i32
	png_buffer := stbi.load(c_filename, &width, &height, &chans, 3)
	defer free(png_buffer)

	// Transform the buffer into f32 values
	size := width * height * 3
	c.pixels = make([^]f32, size)
	c.width = int(width)
	c.height = int(height)
	for i in 0 ..< size {
		c.pixels[i] = f32(png_buffer[i]) / 255
	}

	return
}

canvas_get_color_at :: proc(pcanvas: ^Canvas, x, y: int) -> Color {
	i := y * pcanvas.width + x
	return {
		u8(pcanvas.pixels[i + 0] * 255),
		u8(pcanvas.pixels[i + 1] * 255),
		u8(pcanvas.pixels[i + 2] * 255),
	}
}

canvas_set_color_at :: proc(pcanvas: ^Canvas, x, y: int, color: Color) {
	i := y * pcanvas.width + x
	pcanvas.pixels[i + 0] = f32(color.r) / 255
	pcanvas.pixels[i + 1] = f32(color.g) / 255
	pcanvas.pixels[i + 2] = f32(color.b) / 255
}

canvas_clear :: proc(pcanvas: ^Canvas, color: Color = BLACK) {
	for i := 0; i < pcanvas.width * pcanvas.height * 3; i += 3 {
		pcanvas.pixels[i + 0] = f32(color.r) / 255
		pcanvas.pixels[i + 1] = f32(color.g) / 255
		pcanvas.pixels[i + 2] = f32(color.b) / 255
	}
}
