// Test for array reassignment with autofree
// This test ensures that array reassignments work correctly with -autofree flag

// Helper function: Array reassignment in mut parameter
fn reassign_mut_param(mut arr []int) {
	// This generates: array _sref = *arr;
	arr = [1, 2, 3, 4, 5]
}

fn test_array_reassignment_with_autofree() {
	// Test mut parameter
	mut x := []int{len: 10}
	reassign_mut_param(mut x)
	assert x.len == 5
	assert x[0] == 1
}
