package lut

import "core:fmt"
import "core:os"
import "core:strconv"
import "core:strings"

MAX_LINE_LEN :: 250
MIN_SIZE_1D :: 2
MAX_SIZE_1D :: 65536
MIN_SIZE_3D :: 2
MAX_SIZE_3D :: 256

TableRow :: #type [3]f32

Cube :: struct {
	title:      string,
	domain_min: TableRow,
	domain_max: TableRow,
	size_1d:    int,
	data_1d:    [^]f32,
	size_3d:    int,
	data_3d:    [^]f32,
}

cube_from_canvas :: proc(pcanvas: ^Canvas) -> (cube: ^Cube) {
	cube = new(Cube)
	level := canvas_get_hald_level(pcanvas)
	if level == 0 do return nil

	cube.domain_min = {0, 0, 0}
	cube.domain_max = {1, 1, 1}
	cube.size_3d = level
	bufsize := level * level * level * 3
	cube.data_3d = make([^]f32, bufsize)
	index := 0
	for i := 0; i < bufsize; i += 1 {
		cube.data_3d[i] = pcanvas.pixels[i]
	}
	return
}

cube_to_canvas :: proc(pcube: ^Cube) -> (pcanvas: ^Canvas) {
	level := pcube.size_3d
	if level == 0 do return nil
	width := level * level * level
	height := width
	cube_size := level * level
	pcanvas = new(Canvas)

	// Allocate the buffer
	size := width * height * 3
	buffer, err := make([^]f32, size)
	if err != nil {
		fmt.eprintln("Error allocating buffer for the canvas")
		os.exit(1)
	}

	// Copy the Cube colors
	// i := 0
	// for b in 0 ..< cube_size {
	// 	for g in 0 ..< cube_size {
	// 		for r in 0 ..< cube_size {
	// 			buffer[i + 0] = pcube.data_3d
	// 			buffer[i + 1] = f32(g) / (f32)(cube_size - 1)
	// 			buffer[i + 2] = f32(b) / (f32)(cube_size - 1)
	// 			i += 3
	// 		}
	// 	}
	// }

	// Return the canvas
	pcanvas.width = width
	pcanvas.height = height
	pcanvas.pixels = pcube.data_3d
	return
}

cube_destroy :: proc(cube: ^Cube) {
	if cube == nil do return
	if cube.size_1d > 0 do free(cube.data_1d)
	if cube.size_3d > 0 do free(cube.data_3d)
	free(cube)
}

