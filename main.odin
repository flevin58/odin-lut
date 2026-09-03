package main

import "core:fmt"
import "core:os"
import "lut"

main :: proc() {
	if len(os.args) != 2 {
		fmt.eprintln("Missing LUT file to load")
		os.exit(1)
	}
	plut := lut.load_cube(os.args[1])
	defer free(plut)

	lut.save_cube(plut, "assets/pippo.cube")
	lut.create_hald()
}
