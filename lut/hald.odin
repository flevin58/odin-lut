package lut

import "core:fmt"
import "core:slice"
import "core:strings"
import stbi "vendor:stb/image"

HALD_PNG :: "assets/hald_identity_8.png"
HALD_TGA :: "assets/hald_identity_8.tga"
HALD_SIZE :: 8
BYTES_PER_PIXEL :: 3
HALD_SQUARE :: HALD_SIZE * HALD_SIZE
MAX_VAL :: f32(HALD_SQUARE - 1)
IMG_DIM :: HALD_SIZE * HALD_SIZE * HALD_SIZE // 8 * 8 * 8 = 512
BUFFER_SIZE :: IMG_DIM * IMG_DIM * BYTES_PER_PIXEL
STRIDE_IN_BYTES :: i32(IMG_DIM * BYTES_PER_PIXEL)

Dimensions :: struct {
	level:       int,
	image_side:  int,
	stride:      int,
	buffer_size: int,
}

get_hald_dimensions :: proc(level: int) -> Dimensions {
	side := level * level * level
	return {level = level, image_side = side, stride = side * 3, buffer_size = side * side}
}

// Sizes and Levels are related: size = level * level * level
VALID_HALD_LEVELS := []int{4, 8, 10, 12, 16}
VALID_HALD_SIZES := []i32{64, 512, 1000, 1728, 4096}

load_cube_from_hald :: proc(filename: string) -> ^Cube {
	c_filename := strings.clone_to_cstring(filename, context.allocator)
	defer delete(c_filename)

	width, height, chans: i32
	bytes := stbi.load(c_filename, &width, &height, &chans, 3)
	index, found := slice.linear_search(VALID_HALD_SIZES, width)
	if !found || width != height || chans != 3 {
		fmt.eprintfln("Bad HALD image: %s (%dx%dx%d)", c_filename, width, height, chans)
		return nil
	}
	return load_cube_from_bytes(bytes, VALID_HALD_LEVELS[index])
}

@(private = "file")
next_table_row :: proc(dims: ^Dimensions, r, g, b: ^int) -> (color: TableRow) {
	color = {
		(f32(r^) / MAX_VAL) * 255.0 + 0.5,
		(f32(g^) / MAX_VAL) * 255.0 + 0.5,
		(f32(b^) / MAX_VAL) * 255.0 + 0.5,
	}
	r^ += 1
	if r^ == dims.image_side {
		g^ += 1
		if g^ == dims.image_side {
			b^ += 1
		}
	}
	return
}

create_neutral_hald :: proc(level: int) {
	// Allocate a buffer for the pixel data
	dims := get_hald_dimensions(level)
	pixels := make([]TableRow, dims.buffer_size)
	defer delete(pixels)

	// Fill the buffer with neutral colors
	r, g, b: int
	for i in 0 ..< dims.buffer_size {
		pixels[i] = next_table_row(&dims, &r, &g, &b)
	}
	// index := 0
	// for r := 0; r < dims.image_side; r += 1 {
	// 	for g := 0; g < dims.image_side; g += 1 {
	// 		for b := 0; b < dims.image_side; b += 1 {
	// 			rv := u8((f32(r) / MAX_VAL) * 255.0 + 0.5)
	// 			gv := u8((f32(g) / MAX_VAL) * 255.0 + 0.5)
	// 			bv := u8((f32(b) / MAX_VAL) * 255.0 + 0.5)

	// 			pixels[index + 0] = rv
	// 			pixels[index + 1] = gv
	// 			pixels[index + 2] = bv
	// 			index += 3
	// 		}
	// 	}
	// }

	err := stbi.write_png(
		"output.png",
		i32(dims.image_side),
		i32(dims.image_side),
		BYTES_PER_PIXEL,
		raw_data(pixels),
		i32(dims.stride),
	)

	if err != 0 {
		fmt.printfln("HALD image successfully created: %s (%dx%d)", HALD_PNG, IMG_DIM, IMG_DIM)
	} else {
		fmt.println("Error creating the HALD image.")
	}
}
