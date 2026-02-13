// Comprehensive test for function pointers and enum values in if expressions with -autofree
// This test addresses the issue where enum values or function names were incorrectly
// treated as type names in temporary variable declarations
module main

import term

// Test 1: Simple enum values in if expression
enum Color {
	red
	green
	blue
}

fn test_simple_enum_in_if() {
	x := 5
	color := if x > 0 {
		Color.green
	} else {
		Color.red
	}
	assert color == Color.green
	println('✓ Simple enum in if expression works')
}

// Test 2: Nested enum conditionals
fn test_nested_enum_conditionals() {
	x := 5
	y := 10

	color := if x > 0 {
		if y > 5 {
			Color.blue
		} else {
			Color.green
		}
	} else {
		Color.red
	}

	assert color == Color.blue
	println('✓ Nested enum conditionals work')
}

// Test 3: Function pointers in if expression (the main issue case)
fn add_one(x int) int {
	return x + 1
}

fn sub_one(x int) int {
	return x - 1
}

fn test_function_ptr_in_if() {
	x := 5
	f := if x > 0 {
		add_one
	} else {
		sub_one
	}
	result := f(10)
	assert result == 11
	println('✓ Function pointers in if expression work')
}

// Test 4: Term color functions (the original failing case from the issue)
fn test_term_colors_in_if() {
	rate_diff := 1.5

	color := if rate_diff > 0 {
		term.green
	} else {
		term.red
	}

	result := color('Rate: ${rate_diff}')
	assert result.contains('Rate:')
	assert result.contains('1.5')
	println('✓ Term color functions in if expression work')
}

// Test 5: Nested term colors
fn test_nested_term_colors() {
	rate := 2.0

	color := if rate > 0 {
		if rate > 1 {
			term.green
		} else {
			term.yellow
		}
	} else {
		term.red
	}

	result := color('positive')
	assert result.contains('positive')
	println('✓ Nested term color functions work')
}

// Test 6: Multiple branches with different function types
fn test_multiple_branches() {
	x := 0

	color := if x > 10 {
		term.green
	} else if x > 0 {
		term.yellow
	} else {
		term.red
	}

	result := color('zero')
	assert result.contains('zero')
	println('✓ Multiple branches with function pointers work')
}

// Test 7: Function returning function pointer
fn get_color_fn(positive bool) fn (string) string {
	return if positive {
		term.green
	} else {
		term.red
	}
}

fn test_function_returning_fn_ptr() {
	color_fn := get_color_fn(true)
	result := color_fn('success')
	assert result.contains('success')
	println('✓ Function returning function pointer works')
}

fn main() {
	test_simple_enum_in_if()
	test_nested_enum_conditionals()
	test_function_ptr_in_if()
	test_term_colors_in_if()
	test_nested_term_colors()
	test_multiple_branches()
	test_function_returning_fn_ptr()
}
