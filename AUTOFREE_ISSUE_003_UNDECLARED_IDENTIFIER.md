# Issue #3: Undeclared Identifier in Autofree Cleanup Code

**Category:** Scope Tracking Bug  
**Severity:** High  
**Status:** Open  
**Assignable to Agent:** Yes

## Problem Description

When the `-autofree` flag is enabled, the compiler generates cleanup code that attempts to free variables which were never declared or are out of scope at the point of the free call. This results in C compilation errors for undeclared identifiers.

## Symptoms

**Compilation Error:**
```
error: use of undeclared identifier '_t3'
builtin__string_free(&_t3); // autofreed var flag false
                     ^
```

**Error Patterns:**
The compiler generates cleanup calls like:
```c
builtin__string_free(&_t3);    // But _t3 was never declared
builtin__string_free(&_t29);   // Or _t29 is out of scope
builtin__array_free(&ids);     // Or ids doesn't exist here
```

## Affected Files

**Test Cases (Multiple Examples Fail):**
- `examples/animated_help_text.v` - 20+ undeclared identifier errors
- `examples/flag_layout_editor.v` - 20+ undeclared identifier errors
- `examples/mini_calculator.v` - Variable `expr` not declared
- `examples/mini_calculator_recursive_descent.v` - Variable `input` not declared
- `examples/news_fetcher.v` - Variable `ids` not declared

**Compiler Code to Fix:**
- `vlib/v/gen/c/autofree.v` - Especially `autofree_scope_vars2()` function
- `vlib/v/gen/c/cgen.v` - Temporary variable tracking
- Possibly scope tracking in AST processing

## Root Cause

The autofree scope tracking (`autofree_scope_vars2()`) incorrectly includes variables for cleanup that:

1. **Were optimized away** - The compiler optimized the variable out but autofree still tries to free it
2. **Are in different scopes** - Variable is in a nested scope but cleanup is in parent scope
3. **Are part of inlined expressions** - Temporary variables from expression evaluation that get inlined

The core issue is that the scope tracking doesn't properly:
- Exclude temporary variables that were never actually declared in C
- Track when variables go out of scope
- Handle variables that are part of complex expressions vs standalone declarations

## Reproduction Steps

### Minimal Reproduction Code

Save as `test_undeclared_autofree.v`:

```v
import flag

fn main() {
    mut fp := flag.new_flag_parser(os.args)
    fp.application('test')
    fp.version('1.0.0')
    
    // Flag parsing creates temporary variables that autofree tries to free incorrectly
    show_version := fp.bool('version', `v`, false, 'Show version')
    show_help := fp.bool('help', `h`, false, 'Show help')
    
    if show_version {
        println('Version 1.0.0')
    }
    if show_help {
        println('Help text')
    }
}
```

Or even simpler:

```v
fn main() {
    // Complex expression that creates temporaries
    result := if true { 'hello' } else { 'world' }
    println(result)
}
```

### Compilation Commands

```bash
# Build V compiler if needed
make

# Reproduce with failing examples
./v -autofree -cc clang examples/animated_help_text.v -o /tmp/test
./v -autofree -cc clang examples/flag_layout_editor.v -o /tmp/test
./v -autofree -cc clang examples/mini_calculator.v -o /tmp/test

# Get detailed output showing all undeclared variables
./v -autofree -cc clang -show-c-output examples/animated_help_text.v -o /tmp/test 2>&1 | grep "undeclared"
```

### Expected vs Actual

**Expected:** Cleanup only for declared variables
```c
string declared_var = _STR("hello");
// ... use declared_var ...
builtin__string_free(&declared_var);  // OK - variable exists
```

**Actual:** Cleanup for non-existent variables
```c
// No declaration of _t3
// ... code ...
builtin__string_free(&_t3);  // ERROR - variable doesn't exist
```

## Affected Examples

The following examples fail with this issue:
- `examples/animated_help_text.v` (20+ errors: `_t3`, `_t29`, `_t55`, etc.)
- `examples/flag_layout_editor.v` (20+ errors: same temporaries)
- `examples/mini_calculator.v` (variable: `expr`)
- `examples/mini_calculator_recursive_descent.v` (variable: `input`)
- `examples/news_fetcher.v` (variable: `ids`)

## Suggested Fix Approach

1. **Improve scope tracking in `autofree_scope_vars2()`:**
   ```v
   // In vlib/v/gen/c/autofree.v
   fn (mut g Gen) autofree_scope_vars2(...) {
       // Current: Marks all variables in scope for cleanup
       // Need: Only mark variables that were actually declared in C
       
       for _, obj in scope.objects {
           match obj {
               ast.Var {
                   // Add check: was this variable actually emitted to C?
                   if !g.was_var_emitted(obj.name) {
                       continue  // Skip if never declared
                   }
                   
                   // Add check: is variable still in scope?
                   if !g.is_var_in_scope(obj.name) {
                       continue  // Skip if out of scope
                   }
                   
                   g.autofree_variable(obj)
               }
           }
       }
   }
   ```

