package main

import "core:fmt"
import "core:os"
import "lut"

main :: proc() {
	// if len(os.args) != 2 {
	// 	fmt.eprintln("Missing LUT file to load")
	// 	os.exit(1)
	// }
	// plut := lut.load_cube(os.args[1])
	// defer free(plut)

	// lut.save_cube(plut, "assets/pippo.cube")
	lut.create_neutral_hald(10)

	// phald := lut.load_from_hald("assets/hald_identity_8.png")
	// defer free(phald)
	// lut.save_cube_to_file(phald, "assets/hald_identity_8_bis.cube")
	// plut := lut.load_cube_from_file("assets/hald_identity_8_bis.cube")
	// defer free(plut)
	// lut.save_cube_to_png(plut, "assets/hald_identity_8_bis.png")
}
