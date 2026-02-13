# Issue #4: Function Call Syntax Broken by Autofree Cleanup

**Category:** Code Generation Bug  
**Severity:** High  
**Status:** Open  
**Assignable to Agent:** Yes

## Problem Description

When the `-autofree` flag is enabled, the compiler generates invalid C code for function calls with complex expressions as arguments. The autofree cleanup code is inserted in a way that breaks the function call syntax, causing compilation errors.

## Symptoms

**Compilation Error:**
```
error: expected ';' at end of declaration
string _arg_expr_println_1_21 = _expr_println_1_21)((_t1 == ...));
                                                   ^
                                                   ;
```

Or:

```
error: use of undeclared identifier '_expr_println_1_21'
string _arg_expr_println_1_21 = _expr_println_1_21)(...)
                                ^
```

**Error Pattern:**
The compiler generates broken function call code like:
```c
// Variable declaration followed by function call - broken
string _arg_expr_println_1_21 = _expr_println_1_21)((_t1 == ...));

// Or incorrect cleanup marker
builtin__println(/*autofree arg*/_arg;  // Missing closing paren
```

## Affected Files

**Test Cases:**
- `examples/fizz_buzz.v` - Complex conditional as println argument
- `examples/random_ips.v` - Result unwrapping in println argument

**Compiler Code to Fix:**
- `vlib/v/gen/c/fn.v` - Function call generation
- `vlib/v/gen/c/autofree.v` - Argument cleanup code
- Possibly `vlib/v/gen/c/cgen.v` - Expression handling

## Root Cause

The autofree code generation for function arguments incorrectly handles complex expressions. When a function is called with a complex expression (like nested ternaries, match expressions, or result unwrapping), the cleanup code interferes with:

1. **Argument variable declaration** - Creates malformed variable declarations
2. **Function call syntax** - Inserts cleanup code that breaks the call
3. **Expression evaluation order** - Cleanup happens before evaluation completes

The issue occurs because autofree tries to create cleanup temporaries for function arguments, but the code insertion happens at the wrong point in the expression, breaking C syntax.

## Reproduction Steps

### Minimal Reproduction Code

Save as `test_funcall_autofree.v`:

```v
fn main() {
    for n in 1..101 {
        println(if n % 15 == 0 {
            'FizzBuzz'
        } else if n % 5 == 0 {
            'Buzz'
        } else if n % 3 == 0 {
            'Fizz'
        } else {
            n.str()
        })
    }
}
```

Or with Result type:

```v
fn get_value() !int {
    return 42
}

fn main() {
    // Complex expression with or-block as function argument
    println(get_value() or { 
        panic('error: ${err}') 
    })
}
```

### Compilation Commands

```bash
# Build V compiler if needed
make

# Reproduce with FizzBuzz
./v -autofree -cc clang examples/fizz_buzz.v -o /tmp/test

# Reproduce with random_ips
./v -autofree -cc clang examples/random_ips.v -o /tmp/test

# Get detailed C error
./v -autofree -g -keepc -cc clang test_funcall_autofree.v -o /tmp/test

# Inspect generated C
cat /tmp/v_*/test.tmp.c | grep "_arg_expr_println" -A 5 -B 5
```

### Expected vs Actual

**Expected:** Clean function call with proper argument evaluation
```c
// Evaluate complex expression
string temp_arg = (n % 15 == 0) ? _S("FizzBuzz") : 
                  (n % 5 == 0) ? _S("Buzz") : 
                  (n % 3 == 0) ? _S("Fizz") : 
                  builtin__int_literal_str(n);

// Call function
builtin__println(temp_arg);

// Cleanup
builtin__string_free(&temp_arg);
```

**Actual:** Broken syntax with cleanup code in wrong place
```c
// Malformed declaration
string _arg_expr_println_1_21 = _expr_println_1_21)((_t1 == ...));

// Or broken function call
builtin__println(/*autofree arg*/_arg;
```

## Affected Examples

The following examples fail with this issue:
- `examples/fizz_buzz.v` - Nested conditional in println
- `examples/random_ips.v` - Result unwrapping in println

## Suggested Fix Approach

1. **Analyze function argument cleanup code:**
   - Look at `vlib/v/gen/c/fn.v` - `gen_fn_call()` or similar
   - Find where autofree cleanup is inserted for arguments
   - Identify why it breaks the expression syntax

2. **Proper argument handling:**
   ```v
   // In function call generation
   fn (mut g Gen) gen_fn_call(node ast.CallExpr) {
       // Generate argument expressions
       for arg in node.args {
           // BEFORE: autofree code inserted here breaks syntax
           // AFTER: should be like this:
           
           // 1. Generate temporary for complex argument
           if arg.is_complex_expr() {
               temp_var := g.new_tmp_var()
               g.write('${arg_type} ${temp_var} = ')
               g.expr(arg.expr)
               g.writeln(';')
               arg_names << temp_var
           } else {
               // Simple expression, generate inline
               g.expr(arg.expr)
           }
       }
       
       // 2. Generate function call
       g.write('${fn_name}(')
       g.write(arg_names.join(', '))
       g.write(')')
       
       // 3. NOW cleanup temporaries (after the call)
       for temp_var in arg_names {
           if needs_cleanup(temp_var) {
               g.writeln('${cleanup_fn}(&${temp_var});')
           }
       }
   }
   ```

