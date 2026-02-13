# Issue #1: Match Expression Invalid C Code Generation with -autofree

**Category:** Code Generation Bug  
**Severity:** High  
**Status:** Open  
**Assignable to Agent:** Yes

## Problem Description

When the `-autofree` flag is enabled, the V compiler generates invalid C code for match expressions with sum types that include complex nested conditionals. The generated C code attempts to assign an `if` statement to a variable, which is invalid C syntax.

## Symptoms

**Compilation Error:**
```
error: expected expression
_t3 = if (x == (*tree._main__Node_T_f64).value) {
      ^
```

**Error Pattern:**
The compiler generates C code like:
```c
_t3 = 
if (condition) {
    // code
}
```

Instead of valid C syntax.

## Affected Files

**Test Case:** `examples/binary_search_tree.v` (lines 87, 105, 114)

**Compiler Code to Fix:**
- `vlib/v/gen/c/autofree.v` - Autofree code generation
- `vlib/v/gen/c/cgen.v` - Main C code generator
- Possibly `vlib/v/gen/c/fn.v` - Function code generation

## Root Cause

The autofree code generator incorrectly handles match expressions or conditional assignments in certain contexts. When freeing variables in match expressions with sum types, the cleanup code is inserted at a point that breaks the expression structure, causing the assignment operator to be followed by an `if` statement instead of a value.

The issue occurs specifically when:
1. Match expression returns different types (sum types)
2. Multiple nested conditions exist within match branches
3. Autofree tries to insert cleanup code between the assignment and the conditional

## Reproduction Steps

### Minimal Reproduction Code

Save as `test_match_autofree.v`:

```v
type Tree[T] = Empty | Node[T]

struct Empty {}

struct Node[T] {
    value T
    left  Tree[T]
    right Tree[T]
}

fn (tree Tree[T]) delete[T](x T) Tree[T] {
    return match tree {
        Empty { tree }
        Node[T] {
            if tree.left !is Empty && tree.right !is Empty {
                if x < tree.value {
                    Node[T]{ ...tree, left: tree.left.delete(x) }
                } else {
                    tree
                }
            } else {
                tree
            }
        }
    }
}

fn main() {
    mut tree := Tree[int](Empty{})
    tree = tree.delete(5)
}
```

### Compilation Commands

```bash
# Build V compiler if needed
make

# Reproduce with TCC (basic error)
./v -autofree test_match_autofree.v -o /tmp/test

# Reproduce with Clang (detailed error with line numbers)
./v -autofree -g -keepc -cc clang test_match_autofree.v -o /tmp/test

# Inspect generated C code
./v -autofree -g -keepc test_match_autofree.v -o /tmp/test 2>&1
cat /tmp/v_*/test.tmp.c | grep -A 20 "if (x"
```

### Expected vs Actual

**Expected:** Valid C code with proper variable assignment
```c
_t3 = (condition) ? value1 : value2;
// or
if (condition) {
    _t3 = value1;
} else {
    _t3 = value2;
}
```

**Actual:** Invalid C code with assignment to if statement
```c
_t3 = 
if (condition) {
    value1;
}
```

## Affected Examples

The following examples fail with this issue:
- `examples/binary_search_tree.v`

## Suggested Fix Approach

1. **Analyze the issue location:**
   - Look at `vlib/v/gen/c/autofree.v` function `autofree_scope_vars2()`
   - Check how autofree inserts cleanup code in match expressions
   - Review `vlib/v/gen/c/cgen.v` match expression generation

2. **Identify the insertion point:**
   - The autofree code should NOT be inserted between assignment operator and value
   - Cleanup should happen AFTER the complete assignment statement

3. **Potential solutions:**
   - Defer autofree cleanup for match expression temporaries until after assignment
   - Mark match expression variables as "in-use" until assignment completes
   - Generate a temporary variable for the match result, then assign and cleanup

4. **Code changes needed:**
   ```v
   // In autofree_scope_vars2() or similar
   // Add check to skip cleanup insertion during match expression evaluation
   if g.inside_match_expr && !g.match_expr_complete {
       return // Don't insert cleanup yet
   }
   ```

## Testing Strategy

### Unit Test

Create `vlib/v/tests/autofree_match_sumtype_test.v`:
```v
type Result = Success | Error

struct Success {
    value int
}

struct Error {
    msg string
}

fn process(r Result) Result {
    return match r {
        Success {
            if r.value > 10 {
                Success{ value: r.value * 2 }
            } else {
                r
            }
        }
        Error { r }
    }
}

fn test_autofree_match_with_nested_if() {
    r := process(Success{value: 15})
    assert r is Success
    assert (r as Success).value == 30
}
```

Compile with: `./v -autofree vlib/v/tests/autofree_match_sumtype_test.v`

### Regression Test

Ensure `examples/binary_search_tree.v` compiles and runs:
```bash
./v -autofree examples/binary_search_tree.v -o /tmp/bst_test
/tmp/bst_test
```

Expected output:
```
[1] after insertion tree size is 11
[2] after deletion tree size is 7, and these elements were deleted: 0.0 0.3 0.6 1.0
```

## Success Criteria

- [ ] `examples/binary_search_tree.v` compiles successfully with `-autofree`
- [ ] Generated C code has valid syntax (no `_t = if` patterns)
- [ ] Unit test passes
- [ ] No memory leaks (verify with valgrind if available)
- [ ] No regressions in existing autofree tests

## Additional Context

**Related Code Patterns That Work:**
- Simple match expressions (without nested conditionals)
- Match with direct value returns
- Match without sum types

**Related Code Patterns That Fail:**
- Match with sum types + nested if statements
- Match with complex conditional logic in branches
- Match expressions assigned to variables with autofree enabled

## References

- Main investigation: `AUTOFREE_ISSUES.md`
- Reproduction guide: `AUTOFREE_REPRODUCTION_GUIDE.md`
- Related compiler code: `vlib/v/gen/c/autofree.v`, `vlib/v/gen/c/cgen.v`

## Notes for Agent

This is a code generation issue in the autofree cleanup insertion logic. The fix requires careful placement of cleanup code to avoid breaking expression syntax. Focus on the scope tracking in `autofree_scope_vars2()` and how it interacts with match expression generation.

Debug by examining the generated C code with `-keepc` flag and comparing working vs non-working patterns.
