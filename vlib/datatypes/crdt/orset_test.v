import datatypes.crdt

fn test_add() {
	mut orset := crdt.new_orset[string]()
	element := 'some-test-element'
	assert orset.lookup(element) == false
	orset.add(element)
	assert orset.lookup(element)
}

fn test_remove() {
	mut orset := crdt.new_orset[string]()
	element := 'some-test-element'
	assert orset.lookup(element) == false
	orset.add(element)
	assert orset.lookup(element)
	orset.remove(element)
	assert orset.lookup(element) == false
}

fn test_merge() {
	mut orset := crdt.new_orset[string]()
	element := 'some-test-element'
	assert orset.lookup(element) == false
	orset.add(element)
	assert orset.lookup(element)
	mut other_orset := crdt.new_orset[string]()
	other_orset.merge(orset)
	assert other_orset.lookup(element)
	other_orset.remove(element)
	orset.merge(other_orset)
	assert orset.lookup(element) == false
}
