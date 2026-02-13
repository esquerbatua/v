# V Compiler `-autofree` Flag - Investigation Summary

**Date:** February 12, 2026  
**Branch:** `copilot/investigate-autofree-errors`  
**Status:** Investigation Complete ✅

## Objective

Investigate all possible errors that occur when using the `-autofree` flag to compile V programs and create a comprehensive list of issues for future fixes.

## Methodology

1. Built V compiler from source
2. Systematically tested 71 V programs with `-autofree` flag
3. Categorized and analyzed all compilation errors
4. Documented error patterns and root causes
5. Created reproduction steps and workarounds

## Test Coverage

- **Single-file examples:** 68 programs
- **Multi-file examples:** 3 programs  
- **Existing autofree tests:** 4 tests (all passed)
- **Total programs tested:** 71

## Results

### Overall Statistics

| Metric | Count | Percentage |
|--------|-------|------------|
| ✅ Compiled Successfully | 56 | 78.9% |
| ❌ Failed to Compile | 15 | 21.1% |
| **Total Tested** | **71** | **100%** |

### Issues Discovered

**6 Major Issue Categories:**

1. **Invalid C Code Generation** (High Severity)
   - Match expressions generate `_t = if (...)` syntax
   - Affects sum types with complex conditionals
   - Example: `binary_search_tree.v`

2. **Array Pointer Dereference** (High Severity)
   - Missing dereference operator in cleanup code
   - Generates `array var = ptr` instead of `array var = *ptr`
   - Affects: `pidigits.v`, `rule110.v`, `vpwgen.v`

3. **Undeclared Identifier** (High Severity)
   - Attempts to free non-existent variables
   - Scope tracking issues with temporary variables
   - Affects: `animated_help_text.v`, `flag_layout_editor.v`, `mini_calculator.v`, and more

4. **Invalid Function Call Syntax** (High Severity)
   - Cleanup code breaks function argument expressions
   - Affects: `fizz_buzz.v`, `random_ips.v`

5. **Result/Option Type Handling** (Medium Severity)
   - Issues with `!` and `?` types in or-blocks
   - Affects: `net_raw_http.v`, `random_ips.v`

6. **Enum Declaration Issues** (Medium Severity)
   - Enum values treated as type names
   - Affects: `poll_coindesk_bitcoin_vs_usd_rate.v`

## Documentation Delivered

### 1. AUTOFREE_ISSUES.md (8.3 KB)
Comprehensive issue report including:
- Executive summary with statistics
- Detailed description of each issue category
- Error patterns and generated C code examples
- Root cause analysis
- Prioritized recommendations
- List of successfully compiled programs

### 2. AUTOFREE_REPRODUCTION_GUIDE.md (5.4 KB)
Step-by-step reproduction guide including:
- Prerequisites and setup
- Reproduction commands for each issue
- Expected error messages
- Minimal reproduction code examples
- Testing strategies
- Debug commands

### 3. AUTOFREE_QUICK_REFERENCE.md (4.4 KB)
Quick reference guide including:
- Feature support matrix
- Issue summaries with workarounds
- Testing checklist
- Debug commands
- Usage guidelines
- Success rate statistics

## Key Findings

### What Works ✅

- Simple programs (hello_world, fibonacci, primes)
- String operations (concatenation, interpolation)
- Basic array and map operations
- Struct operations (init, methods)
- Closures and function values
- Recursion
- Simple match expressions

### What Doesn't Work ❌

- Complex match expressions with sum types
- Array reassignments in certain contexts
- Nested conditionals as function arguments
- Some Result/Option or-block patterns
- Complex flag/CLI parsing patterns

## Root Causes

The issues stem from three main areas:

1. **Scope Tracking** (`vlib/v/gen/c/autofree.v`)
   - `autofree_scope_vars2()` doesn't correctly track temporary variables
   - Variables optimized away still marked for cleanup
   - Expression temporaries not properly excluded

2. **Expression Handling**
   - Match expressions with complex returns confuse cleanup logic
   - Ternary and nested expressions cause incorrect insertion points
   - Result/Option unwrapping creates untracked temporaries

3. **C Code Generation Ordering**
   - Cleanup code inserted before variable declarations complete
   - Function argument cleanup interferes with evaluation
   - Array reassignment doesn't handle pointer indirection

## Recommendations

### Priority 1 (Critical)
1. Fix `_t = if (...)` bug in match expressions
2. Fix array pointer dereference in reassignments
3. Fix undeclared identifier scope tracking

### Priority 2 (Important)
4. Fix function argument cleanup generation
5. Fix Result/Option type handling
6. Fix enum value handling in conditionals

### Priority 3 (Enhancement)
7. Add autofree tests for complex scenarios
8. Create regression tests for each bug
9. Add valgrind integration tests

### Priority 4 (Documentation)
10. Document `-autofree` limitations
11. Add pattern examples (work/don't work)
12. Improve error messages

## Impact Analysis

- **Current Usability:** Suitable for simple programs (79% success rate)
- **Production Readiness:** Not recommended (still experimental)
- **Code Coverage:** Good coverage of standard library usage
- **Blocking Issues:** 6 categories need fixes before general use

## Affected Compiler Code

Primary areas requiring fixes:
- `vlib/v/gen/c/autofree.v` - Main autofree logic
- `vlib/v/gen/c/assign.v` - Array reassignment handling
- `vlib/v/gen/c/fn.v` - Function argument handling
- `vlib/v/gen/c/if.v` - Conditional expression handling

## Next Steps

1. Share documentation with V core team
2. Create GitHub issues for each category
3. Prioritize fixes based on impact
4. Add regression tests for each fix
5. Update documentation as fixes are implemented

## Conclusion

The `-autofree` flag shows strong potential for automatic memory management in V, with a 79% success rate on real-world examples. However, 6 specific code generation patterns need to be fixed before it can be recommended for general use. The issues are well-documented and reproducible, providing a clear roadmap for improvement.

With focused fixes on match expressions, array reassignments, and scope tracking, the success rate could approach 100%, making `-autofree` a viable option for most V programs.

---

## Files in Repository

- `AUTOFREE_ISSUES.md` - Comprehensive issue report
- `AUTOFREE_REPRODUCTION_GUIDE.md` - Step-by-step reproduction
- `AUTOFREE_QUICK_REFERENCE.md` - Quick lookup guide
- `AUTOFREE_INVESTIGATION_SUMMARY.md` - This summary

## Investigation By

GitHub Copilot Agent  
Branch: `copilot/investigate-autofree-errors`
