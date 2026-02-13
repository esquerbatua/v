# V Compiler -autofree Issues - Agent Task Index

This directory contains individual, standalone issue documents that can be assigned to agents for fixing. Each document is self-contained with all necessary information to understand and fix the issue.

## 🎯 Purpose

Each issue document is designed to be:
- **Standalone** - Contains all context needed to understand and fix the issue
- **Actionable** - Includes reproduction steps, suggested fixes, and test strategies
- **Agent-ready** - Can be passed directly to an AI agent or developer

## 📋 Issue List

### High Severity Issues (Must Fix)

1. **[AUTOFREE_ISSUE_001_MATCH_EXPRESSION.md](AUTOFREE_ISSUE_001_MATCH_EXPRESSION.md)**
   - **Problem:** Invalid C code generation (`_t = if (...)`) in match expressions
   - **Affects:** `examples/binary_search_tree.v`
   - **Complexity:** Medium-High
   - **Files to fix:** `vlib/v/gen/c/autofree.v`, `vlib/v/gen/c/cgen.v`

2. **[AUTOFREE_ISSUE_002_ARRAY_DEREFERENCE.md](AUTOFREE_ISSUE_002_ARRAY_DEREFERENCE.md)**
   - **Problem:** Missing pointer dereference in array cleanup code
   - **Affects:** `examples/pidigits.v`, `examples/rule110.v`, `examples/vpwgen.v`
   - **Complexity:** Low-Medium
   - **Files to fix:** `vlib/v/gen/c/assign.v`, `vlib/v/gen/c/autofree.v`

3. **[AUTOFREE_ISSUE_003_UNDECLARED_IDENTIFIER.md](AUTOFREE_ISSUE_003_UNDECLARED_IDENTIFIER.md)**
   - **Problem:** Cleanup code references non-existent variables
   - **Affects:** `examples/animated_help_text.v`, `examples/flag_layout_editor.v`, and 3 more
   - **Complexity:** High
   - **Files to fix:** `vlib/v/gen/c/autofree.v` (scope tracking)

4. **[AUTOFREE_ISSUE_004_FUNCTION_CALL_SYNTAX.md](AUTOFREE_ISSUE_004_FUNCTION_CALL_SYNTAX.md)**
   - **Problem:** Cleanup code breaks function call argument expressions
   - **Affects:** `examples/fizz_buzz.v`, `examples/random_ips.v`
   - **Complexity:** Medium-High
   - **Files to fix:** `vlib/v/gen/c/fn.v`, `vlib/v/gen/c/autofree.v`

### Medium Severity Issues (Should Fix)

5. **[AUTOFREE_ISSUE_005_RESULT_OPTION_HANDLING.md](AUTOFREE_ISSUE_005_RESULT_OPTION_HANDLING.md)**
   - **Problem:** Result/Option type temporaries not tracked correctly in or-blocks
   - **Affects:** `examples/net_raw_http.v`, `examples/random_ips.v`
   - **Complexity:** Medium-High
   - **Files to fix:** `vlib/v/gen/c/autofree.v`, `vlib/v/gen/c/cgen.v`

6. **[AUTOFREE_ISSUE_006_ENUM_DECLARATION.md](AUTOFREE_ISSUE_006_ENUM_DECLARATION.md)**
   - **Problem:** Enum values used as type names in variable declarations
   - **Affects:** `examples/poll_coindesk_bitcoin_vs_usd_rate.v`
   - **Complexity:** Low-Medium
   - **Files to fix:** `vlib/v/gen/c/autofree.v`, `vlib/v/gen/c/if.v`

## 📊 Statistics

- **Total Issues:** 6
- **High Severity:** 4 issues
- **Medium Severity:** 2 issues
- **Total Affected Examples:** 15 files
- **Current Success Rate:** 78.9% (56/71 programs compile)
- **Target Success Rate:** ~100% after fixes

## 🔧 Recommended Fix Order

### Phase 1: Quick Wins (Estimated: 1-2 days each)
1. **Issue #2** (Array Dereference) - Straightforward pointer fix
2. **Issue #6** (Enum Declaration) - Simple type resolution fix

