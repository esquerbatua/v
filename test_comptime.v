module main

struct TestStruct {
name string
age  int
flag bool
}

fn test_generic[T]() {
$for field in T.fields {
$if field.typ is int {
println('Found int field: ${field.name}')
}
}
}

fn main() {
test_generic[TestStruct]()
}
