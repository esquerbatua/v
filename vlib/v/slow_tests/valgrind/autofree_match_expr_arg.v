// vtest vflags: -autofree
// Test that autofree properly handles match expressions as function arguments
// This tests the fizz_buzz pattern that was previously broken

fn main() {
	// Test match expression as println argument
	for n in 1 .. 16 {
		println(match true {
			n % 15 == 0 { 'FizzBuzz' }
			n % 5 == 0 { 'Buzz' }
			n % 3 == 0 { 'Fizz' }
			else { n.str() }
		})
	}

	// Test simple match as argument
	x := 2
	println(match x {
		1 { 'one' }
		2 { 'two' }
		else { 'other' }
	})

	println('Done')
}
