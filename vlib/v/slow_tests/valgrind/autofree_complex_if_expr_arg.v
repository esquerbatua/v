// vtest vflags: -autofree
// Test that autofree properly handles complex if-expressions as function arguments
// This was previously broken, generating malformed C code

fn main() {
	// Test simple if-expression as argument
	for n in 1 .. 5 {
		println(if n % 2 == 0 {
			'Even'
		} else {
			'Odd'
		})
	}

	// Test with multiple branches
	for i in 1 .. 4 {
		result := if i == 1 {
			'One'
		} else if i == 2 {
			'Two'
		} else {
			'Three or more'
		}
		println(result)
	}

	println('Done')
}
