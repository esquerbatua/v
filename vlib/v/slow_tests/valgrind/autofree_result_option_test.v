// vtest vflags: -autofree
// vtest build: !sanitize-address-gcc && !sanitize-address-clang

// Test for autofree with Result types in string interpolation
fn get_int() !int {
	return 42
}

fn get_string() !string {
	return 'hello'
}

fn might_fail(should_fail bool) !int {
	if should_fail {
		return error('failed')
	}
	return 100
}

fn test_simple_result_unwrap() {
	value := get_int() or {
		assert false, 'should not fail'
		return
	}
	assert value == 42
}

fn test_result_with_error_handling() {
	value := might_fail(false) or {
		assert false, 'should not fail'
		0
	}
	assert value == 100

	value2 := might_fail(true) or {
		assert err.msg() == 'failed'
		-1
	}
	assert value2 == -1
}

fn test_result_in_expression() {
	result := (get_int() or { 0 }) + (get_int() or { 0 })
	assert result == 84
}

fn test_string_result() {
	s := get_string() or {
		assert false
		''
	}
	assert s == 'hello'
}

// Test Result types in string interpolation (the main issue fixed)
fn test_result_in_string_interpolation() {
	// Simple case with one result propagation
	s1 := '${get_int()!}'
	assert s1 == '42'

	// Multiple result propagations
	s2 := '${get_int()!} and ${get_int()!}'
	assert s2 == '42 and 42'

	// Mixed with other expressions
	s3 := 'Value: ${get_int()!}'
	assert s3 == 'Value: 42'
}

// Test with propagation in println (original issue)
fn test_result_propagation_in_println() {
	// This used to fail with: error: use of undeclared identifier '_t2'
	println('${get_int()!}')
	println('${get_int()!}.${get_int()!}')
}
