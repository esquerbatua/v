# Issue #5: Result/Option Type Handling in Or-Blocks with -autofree

**Category:** Type System Bug  
**Severity:** Medium  
**Status:** Open  
**Assignable to Agent:** Yes

## Problem Description

When the `-autofree` flag is enabled, the compiler generates incorrect cleanup code for Result (`!`) and Option (`?`) types, particularly when used with or-blocks. The temporary variables created for result/option unwrapping are not properly tracked, leading to undeclared identifier errors.

## Symptoms

**Compilation Error:**
```
error: use of undeclared identifier '_t2'
string _arg_expr_println_1_139 = (_t2.is_error) { ... }
                                  ^
```

Or:

```
error: initializing 'string' with an expression of incompatible type 'bool'
string _arg_expr_println_1_139 = (_t2.is_error) { ... }
       ^                         ~~~~~~~~~~~~~~
```

**Error Pattern:**
The compiler generates code that references result/option temporaries that don't exist or are out of scope:
```c
// _t2 is never declared or already out of scope
if (_t2.is_error) {
    // error handling
}
```

## Affected Files

**Test Cases:**
- `examples/net_raw_http.v` - Result type with or-block in network operations
- `examples/random_ips.v` - Option/Result unwrapping in expressions

**Compiler Code to Fix:**
- `vlib/v/gen/c/autofree.v` - Result/Option cleanup tracking
- `vlib/v/gen/c/cgen.v` - Result/Option code generation
- Possibly `vlib/v/gen/c/fn.v` - Function call handling with results

## Root Cause

The autofree code doesn't properly handle the temporary variables created for Result/Option unwrapping. When a Result or Option type is used with an or-block:

```v
conn := net.dial_tcp('google.com:80') or {
    println('Failed: ${err}')
    return
}
```

The compiler creates temporary variables for:
1. The result value
2. The error state
3. The unwrapped value

Autofree tries to track and cleanup these temporaries, but:
- They may have different lifetimes than expected
- The scope tracking doesn't account for or-block control flow
- Temporaries from the result struct are referenced after cleanup

## Reproduction Steps

### Minimal Reproduction Code

Save as `test_result_autofree.v`:

```v
import net

fn main() {
    conn := net.dial_tcp('google.com:80') or {
        println('Failed to connect: ${err}')
        return
    }
    defer {
        conn.close() or {}
    }
    
    println('Connected successfully')
}
```

Or simpler version with custom Result type:

```v
fn get_value() !int {
    return 42
}

fn main() {
    value := get_value() or {
        println('Error: ${err}')
        return
    }
    println('Value: ${value}')
}
```

### Compilation Commands

```bash
# Build V compiler if needed
make

# Reproduce with net example
./v -autofree -cc clang test_result_autofree.v -o /tmp/test

# Reproduce with real examples
./v -autofree -cc clang examples/net_raw_http.v -o /tmp/test
./v -autofree -cc clang examples/random_ips.v -o /tmp/test

# Get detailed error
./v -autofree -g -keepc -cc clang test_result_autofree.v -o /tmp/test

# Inspect generated C
cat /tmp/v_*/test.tmp.c | grep "_result_" -A 10 -B 5
cat /tmp/v_*/test.tmp.c | grep "is_error" -A 5 -B 5
```

### Expected vs Actual

**Expected:** Proper result handling and cleanup
```c
// Generate result
_result_net__TcpConn_ptr _t1 = net__dial_tcp(_S("google.com:80"));

// Check error
if (_t1.is_error) {
    // Handle error with 'err' available
    IError err = _t1.err;
    builtin__println(_SLIT("Failed"));
    return;
}

// Extract value
net__TcpConn_ptr conn = *(net__TcpConn_ptr*)_t1.data;

// Cleanup at scope end
// (result temporary _t1 is already handled)
```

**Actual:** References to non-existent temporaries
```c
// _t2 referenced but never declared
if (_t2.is_error) {
    // ...
}

// Or cleanup happens before use
builtin__string_free(&_t2);  // _t2 doesn't exist
```

## Affected Examples

The following examples fail with this issue:
- `examples/net_raw_http.v` - Network operations with result types
- `examples/random_ips.v` - IP parsing with result types
- Any code using Result (`!`) or Option (`?`) types with or-blocks and `-autofree`

## Suggested Fix Approach

1. **Understand Result/Option code generation:**
   - Result types generate `_result_TypeName` structs
   - These contain `.is_error`, `.err`, and `.data` fields
   - Or-blocks create control flow that branches on `.is_error`
   - The actual value is extracted from `.data`

