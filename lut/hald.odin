package lut

import "core:fmt"
import "vendor:stb/image"

HALD_PNG :: cstring("assets/hald_identity_8.png")
HALD_SIZE :: 8
BYTES_PER_PIXEL :: 3
HALD_SQUARE :: HALD_SIZE * HALD_SIZE
MAX_VAL :: f32(HALD_SQUARE - 1)
IMG_DIM :: HALD_SIZE * HALD_SIZE * HALD_SIZE // 8 * 8 * 8 = 512
BUFFER_SIZE :: IMG_DIM * IMG_DIM * BYTES_PER_PIXEL
STRIDE_IN_BYTES :: i32(IMG_DIM * BYTES_PER_PIXEL)

create_hald :: proc() {
	pixels := make([]u8, BUFFER_SIZE)
	defer delete(pixels)

	index := 0
	for r := 0; r < HALD_SQUARE; r += 1 {
		for g := 0; g < HALD_SQUARE; g += 1 {
			for b := 0; b < HALD_SQUARE; b += 1 {
				rv := u8((f32(r) / MAX_VAL) * 255.0 + 0.5)
				gv := u8((f32(g) / MAX_VAL) * 255.0 + 0.5)
				bv := u8((f32(b) / MAX_VAL) * 255.0 + 0.5)

				pixels[index + 0] = rv
				pixels[index + 1] = gv
				pixels[index + 2] = bv
				index += 3
			}
		}
	}

	success := image.write_png(
		HALD_PNG,
		IMG_DIM,
		IMG_DIM,
		BYTES_PER_PIXEL,
		raw_data(pixels),
		STRIDE_IN_BYTES,
	)

	if success != 0 {
		fmt.printfln("HALD image successfully created: %s (%dx%d)", HALD_PNG, IMG_DIM, IMG_DIM)
	} else {
		fmt.println("Error creating the HALD image.")
	}
}
