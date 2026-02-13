import os

fn main() {
	mut count := 0
	for {
		count++
		expr := os.input_opt('[${count}] ') or {
			println('error')
			break
		}.trim_space()
		if expr == 'exit' {
			break
		}
		println('You entered: ${expr}')
	}
}
