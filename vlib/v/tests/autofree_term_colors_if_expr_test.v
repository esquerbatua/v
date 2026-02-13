module main

import term

fn test_term_colors_in_if_expr() {
	rate_diff := 1.5

	// Test term color functions in if expression
	color := if rate_diff > 0 {
		term.green
	} else {
		term.red
	}

	result := color('Rate: ${rate_diff}')
	assert result.contains('Rate: 1.5')
}

fn test_term_colors_nested() {
	rate := 2.0

	// Test nested if with term colors
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
}

fn main() {
	test_term_colors_in_if_expr()
	test_term_colors_nested()
}
