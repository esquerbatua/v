# Issue #6: Enum Values Treated as Type Names with -autofree

**Category:** Type System Bug  
**Severity:** Medium  
**Status:** Open  
**Assignable to Agent:** Yes

## Problem Description

When the `-autofree` flag is enabled, the compiler generates incorrect C code where enum values or constant values are treated as type names in variable declarations, particularly in conditional expressions.

## Symptoms

**Compilation Error:**
```
error: expected ';' after expression
term__green _t1; /* if prepend */
           ^
           ;
```

**Error Pattern:**
The compiler generates invalid variable declarations like:
```c
term__green _t1; /* if prepend */
```

Where `term__green` is an enum value or function, not a type name. This should be:
```c
term__Color _t1; /* if prepend */
```

Or the variable declaration should be structured differently to avoid using the enum value as a type.

## Affected Files

**Test Case:**
- `examples/poll_coindesk_bitcoin_vs_usd_rate.v` - Uses term colors in conditionals

**Compiler Code to Fix:**
- `vlib/v/gen/c/autofree.v` - Temporary variable type determination
- `vlib/v/gen/c/cgen.v` - Type name generation
- Possibly `vlib/v/gen/c/if.v` - Conditional expression handling

## Root Cause

When autofree creates temporary variables for expressions in conditionals, it attempts to determine the variable's type. In some cases involving enum values or constants, it incorrectly uses:
- The enum *value* name instead of the enum *type* name
- A constant value instead of the constant's type
- A function name instead of the function's return type

This happens because the type resolution for temporaries doesn't properly distinguish between:
- Type names (e.g., `term__Color`)
- Value names (e.g., `term__green` which is a `term__Color` value)
- Function names (e.g., `term__green()` which returns a `term__Color`)

## Reproduction Steps

### Minimal Reproduction Code

Save as `test_enum_autofree.v`:

```v
module main

import term

fn main() {
    rate_diff := 1.5
    
    // Conditional using enum function
    color := if rate_diff > 0 {
        term.green
    } else {
        term.red
    }
    
    println(color('Rate: ${rate_diff}'))
}
```

Or simpler with custom enum:

```v
enum Color {
    red
    green
    blue
}

fn main() {
    x := 5
    
    // Conditional expression with enum values
    color := if x > 0 {
        Color.green
    } else {
        Color.red
    }
    
    println('Color: ${color}')
}
```

### Compilation Commands

```bash
# Build V compiler if needed
make

# Reproduce with real example
./v -autofree -cc clang examples/poll_coindesk_bitcoin_vs_usd_rate.v -o /tmp/test

# Reproduce with minimal example
./v -autofree -cc clang test_enum_autofree.v -o /tmp/test

# Get detailed error
./v -autofree -g -keepc -cc clang test_enum_autofree.v -o /tmp/test

# Inspect generated C
cat /tmp/v_*/test.tmp.c | grep "term__green" -A 5 -B 5
cat /tmp/v_*/test.tmp.c | grep "_t1" -A 3 -B 3
```

### Expected vs Actual

**Expected:** Correct type name in declaration
```c
// Correct type: term__Color (the enum type)
term__Color _t1; /* if prepend */

if (rate_diff > 0) {
    _t1 = term__green;  // Assign enum value
} else {
    _t1 = term__red;
}
```

Or even better, no temporary needed:
```c
// Direct ternary
term__Color color = (rate_diff > 0) ? term__green : term__red;
```

**Actual:** Enum value used as type name
```c
// Wrong: term__green is a value, not a type
term__green _t1; /* if prepend */
```

## Affected Examples

The following examples fail with this issue:
- `examples/poll_coindesk_bitcoin_vs_usd_rate.v` - Term color conditionals

Potentially other examples using:
- Enum values in conditional expressions
- Constant values in if-expressions
- Function references in conditionals

## Suggested Fix Approach

1. **Fix type determination for temporaries:**
   ```v
   // In vlib/v/gen/c/autofree.v or cgen.v
   fn (mut g Gen) get_temp_var_type(expr ast.Expr) string {
       // WRONG: Using expr value name
       // return expr.str()
       
       // RIGHT: Get the actual type
       typ := g.table.type_to_str(expr.typ)
       return typ
   }
   ```

2. **Use proper type resolution:**
   ```v
   // When generating temporary for conditional
   match expr {
       ast.Ident {
           // expr.name might be 'term__green' (value)
           // expr.typ is the actual type
           typ := g.table.type_to_str(expr.typ)
           g.write('${typ} ${temp_var};')
           // NOT: g.write('${expr.name} ${temp_var};')
       }
       ast.CallExpr {
           // expr.name is function name
           // expr.return_type is what we need
           typ := g.table.type_to_str(expr.return_type)
           g.write('${typ} ${temp_var};')
       }
   }
   ```

3. **Avoid unnecessary temporaries:**
   ```v
   // For simple conditionals with enum values, use ternary directly
   if is_simple_conditional(node) {
       g.write('(')
       g.expr(node.cond)
       g.write(') ? ')
       g.expr(node.if_expr)
       g.write(' : ')
       g.expr(node.else_expr)
       // No temporary needed!
   }
   ```

