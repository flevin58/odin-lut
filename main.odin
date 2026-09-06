package main

import "core:fmt"
import "core:os"
import "lut"

main :: proc() {
	c1 := lut.canvas_create_hald(8)
	defer lut.canvas_destroy(&c1)
	lut.canvas_save(&c1, "hald_8_c1.png")
	pcube := lut.cube_from_canvas(&c1)
	lut.cube_save_to_file(pcube, "pippo.cube")

	c2 := lut.canvas_load("hald_8_c1.png")
	defer lut.canvas_destroy(&c2)
	lut.canvas_save(&c2, "hald_8_c2.png")

	fmt.printfln("Are equal: %v", lut.canvas_are_equal(&c1, &c2))

	pc := lut.cube_from_file("assets/Milo5.cube")
	c3 := lut.cube_to_canvas(pc)
	lut.canvas_save(c3, "assets/Milo5.png")
	// for y in 0 ..< c1.height {
	// 	for x in 0 ..< c1.width {
	// 		fmt.printfln(
	// 			"c1: %d - c2: %d",
	// 			lut.canvas_get_color_at(&c1, x, y),
	// 			lut.canvas_get_color_at(&c2, x, y),
	// 		)
	// 	}
	// }
}
