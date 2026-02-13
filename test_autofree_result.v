fn get_value() !int {
	return 42
}

fn main() {
	value := get_value() or {
		println('Error: ${err}')
		return
	}
	println('Value: ${value}')
}