4. **Code location to check:**
   Look for where `_t*` variables are declared for conditionals:
   ```v
   // Search for patterns like:
   g.writeln('${type_name} _t${temp_num}; /* if prepend */')
   
   // Ensure type_name comes from expr.typ, not expr.name
   ```

## Testing Strategy

### Unit Test

Create `vlib/v/tests/autofree_enum_conditional_test.v`:
```v
enum Color {
    red
    green
    blue
}

enum Status {
    ok
    error
    pending
}

fn test_enum_in_conditional() {
    x := 5
    color := if x > 0 {
        Color.green
    } else {
        Color.red
    }
    assert color == Color.green
}

fn test_enum_in_match() {
    x := 10
    status := match true {
        x > 0 { Status.ok }
        else { Status.error }
    }
    assert status == Status.ok
}

fn test_enum_function_conditional() {
    import term
    
    rate := 1.5
    color_fn := if rate > 0 {
        term.green
    } else {
        term.red
    }
    
    msg := color_fn('positive')
    assert msg.contains('positive')
}

fn test_nested_enum_conditional() {
    x := 5
    y := 10
    
    color := if x > 0 {
        if y > 5 {
            Color.blue
        } else {
            Color.green
        }
    } else {
        Color.red
    }
    
    assert color == Color.blue
}
```

Compile with: `./v -autofree vlib/v/tests/autofree_enum_conditional_test.v`

### Regression Test

```bash
# Test the actual failing example
./v -autofree examples/poll_coindesk_bitcoin_vs_usd_rate.v -o /tmp/test

# It requires network, so may not run, but should compile
/tmp/test || echo "Network error is OK, important thing is it compiled"
```

### Type Resolution Test

```bash
# Create a test with various enum patterns
cat > /tmp/enum_types_test.v << 'EOF'
enum MyEnum {
    value_a
    value_b
    value_c
}

fn get_enum(x int) MyEnum {
    return if x > 0 { MyEnum.value_a } else { MyEnum.value_b }
}

fn main() {
    e1 := get_enum(5)
    e2 := if e1 == MyEnum.value_a {
        MyEnum.value_c
    } else {
        MyEnum.value_b
    }
    println('e1: ${e1}, e2: ${e2}')
}
EOF

./v -autofree /tmp/enum_types_test.v -o /tmp/test
/tmp/test
# Expected: "e1: value_a, e2: value_c"
```

## Success Criteria

- [ ] `examples/poll_coindesk_bitcoin_vs_usd_rate.v` compiles successfully with `-autofree`
- [ ] Generated C code uses correct type names (not enum value names)
- [ ] Enum conditional expressions work correctly
- [ ] Unit tests pass
- [ ] No regressions in existing autofree tests
- [ ] Term color functions work correctly with `-autofree`

## Additional Context

**Why This Happens:**
When the compiler generates code for conditional expressions, it sometimes creates temporary variables to hold intermediate results. The bug is in how it determines the *type* of these temporaries:

- It should use `expr.typ` (the type)
- Instead it uses `expr.name` or `expr.str()` (the value/function name)

**Enum Background in V:**
```v
enum Color {
    red    // This is an enum VALUE
    green  // This is an enum VALUE
}

// Color is the TYPE
// Color.red is a VALUE of type Color
```

In C, this becomes:
```c
typedef enum {
    Color__red,    // Value
    Color__green,  // Value
} Color;           // Type
```

**Related Code Patterns That Work:**
- Simple enum assignments: `color := Color.red`
- Enum comparisons: `if color == Color.red`
- Enum returns from functions: `fn get_color() Color`

**Related Code Patterns That Fail:**
- Enum values in conditional expressions with `-autofree`
- Function references returning enums in conditionals
- Constants in if-expressions

## Similar Issues

This is similar to Issue #3 (Undeclared Identifier) but the root cause is different:
- Issue #3: Variable doesn't exist
- Issue #6: Variable declaration uses wrong type name

## References

- Main investigation: `AUTOFREE_ISSUES.md` (Issue Category #6)
- Reproduction guide: `AUTOFREE_REPRODUCTION_GUIDE.md`
- Related compiler code: `vlib/v/gen/c/autofree.v`, `vlib/v/gen/c/if.v`
- V enum documentation

## Notes for Agent

This is a type resolution issue. The fix should be straightforward once you find where temporary variable types are determined for conditional expressions.

Key debugging steps:
1. Find where `_t1` variables are declared for if-expressions
2. Check how the type name is obtained (likely wrong)
3. Fix it to use the actual type instead of value/function name

Search for patterns like:
- `/* if prepend */` in generated C (from the error message)
- Generation of `_t*` variables in if-expression handling
- Type to string conversion for temporaries

The fix is likely a one-line change from using a value name to using the type, but finding that line requires understanding the cgen flow for conditionals.

Use `-keepc` to examine generated C and trace back to where the wrong type name comes from.
