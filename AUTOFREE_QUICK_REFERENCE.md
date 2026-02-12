# `-autofree` Quick Reference

## What is `-autofree`?

The `-autofree` flag enables automatic memory management in V by inserting free calls for heap-allocated data (strings, arrays, maps, structs with `.free()` methods).

**Status:** Experimental (not enabled by default)

## Usage

```bash
# Compile with autofree
v -autofree program.v

# Run with autofree
v -autofree run program.v

# Debug autofree issues
v -autofree -g -keepc -cc clang program.v
```

## Quick Status Check

| Category | Works? | Notes |
|----------|--------|-------|
| Simple programs | ✅ Yes | hello_world, fibonacci, primes |
| String operations | ✅ Yes | Concatenation, interpolation |
| Array operations | ✅ Yes | Most operations work |
| Map operations | ✅ Yes | Basic map usage |
| Structs | ✅ Yes | Initialization and methods |
| Closures | ✅ Yes | Function values work |
| Recursion | ✅ Yes | Factorial, Hanoi, etc. |
| Simple match | ✅ Yes | Basic pattern matching |
| **Complex match with sum types** | ❌ No | **Issue #1** |
| **Array reassignments** | ❌ No | **Issue #2** |
| **Nested conditionals in println** | ❌ No | **Issue #4** |
| **Result/Option in or-blocks** | ⚠️ Partial | **Issue #5** |

## Known Issues (Quick Reference)

### Issue #1: Match Expression Bug
**Symptom:** `error: expected expression` with `_t3 = if (...)`  
**Trigger:** Match expressions with sum types and complex conditions  
**Example:** `binary_search_tree.v`  
**Workaround:** Avoid complex nested matches with `-autofree`

### Issue #2: Array Pointer Bug
**Symptom:** `error: initializing 'array' with expression of type 'Array_* *'`  
**Trigger:** Array reassignments  
**Example:** `pidigits.v`, `rule110.v`  
**Workaround:** None currently

### Issue #3: Undeclared Identifier
**Symptom:** `error: use of undeclared identifier '_tN'`  
**Trigger:** Complex flag/CLI parsing patterns  
**Example:** `animated_help_text.v`, `flag_layout_editor.v`  
**Workaround:** Simplify conditional expressions

### Issue #4: Function Arg Cleanup
**Symptom:** `error: expected ';' at end of declaration`  
**Trigger:** Complex expressions as function arguments  
**Example:** `fizz_buzz.v`  
**Workaround:** Extract complex expressions to variables first

### Issue #5: Result/Option Bug
**Symptom:** `error: use of undeclared identifier` in or-blocks  
**Trigger:** Result (`!`) or Option (`?`) types with or-blocks  
**Example:** `net_raw_http.v`  
**Workaround:** Use simpler error handling patterns

### Issue #6: Enum Declaration Bug
**Symptom:** `error: expected ';' after expression` with enum values  
**Trigger:** Enum values in conditional variable initialization  
**Example:** `poll_coindesk_bitcoin_vs_usd_rate.v`  
**Workaround:** Assign enum values outside conditionals

## Testing Checklist

Before using `-autofree` in your project:

- [ ] Test with simple examples first
- [ ] Check if you use sum types with complex match expressions
- [ ] Check for array reassignments
- [ ] Check for Result/Option types with or-blocks
- [ ] Check for complex expressions in function arguments
- [ ] Run with `-g -keepc` to debug any C compilation errors
- [ ] Consider running without `-autofree` if issues persist

## Debug Commands

```bash
# Get detailed error info
v -autofree -g -cc clang program.v 2>&1 | less

# Keep C code for inspection
v -autofree -g -keepc program.v
ls /tmp/v_*/program.tmp.c

# Test without autofree
v program.v  # Should work if code is correct

# Print autofree debug info
v -autofree -d trace_autofree program.v
```

## Success Rate

Based on 71 example programs tested:
- **78.9%** compile successfully with `-autofree`
- **21.1%** fail due to known bugs

## When to Use `-autofree`

**Good candidates:**
- Simple utilities and scripts
- Programs with straightforward data flow
- Code without complex match expressions
- Programs you've tested thoroughly

**Avoid for now:**
- Production code (still experimental)
- Code with complex sum types and match
- Code with heavy array reassignments
- Code you haven't tested with `-autofree`

## Related Flags

```bash
# Print which variables aren't freed
v -autofree -print_autofree_vars program.v

# Print unfree vars in specific function
v -autofree -print_autofree_vars_in_fn:main program.v

# Disable autofree (explicit)
v -manualfree program.v
```

## More Information

- Full issue details: See `AUTOFREE_ISSUES.md`
- Reproduction steps: See `AUTOFREE_REPRODUCTION_GUIDE.md`
- Report bugs: https://github.com/vlang/v/issues