cube_from_file :: proc(filepath: string) -> (cube: ^Cube) {
	// Read the file into memory
	data, err := os.read_entire_file(filepath, context.allocator)
	if err != nil {
		fmt.println("Failed to read the file")
		return nil
	}
	file_contents := string(data)
	defer delete(data, context.allocator)

	cube = new(Cube)
	cube.domain_min = {0, 0, 0}
	cube.domain_max = {1, 1, 1}
	linenum := 1
	r, g, b: int
	n: int
	for line in strings.split_lines_iterator(&file_contents) {
		ok: bool
		if len(line) == 0 || strings.starts_with(line, "#") do continue
		if len(line) > MAX_LINE_LEN {
			fmt.println("Error at line %d: line too long", linenum)
			free(cube)
			return nil
		}

		fields := strings.fields(line)
		defer delete(fields)

		switch fields[0] {
		case "TITLE":
			cube.title = strings.clone(line[7:len(line) - 1])
		case "LUT_3D_SIZE":
			value, ok := strconv.parse_int(fields[1], 10)
			if !ok || value < MIN_SIZE_3D || value > MAX_SIZE_3D {
				fmt.println("Error at line %d: bad lut size", linenum)
				free(cube)
				return nil
			}
			cube.size_3d = value
			cube.data_3d = make([^]f32, value * value * value * 3)
		case "LUT_1D_SIZE":
			value, ok := strconv.parse_int(fields[1], 10)
			if !ok || value < MIN_SIZE_1D || value > MAX_SIZE_1D {
				fmt.println("Error at line %d: bad lut size", linenum)
				free(cube)
				return nil
			}
			cube.size_1d = value
			cube.data_1d = make([^]f32, value * 3)
			if err != nil {
				fmt.println("Error at line %d: not enough memory to allocate the LUT1D", linenum)
				free(cube)
				return nil
			}
		case "DOMAIN_MIN":
			for i in 1 ..= 3 {
				cube.domain_min[i - 1], ok = strconv.parse_f32(fields[i])
				if !ok {
					fmt.println("Error at line %d: bad DOMAIN_MIN value", linenum)
					free(cube)
					return nil
				}
			}
		case "DOMAIN_MAX":
			for i in 1 ..= 3 {
				cube.domain_max[i - 1], ok = strconv.parse_f32(fields[i])
				if !ok {
					fmt.println("Error at line %d: bad DOMAIN_MAX value", linenum)
					free(cube)
					return nil
				}
			}
		case:
			// Here we process the data. We expect r g b values per line
			if len(fields) != 3 {
				fmt.println("Error at line %d: bad table data", linenum)
				free(cube)
				return nil
			}
			data_row: TableRow
			for i in 0 ..< 3 {
				data_row[i], ok = strconv.parse_f32(fields[i])
				if !ok {
					fmt.println("Error at line %d: bad R G B value", linenum)
					free(cube)
					return nil
				}
			}
			if cube.size_1d > 0 {
				cube.data_1d[n + 0] = data_row.r
				cube.data_1d[n + 1] = data_row.g
				cube.data_1d[n + 2] = data_row.b
				n += 3
			} else if cube.size_3d > 0 {
				n = r + g * cube.size_3d + b * cube.size_3d * cube.size_3d
				cube.data_3d[n + 0] = data_row.r
				cube.data_3d[n + 1] = data_row.g
				cube.data_3d[n + 2] = data_row.b
				r += 1
				if r == cube.size_3d {
					r = 0
					g += 1
				}
				if g == cube.size_3d {
					g = 0
					b += 1
				}
			}
		}
		linenum += 1
	}
	return
}

cube_save_to_file :: proc(cube: ^Cube, filename: string) {
	f, err := os.create(filename)
	defer os.close(f)

	if err != nil {
		fmt.println("Could not create file '%s'", filename)
		return
	}
	fmt.fprintfln(f, "TITLE %q", cube.title)
	if cube.size_1d > 0 {
		fmt.fprintfln(f, "LUT_1D_SIZE %d", cube.size_1d)
		fmt.fprintfln(
			f,
			"DOMAIN_MIN %f %f %f",
			cube.domain_min[0],
			cube.domain_min[1],
			cube.domain_min[2],
		)
		fmt.fprintfln(
			f,
			"DOMAIN_MAX %f %f %f",
			cube.domain_max[0],
			cube.domain_max[1],
			cube.domain_max[2],
		)
		for i := 0; i < cube.size_1d; i += 3 {
			fmt.fprintfln(
				f,
				"%.6f %.6f %.6f",
				cube.data_1d[i + 0],
				cube.data_1d[i + 1],
				cube.data_1d[i + 2],
			)
		}
		return
	}
	if cube.size_3d > 0 {
		fmt.fprintfln(f, "LUT_3D_SIZE %d", cube.size_3d)
		fmt.fprintfln(
			f,
			"DOMAIN_MIN %f %f %f",
			cube.domain_min[0],
			cube.domain_min[1],
			cube.domain_min[2],
		)
		fmt.fprintfln(
			f,
			"DOMAIN_MAX %f %f %f",
			cube.domain_max[0],
			cube.domain_max[1],
			cube.domain_max[2],
		)
		for b in 0 ..< cube.size_3d {
			for g in 0 ..< cube.size_3d {
				for r in 0 ..< cube.size_3d {
					n := r + g * cube.size_3d + b * cube.size_3d * cube.size_3d
					fmt.fprintfln(
						f,
						"%.6f %.6f %.6f",
						cube.data_3d[n + 0],
						cube.data_3d[n + 1],
						cube.data_3d[n + 2],
					)
				}
			}
		}
		return
	}
}

cube_to_png :: proc(pcube: ^Cube, filename: string) {
}
