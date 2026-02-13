# Issue #2: Array Pointer Dereference Missing in -autofree Cleanup

**Category:** Code Generation Bug  
**Severity:** High  
**Status:** Open  
**Assignable to Agent:** Yes

## Problem Description

When the `-autofree` flag is enabled, the V compiler generates incorrect C code for array reassignments. The cleanup code attempts to initialize an `array` struct with an `array*` pointer without dereferencing it, causing a type mismatch error in C compilation.

## Symptoms

**Compilation Error:**
```
error: initializing 'array' (aka 'struct array') with an expression of incompatible type 'Array_u64 *' (aka 'struct array *'); dereference with *
array _sref1290 = (remainder); // free array on re-assignment2
      ^           ~~~~~~~~~~~
                  *
```

**Error Pattern:**
The compiler generates:
```c
array _sref1290 = (remainder); // free array on re-assignment2
```

But should generate:
```c
array _sref1290 = *remainder; // free array on re-assignment2
```

## Affected Files

**Test Cases:**
- `examples/pidigits.v` - Uses big integer arrays
- `examples/rule110.v` - Uses integer arrays with reassignment
- `examples/vpwgen.v` - Uses big integer arrays

**Compiler Code to Fix:**
- `vlib/v/gen/c/autofree.v` - Autofree cleanup generation
- `vlib/v/gen/c/assign.v` - Assignment handling
- `vlib/math/big/division_array_ops.v` - Contains affected array operations

## Root Cause

The autofree array reassignment logic doesn't properly dereference array pointers when creating cleanup temporaries. When an array is reassigned, the compiler creates a temporary variable (`_sref*`) to hold the old value for cleanup, but it forgets to dereference the pointer.

The issue occurs in the array reassignment cleanup code, likely in:
1. `vlib/v/gen/c/assign.v` - Where reassignments are handled
2. `vlib/v/gen/c/autofree.v` - Where cleanup temporaries are created

## Reproduction Steps

### Minimal Reproduction Code

Save as `test_array_reassign_autofree.v`:

```v
import math.big

fn test_array_reassign() {
    mut remainder := big.integer_from_int(1)
    mut arr := []u64{len: 10}
    
    // This reassignment triggers the bug
    arr = []u64{len: 20}
    
    // Using big.Integer division also triggers it
    _ := remainder
}

fn main() {
    test_array_reassign()
    println('Done')
}
```

Or simpler version:

```v
fn main() {
    mut arr := []int{len: 5}
    arr = []int{len: 10}  // Reassignment with autofree
    println(arr.len)
}
```

### Compilation Commands

```bash
# Build V compiler if needed
make

# Reproduce the error
./v -autofree test_array_reassign_autofree.v -o /tmp/test

# Get detailed error with clang
./v -autofree -g -keepc -cc clang test_array_reassign_autofree.v -o /tmp/test

# Inspect generated C code
./v -autofree -g -keepc test_array_reassign_autofree.v -o /tmp/test 2>&1
cat /tmp/v_*/test.tmp.c | grep "_sref" -A 2 -B 2
```

### Real-World Examples

```bash
# Test with actual failing examples
./v -autofree -cc clang examples/pidigits.v -o /tmp/pi_test
./v -autofree -cc clang examples/rule110.v -o /tmp/rule_test
./v -autofree -cc clang examples/vpwgen.v -o /tmp/vpw_test
```

### Expected vs Actual

**Expected:** Proper pointer dereference
```c
array _sref1290 = *remainder;  // Dereference the pointer
builtin__array_free(&_sref1290);
remainder = new_value;
```

**Actual:** Missing dereference
```c
array _sref1290 = (remainder);  // Type mismatch: array* vs array
builtin__array_free(&_sref1290);
remainder = new_value;
```

## Affected Examples

The following examples fail with this issue:
- `examples/pidigits.v`
- `examples/rule110.v`
- `examples/vpwgen.v`
- Any code using `vlib/math/big` with array operations

## Suggested Fix Approach

