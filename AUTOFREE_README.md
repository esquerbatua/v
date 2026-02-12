# V `-autofree` Flag Investigation

This directory contains a comprehensive investigation of all issues with the V compiler's `-autofree` flag.

## 📚 Documentation Files

| File | Size | Purpose |
|------|------|---------|
| [AUTOFREE_INVESTIGATION_SUMMARY.md](AUTOFREE_INVESTIGATION_SUMMARY.md) | 6.3 KB | **Start here** - Complete overview of investigation |
| [AUTOFREE_ISSUES.md](AUTOFREE_ISSUES.md) | 8.3 KB | Detailed issue descriptions for developers |
| [AUTOFREE_REPRODUCTION_GUIDE.md](AUTOFREE_REPRODUCTION_GUIDE.md) | 5.4 KB | Step-by-step reproduction instructions |
| [AUTOFREE_QUICK_REFERENCE.md](AUTOFREE_QUICK_REFERENCE.md) | 4.4 KB | Quick lookup for users |

**Total Documentation:** 864 lines, 24.4 KB

## 🎯 Quick Links

### For Users
- Want to know if `-autofree` works for your code? → [AUTOFREE_QUICK_REFERENCE.md](AUTOFREE_QUICK_REFERENCE.md)
- Need to debug an `-autofree` error? → [AUTOFREE_REPRODUCTION_GUIDE.md](AUTOFREE_REPRODUCTION_GUIDE.md)

### For Developers
- Want to fix `-autofree` bugs? → [AUTOFREE_ISSUES.md](AUTOFREE_ISSUES.md)
- Need the full investigation report? → [AUTOFREE_INVESTIGATION_SUMMARY.md](AUTOFREE_INVESTIGATION_SUMMARY.md)

### For Managers/Reviewers
- Want the executive summary? → [AUTOFREE_INVESTIGATION_SUMMARY.md](AUTOFREE_INVESTIGATION_SUMMARY.md#results)

## 📊 Key Statistics

- **Programs Tested:** 71
- **Success Rate:** 78.9% (56/71)
- **Issues Found:** 6 major categories
- **Documentation:** 4 comprehensive guides

## 🐛 Issue Categories

1. ❌ Invalid C Code Generation (match expressions)
2. ❌ Array Pointer Dereference Errors
3. ❌ Undeclared Identifier in Cleanup
4. ❌ Invalid Function Call Syntax
5. ⚠️ Result/Option Type Handling
6. ⚠️ Enum Declaration Issues

## ✅ What Works

- Simple programs (hello_world, fibonacci, primes)
- String operations
- Basic array and map operations
- Structs and methods
- Closures and recursion
- Simple match expressions

## ❌ What Doesn't Work

- Complex match expressions with sum types
- Array reassignments in certain contexts
- Nested conditionals as function arguments
- Some Result/Option or-block patterns

## 🚀 Quick Start

### Test if your program works with `-autofree`

```bash
# Compile with autofree
v -autofree program.v

# Run with autofree
v -autofree run program.v

# Debug autofree issues
v -autofree -g -keepc -cc clang program.v
```

### Expected Behavior

If compilation succeeds, your program works with `-autofree`! ✅

If compilation fails with C errors, check the [Quick Reference](AUTOFREE_QUICK_REFERENCE.md) to see if it's a known issue.

## 📖 Reading Guide

### Path 1: I'm a User
1. Read [Quick Reference](AUTOFREE_QUICK_REFERENCE.md) to see if your pattern is supported
2. If issues arise, check [Reproduction Guide](AUTOFREE_REPRODUCTION_GUIDE.md) for workarounds
3. Consider not using `-autofree` if your code matches known failing patterns

### Path 2: I'm a Developer
1. Read [Investigation Summary](AUTOFREE_INVESTIGATION_SUMMARY.md) for context
2. Read [Issues Document](AUTOFREE_ISSUES.md) for technical details
3. Use [Reproduction Guide](AUTOFREE_REPRODUCTION_GUIDE.md) to reproduce bugs
4. Fix issues starting with Priority 1 categories

### Path 3: I'm a Manager/Reviewer
1. Read [Investigation Summary](AUTOFREE_INVESTIGATION_SUMMARY.md)
2. Review the statistics and recommendations
3. Decide on prioritization based on impact analysis

## 🎓 Key Findings

The `-autofree` flag works well for simple programs (79% success rate) but has specific patterns that need fixes:

1. **Scope tracking** doesn't handle temporary variables correctly
2. **Match expressions** with complex returns confuse cleanup logic
3. **Array reassignments** have pointer indirection issues
4. **Function arguments** with complex expressions break cleanup

## 🔧 For Contributors

To help improve `-autofree`:

1. Pick an issue category from [AUTOFREE_ISSUES.md](AUTOFREE_ISSUES.md)
2. Use reproduction steps from [AUTOFREE_REPRODUCTION_GUIDE.md](AUTOFREE_REPRODUCTION_GUIDE.md)
3. Fix the issue in the affected compiler code
4. Add regression tests
5. Update documentation

Primary areas needing fixes:
- `vlib/v/gen/c/autofree.v`
- `vlib/v/gen/c/assign.v`
- `vlib/v/gen/c/fn.v`
- `vlib/v/gen/c/if.v`

## 📝 Investigation Details

- **Date:** February 12, 2026
- **Branch:** `copilot/investigate-autofree-errors`
- **Methodology:** Systematic testing of 71 programs
- **Tools Used:** V compiler, clang, TCC
- **Test Time:** ~30 minutes for full suite

## 🙏 Acknowledgments

Investigation performed by GitHub Copilot Agent as part of issue triage for the V programming language.

---

**Note:** The `-autofree` flag is experimental. These findings provide a roadmap for making it production-ready.
