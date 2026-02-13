// vtest vflags: -autofree
// Test that autofree properly handles result type unwrapping as function arguments
// This was previously broken with string interpolation containing result unwrapping

fn get_value() !int {
	return 42
}

fn get_string() !string {
	return 'test'
}

fn main() {
	// Test simple result unwrapping as argument
	result := get_value() or {
		println('Error: ${err}')
		0
	}
	println(result)

	// Test result in string interpolation
	val := get_value() or { -1 }
	msg := 'Value is ${val}'
	println(msg)

	// Test string result unwrapping
	s := get_string() or { 'default' }
	println(s)

	println('Done')
}
