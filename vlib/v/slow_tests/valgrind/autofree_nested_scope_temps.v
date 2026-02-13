// vtest vflags: -autofree
// Test for autofree with temporary variables in nested scopes
// This tests the fix for cleanup_pos tracking to avoid freeing
// temporaries from sibling scopes or after the cleanup point

struct TestStruct {
	name  string
	value int
}

fn main() {
	// Test with struct fields that generate temporaries in different scopes
	fields := [
		TestStruct{'field1', 10},
		TestStruct{'field2', 20},
		TestStruct{'field3', 30},
	]

	for field in fields {
		// This creates temporaries in each iteration scope
		name_msg := 'Field: ${field.name}'
		value_msg := 'Value: ${field.value}'
		println('${name_msg}, ${value_msg}')

		// Each branch creates its own temporaries
		if field.value > 15 {
			desc := 'High: ${field.value}'
			println(desc)
		} else {
			desc := 'Low: ${field.value}'
			println(desc)
		}
	}

	println('All fields processed')
}