### Phase 2: Medium Complexity (Estimated: 2-4 days each)
3. **Issue #4** (Function Call Syntax) - Reorder code generation
4. **Issue #1** (Match Expression) - Fix cleanup insertion point
5. **Issue #5** (Result/Option) - Improve temporary tracking

### Phase 3: Complex (Estimated: 5-7 days)
6. **Issue #3** (Undeclared Identifier) - Requires scope tracking overhaul

## 📖 Document Structure

Each issue document contains:

### 1. Problem Description
Clear explanation of what's broken and why it matters

### 2. Symptoms
- Compilation error messages
- Error patterns in generated C code

### 3. Affected Files
- Test cases that reproduce the issue
- Compiler code that needs fixing

### 4. Root Cause
Technical explanation of why the bug occurs

### 5. Reproduction Steps
- Minimal reproduction code
- Compilation commands
- Expected vs actual behavior

### 6. Suggested Fix Approach
Step-by-step guidance on how to fix the issue with code examples

### 7. Testing Strategy
- Unit tests to create
- Regression tests to run
- Success criteria

### 8. Additional Context
- Related patterns that work/fail
- References to other documentation
- Notes for the agent/developer

## 🚀 How to Use These Documents

### For AI Agents

```bash
# Pass the issue document directly to the agent
cat AUTOFREE_ISSUE_00X_NAME.md | agent-cli fix

# Or reference it in a prompt
"Please fix the issue described in AUTOFREE_ISSUE_002_ARRAY_DEREFERENCE.md"
```

### For Human Developers

1. Pick an issue based on priority and complexity
2. Read the entire issue document
3. Set up reproduction environment
4. Follow the suggested fix approach
5. Implement tests from testing strategy
6. Verify all success criteria are met

### For Project Managers

- Use this index to assign issues to team members
- Track progress using the issue numbers
- Estimate effort using the complexity ratings
- Monitor overall progress toward 100% success rate

## 🔗 Related Documentation

- **[AUTOFREE_INVESTIGATION_SUMMARY.md](AUTOFREE_INVESTIGATION_SUMMARY.md)** - Complete investigation report
- **[AUTOFREE_ISSUES.md](AUTOFREE_ISSUES.md)** - Detailed technical analysis of all issues
- **[AUTOFREE_REPRODUCTION_GUIDE.md](AUTOFREE_REPRODUCTION_GUIDE.md)** - Step-by-step reproduction for all issues
- **[AUTOFREE_QUICK_REFERENCE.md](AUTOFREE_QUICK_REFERENCE.md)** - Quick lookup guide for users
- **[AUTOFREE_README.md](AUTOFREE_README.md)** - Master README with navigation

## 🎓 Tips for Success

### Before Starting
- Read the full investigation summary to understand the big picture
- Build the V compiler with debug flags: `./v -g -keepc -o ./vnew cmd/v`
- Familiarize yourself with the affected examples

### During Development
- Use `-keepc` flag to inspect generated C code
- Compare working vs non-working patterns
- Add debug output to trace code generation
- Test incrementally with minimal examples

### After Implementation
- Run all tests in the issue document
- Check for regressions in existing autofree tests
- Update documentation if behavior changes
- Consider adding more test cases

## 📞 Support

- **General Questions:** See `AUTOFREE_README.md`
- **Technical Details:** See `AUTOFREE_ISSUES.md`
- **Reproduction Help:** See `AUTOFREE_REPRODUCTION_GUIDE.md`
- **Bug Reports:** Create GitHub issues with reference to issue number

## ✅ Completion Criteria

An issue is considered fixed when:
- [ ] All affected examples compile successfully with `-autofree`
- [ ] Generated C code is syntactically correct
- [ ] All unit tests pass
- [ ] No memory leaks (verified with valgrind if applicable)
- [ ] No regressions in existing autofree tests
- [ ] Documentation is updated if needed

## 🏆 Success Metrics

After all issues are fixed:
- Success rate should be ~100% (up from 78.9%)
- All 71 tested programs should compile
- `-autofree` flag ready for production use
- V automatic memory management fully functional

---

**Last Updated:** February 12, 2026  
**Investigation Branch:** `copilot/investigate-autofree-errors`  
**Total Documentation:** 6 issue documents + supporting files
