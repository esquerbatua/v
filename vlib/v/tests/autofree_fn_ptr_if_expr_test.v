// Test that function pointers work correctly in if expressions with -autofree
module main

fn add(x int) int {
	return x + 1
}

fn sub(x int) int {
	return x - 1
}

fn test_fn_ptr_in_if_expr() {
	x := 5
	// Test function pointer in if expression
	f := if x > 0 {
		add
	} else {
		sub
	}
	assert f(10) == 11
}

fn test_fn_ptr_in_nested_if_expr() {
	x := 5
	y := 10
	// Test nested if expression with function pointers
	f := if x > 0 {
		if y > 5 {
			add
		} else {
			sub
		}
	} else {
		sub
	}
	assert f(10) == 11
}

fn main() {
	test_fn_ptr_in_if_expr()
	test_fn_ptr_in_nested_if_expr()
}
