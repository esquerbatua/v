// vtest vflags: -autofree
// Test for autofree with or blocks in method chains
// This tests the fix for recursive or block detection in chained method calls
// like: os.input_opt() or { break }.trim_space()
import os

fn main() {
	mut count := 0
	for {
		count++
		if count > 1 {
			break
		}
		// This pattern was failing before the fix - the or block is nested
		// inside a method chain, and autofree was trying to free expr
		// before it was declared
		expr := os.input_opt('[${count}] ') or {
			println('input failed')
			break
		}.trim_space()

		if expr == 'exit' {
			break
		}
		println('Got: ${expr}')
	}
}
