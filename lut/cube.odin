package lut

import "core:fmt"
import "core:os"
import "core:slice"
import "core:strconv"
import "core:strings"
import stbi "vendor:stb/image"

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
	data_1d:    []TableRow,
	size_3d:    int,
	data_3d:    []TableRow,
}

destroy_cube :: proc(cube: ^Cube) {
	if cube == nil do return
	if cube.size_1d > 0 do delete(cube.data_1d)
	if cube.size_3d > 0 do delete(cube.data_3d)
	free(cube)
}

load_cube_from_bytes :: proc(buffer: [^]u8, size: int) -> ^Cube {
	lut := new(Cube)
	lut.domain_min = {0, 0, 0}
	lut.domain_max = {1, 1, 1}
	lut.size_3d = size
	bufsize := size * size * size
	lut.data_3d = make([]TableRow, bufsize)
	index := 0
	for i := 0; i < bufsize * size_of(TableRow); i += 3 {
		rf := (f32(buffer[i + 0]) / MAX_VAL) * 255.0 + 0.5
		gf := (f32(buffer[i + 1]) / MAX_VAL) * 255.0 + 0.5
		bf := (f32(buffer[i + 2]) / MAX_VAL) * 255.0 + 0.5
		data_row := TableRow{rf, gf, bf}
		lut.data_3d[index] = data_row
	}
	return lut
}

load_cube_from_file :: proc(filepath: string) -> ^Cube {
	// Read the file into memory
	data, err := os.read_entire_file(filepath, context.allocator)
	if err != nil {
		fmt.println("Failed to read the file")
		return nil
	}
	file_contents := string(data)
	defer delete(data, context.allocator)

	lut := new(Cube)
	lut.domain_min = {0, 0, 0}
	lut.domain_max = {1, 1, 1}
	linenum := 1
	r, g, b: int
	n: int
	for line in strings.split_lines_iterator(&file_contents) {
		ok: bool
		if len(line) == 0 || strings.starts_with(line, "#") do continue
		if len(line) > MAX_LINE_LEN {
			fmt.println("Error at line %d: line too long", linenum)
			free(lut)
			return nil
		}

		fields := strings.fields(line)
		defer delete(fields)

		switch fields[0] {
		case "TITLE":
			lut.title = strings.clone(line[7:len(line) - 1])
		case "LUT_3D_SIZE":
			value, ok := strconv.parse_int(fields[1], 10)
			if !ok || value < MIN_SIZE_3D || value > MAX_SIZE_3D {
				fmt.println("Error at line %d: bad lut size", linenum)
				free(lut)
				return nil
			}
			lut.size_3d = value
			lut.data_3d = make([]TableRow, value * value * value)
		case "LUT_1D_SIZE":
			value, ok := strconv.parse_int(fields[1], 10)
			if !ok || value < MIN_SIZE_1D || value > MAX_SIZE_1D {
				fmt.println("Error at line %d: bad lut size", linenum)
				free(lut)
				return nil
			}
			lut.size_1d = value
			lut.data_1d = make([]TableRow, value)
			if err != nil {
				fmt.println("Error at line %d: not enough memory to allocate the LUT1D", linenum)
				free(lut)
				return nil
			}
		case "DOMAIN_MIN":
			for i in 1 ..= 3 {
				lut.domain_min[i - 1], ok = strconv.parse_f32(fields[i])
				if !ok {
					fmt.println("Error at line %d: bad DOMAIN_MIN value", linenum)
					free(lut)
					return nil
				}
			}
		case "DOMAIN_MAX":
			for i in 1 ..= 3 {
				lut.domain_max[i - 1], ok = strconv.parse_f32(fields[i])
				if !ok {
					fmt.println("Error at line %d: bad DOMAIN_MAX value", linenum)
					free(lut)
					return nil
				}
			}
		case:
			// Here we process the data. We expect r g b values per line
			if len(fields) != 3 {
				fmt.println("Error at line %d: bad table data", linenum)
				free(lut)
				return nil
			}
			data_row: TableRow
			for i in 0 ..< 3 {
				data_row[i], ok = strconv.parse_f32(fields[i])
				if !ok {
					fmt.println("Error at line %d: bad R G B value", linenum)
					free(lut)
					return nil
				}
			}
			if lut.size_1d > 0 {
				lut.data_1d[n] = data_row
				n += 1
			} else if lut.size_3d > 0 {
				n = r + g * lut.size_3d + b * lut.size_3d * lut.size_3d
				lut.data_3d[n] = data_row
				r += 1
				if r == lut.size_3d {
					r = 0
					g += 1
				}
				if g == lut.size_3d {
					g = 0
					b += 1
				}
			}
		}
		linenum += 1
	}
	return lut
}

save_cube_to_file :: proc(lut: ^Cube, filename: string) {
	f, err := os.create(filename)
	defer os.close(f)

	if err != nil {
		fmt.println("Could not create file '%s'", filename)
		return
	}
	fmt.fprintfln(f, "TITLE %q", lut^.title)
	if lut.size_1d > 0 {
		fmt.fprintfln(f, "LUT_1D_SIZE %d", lut.size_1d)
		fmt.fprintfln(
			f,
			"DOMAIN_MIN %f %f %f",
			lut.domain_min[0],
			lut.domain_min[1],
			lut.domain_min[2],
		)
		fmt.fprintfln(
			f,
			"DOMAIN_MAX %f %f %f",
			lut.domain_max[0],
			lut.domain_max[1],
			lut.domain_max[2],
		)
		for i := 0; i < lut.size_1d; i += 1 {
			fmt.fprintfln(
				f,
				"%.6f %.6f %.6f",
				lut.data_1d[i].r,
				lut.data_1d[i].g,
				lut.data_1d[i].b,
			)
		}
		return
	}
	if lut.size_3d > 0 {
		fmt.fprintfln(f, "LUT_3D_SIZE %d", lut.size_3d)
		fmt.fprintfln(
			f,
			"DOMAIN_MIN %f %f %f",
			lut.domain_min[0],
			lut.domain_min[1],
			lut.domain_min[2],
		)
		fmt.fprintfln(
			f,
			"DOMAIN_MAX %f %f %f",
			lut.domain_max[0],
			lut.domain_max[1],
			lut.domain_max[2],
		)
		for b := 0; b < lut.size_3d; b += 1 {
			for g := 0; g < lut.size_3d; g += 1 {
				for r := 0; r < lut.size_3d; r += 1 {
					n := r + g * lut.size_3d + b * lut.size_3d * lut.size_3d
					fmt.fprintfln(
						f,
						"%.6f %.6f %.6f",
						lut.data_3d[n].r,
						lut.data_3d[n].g,
						lut.data_3d[n].b,
					)
				}
			}
		}
		return
	}
}

save_cube_to_png :: proc(pcube: ^Cube, filename: string) {
	c_filename := strings.clone_to_cstring(filename, context.allocator)
	defer delete(c_filename)

	index, found := slice.linear_search(VALID_HALD_SIZES, i32(pcube.size_3d))

	pixels := make([]u8, BUFFER_SIZE)
	err := stbi.write_png(
		c_filename,
		IMG_DIM,
		IMG_DIM,
		BYTES_PER_PIXEL,
		raw_data(pixels),
		STRIDE_IN_BYTES,
	)

	if err != 0 {
		fmt.printfln("HALD image successfully created: %s (%dx%d)", HALD_PNG, IMG_DIM, IMG_DIM)
	} else {
		fmt.println("Error creating the HALD image.")
	}

}