3. **Avoid inline cleanup markers:**
   - Don't insert `/*autofree arg*/` comments mid-expression
   - Generate all cleanup code after the complete statement
   - Use proper temporary variables instead of trying to cleanup inline

4. **Code changes needed:**
   ```v
   // In vlib/v/gen/c/fn.v or autofree.v
   
   // WRONG: Inserting cleanup in the middle of call
   g.write('fn_name(')
   g.write('/*autofree arg*/')  // This breaks syntax
   g.expr(arg)
   
   // RIGHT: Cleanup after complete call
   temp := g.gen_temp_for_arg(arg)
   g.write('fn_name(${temp})')
   g.writeln(';')
   g.autofree_temp(temp)
   ```

## Testing Strategy

### Unit Test

Create `vlib/v/tests/autofree_function_args_test.v`:
```v
fn test_complex_arg_conditional() {
    for n in 1..20 {
        result := if n % 15 == 0 {
            'FizzBuzz'
        } else if n % 5 == 0 {
            'Buzz'
        } else if n % 3 == 0 {
            'Fizz'
        } else {
            n.str()
        }
        assert result.len > 0
    }
}

fn test_result_unwrap_in_call() {
    fn get_value() !int {
        return 42
    }
    
    result := get_value() or { 0 }
    assert result == 42
}

fn test_nested_call_args() {
    fn outer(s string) string {
        return s.to_upper()
    }
    
    fn inner() string {
        return 'hello'
    }
    
    result := outer(inner())
    assert result == 'HELLO'
}
```

Compile with: `./v -autofree vlib/v/tests/autofree_function_args_test.v`

### Regression Tests

```bash
# Test FizzBuzz
./v -autofree examples/fizz_buzz.v -o /tmp/fizz && /tmp/fizz | head -20

# Expected output:
# 1
# 2
# Fizz
# 4
# Buzz
# Fizz
# 7
# 8
# Fizz
# Buzz
# 11
# Fizz
# 13
# 14
# FizzBuzz
# ...

# Test random_ips (with error handling)
./v -autofree examples/random_ips.v -o /tmp/ips && /tmp/ips || echo "OK if network unavailable"
```

### Valgrind Test

```bash
# Ensure no memory leaks
./v -autofree -g test_funcall_autofree.v -o /tmp/test
valgrind --leak-check=full /tmp/test 2>&1 | grep "definitely lost"
# Should show: "definitely lost: 0 bytes in 0 blocks"
```

## Success Criteria

- [ ] `examples/fizz_buzz.v` compiles successfully with `-autofree`
- [ ] `examples/random_ips.v` compiles successfully with `-autofree`
- [ ] Generated C code has valid function call syntax
- [ ] Complex expressions as arguments work correctly
- [ ] Unit tests pass
- [ ] FizzBuzz produces correct output (1, 2, Fizz, 4, Buzz, ...)
- [ ] No memory leaks (verify with valgrind)
- [ ] No regressions in existing autofree tests

## Additional Context

**Why This Happens:**
Function call argument evaluation is complex in C because:
1. Arguments must be evaluated before the call
2. Temporaries must be created for complex expressions
3. Cleanup must happen after the call completes

Autofree tries to insert cleanup code but doesn't respect these constraints, leading to syntax errors.

**Related Code Patterns That Work:**
- Simple variable arguments: `println(var)`
- Simple string literal arguments: `println('hello')`
- Simple function call arguments: `println(fn())`

**Related Code Patterns That Fail:**
- Complex conditional as argument: `println(if x { 'a' } else { 'b' })`
- Match expression as argument: `println(match x { ... })`
- Result unwrapping as argument: `println(fn() or { default })`

## Stack Trace Analysis

The error pattern `_arg_expr_println_1_21 = _expr_println_1_21)(` suggests:
1. Variable `_arg_expr_println_1_21` is being declared
2. It's being assigned `_expr_println_1_21)(`
3. But `_expr_println_1_21` doesn't exist or is malformed
4. The extra `)` and `(` suggest cleanup code is splitting the expression

This points to autofree inserting code between the variable name and its initializer.

## References

- Main investigation: `AUTOFREE_ISSUES.md` (Issue Category #4)
- Reproduction guide: `AUTOFREE_REPRODUCTION_GUIDE.md`
- Related compiler code: `vlib/v/gen/c/fn.v`, `vlib/v/gen/c/autofree.v`
- V language docs on function calls

## Notes for Agent

This issue is about the *order* of code generation. The fix requires ensuring that:
1. Argument expressions are fully evaluated into temporaries
2. The function call uses those temporaries
3. Cleanup happens after the call returns

Focus on the function call generation code in `vlib/v/gen/c/fn.v`. Look for where arguments are processed and where autofree cleanup is triggered.

The key insight: Don't try to cleanup inline during argument evaluation. Instead, evaluate to temporaries first, call the function, then cleanup.

Use `-keepc` extensively to examine the generated C code and understand where the syntax breaks.
