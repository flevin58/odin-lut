package lut

import "base:runtime"
import "core:fmt"
import "core:math"
import "core:mem"
import "core:os"
import "core:strings"
import stbi "vendor:stb/image"

// Pixels are f32 to make it more precise. We assume RGB (3 channels)
Canvas :: struct {
	width:  int,
	height: int,
	pixels: []RGBColor,
}

canvas_destroy :: proc(pcanvas: ^Canvas) {
	delete(pcanvas.pixels)
	free(pcanvas)
}

canvas_are_equal :: proc(c1, c2: ^Canvas) -> bool {
	return(
		c1.width == c2.width &&
		c1.height == c2.height &&
		len(c1.pixels) == len(c2.pixels) &&
		runtime.memory_equal(c1, c2, c1.width * c1.height) \
	)
}

canvas_get_hald_level :: proc(pcanvas: ^Canvas) -> int {
	level := int(math.cbrt_f32(f32(pcanvas.width)))
	if pcanvas.width != level * level * level do return 0
	return level
}

canvas_create_hald :: proc(level: int) -> ^Canvas {
	pcanvas := new(Canvas)
	pcanvas.width = level * level * level
	pcanvas.height = pcanvas.width
	cube_size := level * level

	// Allocate the buffer
	err: mem.Allocator_Error
	size := pcanvas.width * pcanvas.height
	pcanvas.pixels = make([]RGBColor, cube_size * cube_size * cube_size)
	if err != mem.Allocator_Error.None {
		fmt.eprintln("Error allocating buffer for the canvas")
		free(pcanvas)
		os.exit(1)
	}

	// Set the natural Hald colors
	i := 0
	for b in 0 ..< cube_size {
		for g in 0 ..< cube_size {
			for r in 0 ..< cube_size {
				color := LutColor {
					f32(r) / (f32)(cube_size - 1),
					f32(g) / (f32)(cube_size - 1),
					f32(b) / (f32)(cube_size - 1),
				}
				pcanvas.pixels[i] = color_to_RGB(color)
				i += 1
			}
		}
	}

	// Return the canvas
	return pcanvas
}

canvas_create :: proc(width, height: int, color: RGBColor = BLACK) -> ^Canvas {
	pcanvas := new(Canvas)

	// Allocate the buffer
	err: mem.Allocator_Error
	pcanvas.width = width
	pcanvas.height = height
	size := width * height
	pcanvas.pixels = make([]RGBColor, size)
	if err != mem.Allocator_Error.None {
		fmt.eprintln("Error allocating buffer for the canvas")
		free(pcanvas)
		os.exit(1)
	}

	// Fill with black
	for i in 0 ..< size {
		pcanvas.pixels[i] = color
	}

	// Return the canvas
	return pcanvas
}

canvas_save :: proc(pcanvas: ^Canvas, file_name: string) -> int {
	// The stb library wants a cstring
	c_filename := strings.clone_to_cstring(file_name, context.allocator)
	defer delete(c_filename)

	// Save to png file
	bpp: i32 = size_of(RGBColor) // bytes per pixel (RGB)
	err := stbi.write_png(
		c_filename,
		i32(pcanvas.width),
		i32(pcanvas.height),
		bpp,
		raw_data(pcanvas.pixels),
		i32(pcanvas.width) * bpp,
	)

	// Return eventual error
	return int(err)
}

canvas_load :: proc(file_name: string) -> ^Canvas {
	pcanvas := new(Canvas)

	// The stb library wants a cstring
	c_filename := strings.clone_to_cstring(file_name, context.allocator)
	defer delete(c_filename)

	// Load the png_buffer and sizes
	width, height, chans: i32
	buffer := stbi.load(c_filename, &width, &height, &chans, size_of(RGBColor))
	defer free(buffer)
	size := width * height
	pcanvas.pixels = make([]RGBColor, size)
	pcanvas.width = int(width)
	pcanvas.height = int(height)
	mem.copy(raw_data(pcanvas.pixels), buffer, int(size) * size_of(RGBColor))

	return pcanvas
}

canvas_get_RGBColor_at :: proc(pcanvas: ^Canvas, x, y: int) -> RGBColor {
	i := y * pcanvas.width + x
	return pcanvas.pixels[i]
}

canvas_set_RGBColor_at :: proc(pcanvas: ^Canvas, x, y: int, color: RGBColor) {
	i := y * pcanvas.width + x
	pcanvas.pixels[i] = color
}

canvas_clear :: proc(pcanvas: ^Canvas, color: RGBColor = BLACK) {
	size := pcanvas.width * pcanvas.height
	for i in 0 ..< size {
		pcanvas.pixels[i] = color
	}
}