1. **Locate the array reassignment code:**
   - Check `vlib/v/gen/c/assign.v` for array assignment handling
   - Look for where `_sref*` temporary variables are created
   - Find the autofree cleanup code for array reassignments

2. **Identify the missing dereference:**
   ```v
   // Current (incorrect):
   g.write('array ${temp_var} = (${old_var}); // free array on re-assignment2')
   
   // Should be (correct):
   g.write('array ${temp_var} = *${old_var}; // free array on re-assignment2')
   ```

3. **Check pointer context:**
   - Determine if `old_var` is a pointer or a value
   - Add dereference operator when it's a pointer
   - Handle both pointer and non-pointer cases

4. **Potential code location:**
   Look for patterns like:
   ```v
   // In vlib/v/gen/c/assign.v or autofree.v
   if sym.kind == .array {
       // Array reassignment cleanup
       g.writeln('array ${temp_var} = ${old_var};')  // Missing * here
   }
   ```

## Testing Strategy

### Unit Test

Create `vlib/v/tests/autofree_array_reassign_test.v`:
```v
fn test_simple_array_reassign() {
    mut arr := [1, 2, 3]
    arr = [4, 5, 6, 7, 8]
    assert arr.len == 5
    assert arr[0] == 4
}

fn test_array_reassign_in_loop() {
    mut arr := []int{}
    for i in 0 .. 5 {
        arr = []int{len: i + 1}
        assert arr.len == i + 1
    }
}

fn test_array_reassign_different_sizes() {
    mut arr := []string{len: 100}
    arr = []string{len: 10}
    arr = []string{len: 1000}
    assert arr.len == 1000
}
```

Compile with: `./v -autofree vlib/v/tests/autofree_array_reassign_test.v`

### Regression Tests

```bash
# Test real-world examples that currently fail
./v -autofree examples/pidigits.v -o /tmp/pi_test && /tmp/pi_test 50
./v -autofree examples/rule110.v -o /tmp/rule_test && /tmp/rule_test
./v -autofree examples/vpwgen.v -o /tmp/vpw_test && /tmp/vpw_test 12 16
```

### Valgrind Test

```bash
# Ensure no memory leaks after fix
./v -autofree -g test_array_reassign_autofree.v -o /tmp/test
valgrind --leak-check=full /tmp/test
```

## Success Criteria

- [ ] `examples/pidigits.v` compiles successfully with `-autofree`
- [ ] `examples/rule110.v` compiles successfully with `-autofree`
- [ ] `examples/vpwgen.v` compiles successfully with `-autofree`
- [ ] Generated C code uses `*pointer` syntax for array temporaries
- [ ] Unit tests pass
- [ ] No memory leaks (verify with valgrind)
- [ ] No regressions in existing autofree tests

## Additional Context

**Why This Happens:**
Array reassignments need special handling because the old array must be freed before the new one is assigned. The compiler creates a temporary to hold the old array, but when that old array is referenced by a pointer, the temporary initialization forgets to dereference it.

**Related Code Patterns That Work:**
- Simple variable assignments
- Array creation without reassignment
- Pointer assignments (without array-specific cleanup)

**Related Code Patterns That Fail:**
- Array reassignments (`arr = new_array`)
- Array operations in loops with reassignment
- Big integer array operations (which use arrays internally)

## References

- Main investigation: `AUTOFREE_ISSUES.md` (Issue Category #2)
- Reproduction guide: `AUTOFREE_REPRODUCTION_GUIDE.md`
- Related compiler code: `vlib/v/gen/c/assign.v`, `vlib/v/gen/c/autofree.v`
- Affected library: `vlib/math/big/division_array_ops.v`

## Notes for Agent

This is a straightforward pointer dereference issue. The fix is likely a one-line change to add `*` before the variable name when creating the cleanup temporary. The challenge is finding the exact location in the code generation logic.

Start by searching for "_sref" or "free array on re-assignment" in the cgen code to find where these temporaries are created.

Use `-keepc` flag extensively to examine generated C code and verify the fix.
