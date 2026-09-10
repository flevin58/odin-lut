#+feature using-stmt
package main

import "base:runtime"
import "core:fmt"
import "core:os"
import "lut"

main :: proc() {
	hald := lut.canvas_create_hald(8)
	defer lut.canvas_destroy(hald)
	lut.canvas_save(hald, "assets/hald.png")
}