2. **Track Result temporaries correctly:**
   ```v
   // In vlib/v/gen/c/autofree.v
   fn (mut g Gen) autofree_variable(v ast.Var) {
       // Skip result/option temporaries - they have special lifetime
       if v.typ.has_flag(.result) || v.typ.has_flag(.option) {
           // Result temporaries are handled differently
           // Don't add to standard cleanup list
           return
       }
       // ... rest of cleanup logic
   }
   ```

3. **Handle or-block scope correctly:**
   ```v
   // Or-blocks create a special scope
   // Variables in the or-block should not be cleaned up in parent scope
   if obj.is_or {
       g.trace_autofree('// skipping or-block var "${obj.name}"')
       continue
   }
   ```

4. **Result value extraction:**
   ```v
   // The extracted value from a result should be tracked for cleanup
   // But the result temporary itself should not be freed incorrectly
   
   // Generate result
   temp_result := g.gen_result_temp()
   
   // Extract value (this gets the real variable)
   actual_var := g.extract_result_value(temp_result)
   
   // Track actual_var for cleanup, not temp_result
   g.mark_for_cleanup(actual_var)
   ```

## Testing Strategy

### Unit Test

Create `vlib/v/tests/autofree_result_option_test.v`:
```v
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
```

Compile with: `./v -autofree vlib/v/tests/autofree_result_option_test.v`

### Regression Tests

```bash
# Test network example (may fail due to network, but should compile)
./v -autofree test_result_autofree.v -o /tmp/test
/tmp/test || echo "Network failure is OK"

# Test actual failing examples
./v -autofree examples/net_raw_http.v -o /tmp/test
./v -autofree examples/random_ips.v -o /tmp/test
```

### Valgrind Test

```bash
# Check for memory leaks in result handling
./v -autofree -g test_result_autofree.v -o /tmp/test
valgrind --leak-check=full /tmp/test 2>&1 | grep "definitely lost"
```

## Success Criteria

- [ ] `examples/net_raw_http.v` compiles successfully with `-autofree`
- [ ] `examples/random_ips.v` compiles successfully with `-autofree`
- [ ] Result/Option temporaries are properly tracked
- [ ] Or-block variables are not incorrectly freed
- [ ] Unit tests pass
- [ ] No memory leaks (verify with valgrind)
- [ ] No regressions in existing autofree tests

## Additional Context

**Result Type Structure:**
```c
// Generated C struct for Result type
typedef struct {
    bool is_error;
    IError err;      // Only valid if is_error == true
    byte* data;      // Only valid if is_error == false
    int ecode;
} _result_TypeName;
```

**Why This is Tricky:**
1. Result value has two states (success/error)
2. Different fields are valid in different states
3. Or-block creates branching control flow
4. The actual value is extracted from `.data` pointer
5. Multiple temporaries exist during unwrapping

**Related Code Patterns That Work:**
- Simple function calls without Result/Option
- Result types without or-blocks (if checked manually)
- Option types with simple unwrapping

**Related Code Patterns That Fail:**
- Result types with or-blocks
- Option types with complex or-block expressions
- Result types in function call arguments
- Nested result unwrapping

## Code Already Handling This

In `vlib/v/gen/c/autofree.v` line 70-74:
```v
if obj.is_or {
    // Skip vars inited with the `or {}`, since they are generated
    // after the or block in C.
    g.trace_autofree('// skipping `or {}` var "${obj.name}"')
    continue
}
```

This shows the compiler knows about or-block variables, but the check might not be comprehensive enough.

## References

- Main investigation: `AUTOFREE_ISSUES.md` (Issue Category #5)
- Reproduction guide: `AUTOFREE_REPRODUCTION_GUIDE.md`
- Related compiler code: `vlib/v/gen/c/autofree.v`, `vlib/v/gen/c/cgen.v`
- Result type documentation in V docs

## Notes for Agent

This issue requires understanding V's Result/Option type system implementation. Key areas:

1. How Result types are generated in C
2. How or-blocks create control flow
3. How values are extracted from Results
4. Which temporaries need cleanup and which don't

The existing code already has *some* handling for or-block variables (line 70-74 in autofree.v), but it may not cover all cases.

Start by examining:
- How `_result_*` temporaries are generated
- Where they're supposed to be cleaned up
- Why they're being referenced out of scope

Use `-keepc` to examine the generated C and trace the lifetime of result temporaries.

This may require coordination with Result type generation code, not just autofree.