2. **Track emitted variables:**
   ```v
   // In Gen struct, add:
   mut:
       emitted_vars map[string]bool  // Track which vars were actually declared
   
   // When emitting a variable declaration:
   fn (mut g Gen) emit_var_decl(name string, ...) {
       g.write('${typ} ${name} = ...')
       g.emitted_vars[name] = true  // Mark as emitted
   }
   ```

3. **Better temporary variable handling:**
   ```v
   // Mark temporaries that get inlined and shouldn't be freed
   if obj.is_tmp && g.tmp_was_inlined(obj.name) {
       g.print_autofree_var(obj, 'temporary was inlined')
       continue
   }
   ```

4. **Scope boundary tracking:**
   - Track when entering/exiting scopes
   - Remove variables from cleanup list when scope exits
   - Don't add cleanup for variables from child scopes

## Testing Strategy

### Unit Test

Create `vlib/v/tests/autofree_scope_tracking_test.v`:
```v
fn test_nested_scope_vars() {
    s1 := 'outer'
    {
        s2 := 'inner'
        println(s2)
    }
    println(s1)
    // Should not try to free s2 here
}

fn test_temporary_in_expression() {
    result := if true { 'hello' } else { 'world' }
    println(result)
    // Should not try to free intermediate temporaries
}

fn test_flag_parser() {
    mut fp := flag.new_flag_parser(['program'])
    show_help := fp.bool('help', `h`, false, 'help')
    assert show_help == false
}

fn test_calculator_pattern() {
    input := '5 + 3'
    // Parse and evaluate (simplified)
    result := input.replace(' ', '')
    assert result == '5+3'
}
```

Compile with: `./v -autofree vlib/v/tests/autofree_scope_tracking_test.v`

### Regression Tests

```bash
# Test all currently failing examples
./v -autofree examples/animated_help_text.v -o /tmp/test && /tmp/test
./v -autofree examples/flag_layout_editor.v -o /tmp/test && /tmp/test
./v -autofree examples/mini_calculator.v -o /tmp/test && /tmp/test
./v -autofree examples/mini_calculator_recursive_descent.v -o /tmp/test && /tmp/test
./v -autofree examples/news_fetcher.v -o /tmp/test && /tmp/test
```

### Debug Output Test

```bash
# Use autofree debug flags to see what's being tracked
./v -autofree -d trace_autofree examples/animated_help_text.v -o /tmp/test 2>&1 | less
./v -autofree -print_autofree_vars examples/animated_help_text.v -o /tmp/test 2>&1
```

## Success Criteria

- [ ] All 5 affected examples compile successfully with `-autofree`
- [ ] No "undeclared identifier" errors in generated C code
- [ ] Scope tracking correctly identifies declared vs non-declared variables
- [ ] Temporary variables are properly excluded from cleanup
- [ ] Unit tests pass
- [ ] No regressions in existing autofree tests
- [ ] Debug output shows correct variable tracking

## Additional Context

**Why This is Complex:**
Unlike the other autofree issues which are about incorrect code generation, this one requires fixing the fundamental scope tracking logic. The compiler needs to understand:
- Which V variables actually become C variables
- When temporaries are inlined vs declared
- Scope boundaries and variable lifetimes

**Variables That Should Be Cleaned:**
- Explicitly declared variables in current scope
- Function parameters (in some cases)
- Variables that were actually emitted to C code

**Variables That Should NOT Be Cleaned:**
- Temporary variables that were optimized away
- Variables from child scopes (already cleaned)
- Variables that were inlined into expressions
- Compiler-generated temporaries that don't exist in C

## Pattern Analysis

Looking at the failing examples:
- `_t3`, `_t29`, `_t55` - These are compiler-generated temporaries
- `expr`, `input`, `ids` - These are V variables that might be in wrong scope

The first set suggests the compiler is tracking temporaries incorrectly.
The second set suggests scope boundary issues.

## References

- Main investigation: `AUTOFREE_ISSUES.md` (Issue Category #3)
- Reproduction guide: `AUTOFREE_REPRODUCTION_GUIDE.md`
- Related compiler code: `vlib/v/gen/c/autofree.v` (especially `autofree_scope_vars2()`)
- AST scope tracking: `vlib/v/ast/scope.v`

## Notes for Agent

This is the most complex autofree issue because it requires understanding and fixing the scope tracking logic. Start by:

1. Adding debug output to see which variables are being marked for cleanup
2. Comparing working vs non-working examples
3. Understanding when variables are emitted vs optimized away
4. Checking the `ast.Var` properties: `is_tmp`, `is_inherited`, `is_or`, etc.

The fix likely involves multiple changes:
- Better checking in `autofree_scope_vars2()`
- Tracking emitted variables in `Gen` struct
- Excluding certain variable categories from cleanup

Use `-d trace_autofree` and `-print_autofree_vars` flags extensively during debugging.
