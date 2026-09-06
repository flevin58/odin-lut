package clut

import "core:fmt"
import "core:strings"
import stbi "vendor:stb/image"

createHaldClut :: proc(cube_size: int) -> (data: [^]f32) {
	fmt.printfln("Creating Hald CLUT with %d pixel blocks", cube_size)

	// Hald CLUT
	data = make([^]f32, cube_size * cube_size * cube_size * 3)
	red, blue, green: int
	i: int
	for blue in 0 ..< cube_size {
		for green in 0 ..< cube_size {
			for red in 0 ..< cube_size {
				data[i + 0] = f32(red) / (f32)(cube_size - 1)
				data[i + 1] = f32(green) / (f32)(cube_size - 1)
				data[i + 2] = f32(blue) / (f32)(cube_size - 1)
				i += 3
			}
		}
	}
	return
}

createClut :: proc(cube_size, width, height: int) -> (data: [^]f32) {
	fmt.printfln("Creating conventional CLUT at %dx%d pixels", width, height)

	// Conventional CLUT
	data = make([^]f32, width * height * 3)
	i, red, blue, green: int
	for green in 0 ..< cube_size {
		for blue in 0 ..< cube_size {
			for red in 0 ..< cube_size {
				data[i + 0] = f32(red) / (f32)(cube_size - 1)
				data[i + 1] = f32(green) / (f32)(cube_size - 1)
				data[i + 2] = f32(blue) / (f32)(cube_size - 1)
				i += 3
			}
		}
	}
	return
}

readClut :: proc(file_name: string) -> (data: [^]f32) {
	c_filename := strings.clone_to_cstring(file_name, context.allocator)
	defer delete(c_filename)

	width, height, chans: i32
	bytes := stbi.load(c_filename, &width, &height, &chans, 3)

	fmt.printfln("Reading %dx%d image...", width, height)

	data = make([^]f32, width * height * 3)
	i: int

	for y in 0 ..< height {
		for x in 0 ..< width {
			data[i + 0] = f32(bytes[i + 0]) / 255.0 // red
			data[i + 1] = f32(bytes[i + 1]) / 255.0 // green
			data[i + 2] = f32(bytes[i + 2]) / 255.0 // blue
		}
	}

	fmt.printfln("Read %u pixels", width * height * 3)

	return
}

writeOutput :: proc(file_name: string, data: [^]f32, width, height: int) {
	fmt.printfln("Mapping %dx%d pixels for output...", width, height)
	out_data := make([^]u8, width * height * 3)
	i: int
	for y in 0 ..< height {
		for x in 0 ..< width {
			out_data[i + 0] = u8(data[i + 0] * 255.0) // red
			out_data[i + 1] = u8(data[i + 1] * 255.0) // green
			out_data[i + 2] = u8(data[i + 2] * 255.0) // blue
			i += 3
		}
	}
	fmt.printfln("Writing PNG...")
	write_png_file(file_name, width, height, out_data)
}

write_png_file :: proc(file_name: string, width, height: int, data: [^]u8) {
	c_filename := strings.clone_to_cstring(file_name, context.allocator)
	defer delete(c_filename)

	err := stbi.write_png(c_filename, i32(width), i32(height), 3, data, i32(width * 3))
}
