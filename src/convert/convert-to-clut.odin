package main

import "../clut"
import "core:fmt"
import "core:os"
import "core:strconv"

main :: proc() {

	level := 8
	ok: bool
	arg_len := len(os.args)

	if arg_len <= 2 {
		fmt.printfln("Usage %s <INPUT> <OUTPUT> <LEVEL>", os.args[0])
		os.exit(0)
	}

	input_file := os.args[1]
	output_file := os.args[2]

	if arg_len > 3 {
		level, ok = strconv.parse_int(os.args[3], 10)
		if level < 1 || level > 16 {
			fmt.printfln("Not a valid level: %s (level must be 16 or lower)", os.args[3])
			os.exit(1)
		}
	}

	fmt.printfln("INPUT:    %s", input_file)
	fmt.printfln("OUTPUT:   %s", output_file)
	fmt.printfln("LEVEL:    %u", level)

	cube_size := level * level
	data := clut.readClut(input_file)

	width := level * level * level * level
	height := level * level

	clut.writeOutput(output_file, data, width, height)

	fmt.printf("Success!")
}
