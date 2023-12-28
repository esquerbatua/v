import datatypes.crdt

fn test_add() {
	mut twophaseset := crdt.new_two_phase_set[string]()
	element := 'some-test-element'
	assert twophaseset.lookup(element) == false
	twophaseset.add(element)
	assert twophaseset.lookup(element)
}

fn test_remove() {
	mut twophaseset := crdt.new_two_phase_set[string]()
	element := 'some-test-element'
	assert twophaseset.lookup(element) == false
	twophaseset.add(element)
	assert twophaseset.lookup(element)
	twophaseset.remove(element)
	assert twophaseset.lookup(element) == false
}
