fn main() {
	mut arr := []int{len: 5}
	arr = []int{len: 10} // Reassignment with autofree
	println(arr.len)
}
