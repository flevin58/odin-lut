package main

import "../clut"
import "core:fmt"
import "core:os"
import "core:strconv"

main :: proc() {
	level := 8
	mode: int
	ok: bool
	file_name := "hald.png"

	arg_len := len(os.args)

	if arg_len <= 1 {
		fmt.printfln("Usage %s <FILENAME> <MODE> <LEVEL>", os.args[0])
		fmt.printfln("MODE:")
		fmt.printfln("  0 = Hald CLUT (square image with RGB along XYZ axes)")
		fmt.printfln("  1 = Conventional CLUT (rectangular image with RGB along XYZ axes)")
		os.exit(0)
	}
	file_name = os.args[1]

	if arg_len > 2 {
		mode, ok = strconv.parse_int(os.args[2], 10)
		if mode < 0 || mode > 1 {
			fmt.printfln("Not a valid mode: %s (mode must be 0 or 1)", os.args[2])
			os.exit(1)
		}
	}

	if arg_len > 3 {
		level, ok = strconv.parse_int(os.args[3], 10)
		if level < 1 || level > 16 {
			fmt.printfln("Not a valid level: %s (level must be 16 or lower)", os.args[3])
			os.exit(1)
		}
	}

	fmt.printfln("FILENAME: %s", file_name)
	fmt.printfln("LEVEL:    %u", level)
	fmt.printfln("MODE:     %u", mode)

	cube_size, width, height: int
	data: [^]f32

	switch (mode) {
	case 0:
		cube_size = level * level
		width = level * level * level
		height = width
		data = clut.createHaldClut(cube_size)
	case 1:
		cube_size = level * level
		width = cube_size * cube_size
		height = cube_size
		data = clut.createClut(cube_size, width, height)
	}

	clut.writeOutput(file_name, data, width, height)

	fmt.printfln("Success!")
}
