# V Compiler `-autofree` Issues - Reproduction Guide

This guide provides step-by-step instructions to reproduce each category of `-autofree` bugs.

## Prerequisites

```bash
# Build the V compiler
make
./v -g -keepc -o ./vnew cmd/v
```

## Issue 1: Invalid Assignment to `if` Statement

**File:** `examples/binary_search_tree.v`

```bash
# Reproduce with TCC (basic error)
./vnew -autofree examples/binary_search_tree.v -o /tmp/test

# Reproduce with Clang (detailed error with line numbers)
./vnew -autofree -g -keepc -cc clang examples/binary_search_tree.v -o /tmp/test
```

**Expected Error:**
```
error: expected expression
_t3 = if (x == (*tree._main__Node_T_f64).value) {
      ^
```

**Minimal Reproduction:**
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

---

## Issue 2: Array Pointer Dereference Error

**File:** `examples/pidigits.v`

```bash
# Reproduce
./vnew -autofree -g -keepc -cc clang examples/pidigits.v -o /tmp/test
```

**Expected Error:**
```
error: initializing 'array' with an expression of incompatible type 'Array_u64 *'; dereference with *
array _sref1290 = (remainder); // free array on re-assignment2
      ^           ~~~~~~~~~~~
```

**Also Affected:**
```bash
./vnew -autofree -cc clang examples/rule110.v -o /tmp/test
./vnew -autofree -cc clang examples/vpwgen.v -o /tmp/test
```

---

## Issue 3: Undeclared Identifier in Autofree

**File:** `examples/animated_help_text.v`

```bash
# Reproduce
./vnew -autofree -cc clang examples/animated_help_text.v -o /tmp/test
```

**Expected Error:**
```
error: use of undeclared identifier '_t3'
builtin__string_free(&_t3); // autofreed var flag false
                     ^
```

**Also Affected:**
```bash
./vnew -autofree -cc clang examples/flag_layout_editor.v -o /tmp/test
./vnew -autofree -cc clang examples/mini_calculator.v -o /tmp/test
./vnew -autofree -cc clang examples/mini_calculator_recursive_descent.v -o /tmp/test
./vnew -autofree -cc clang examples/news_fetcher.v -o /tmp/test
```

---

## Issue 4: Invalid Function Call Syntax

**File:** `examples/fizz_buzz.v`

```bash
# Reproduce
./vnew -autofree -cc clang examples/fizz_buzz.v -o /tmp/test
```

**Expected Error:**
```
error: use of undeclared identifier '_expr_println_1_21'
string _arg_expr_println_1_21 = _expr_println_1_21)(...)
                                ^
```

**Minimal Reproduction:**
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

---

## Issue 5: Result/Option Type Handling

**File:** `examples/net_raw_http.v`

```bash
# Reproduce
./vnew -autofree -cc clang examples/net_raw_http.v -o /tmp/test
```

**Expected Error:**
```
error: use of undeclared identifier '_t2'
string _arg_expr_println_1_139 = (_t2.is_error) { ... }
                                  ^
```

**Minimal Reproduction:**
```v
import net

fn main() {
    conn := net.dial_tcp('google.com:80') or {
        println('Failed to connect')
        return
    }
    println('Connected')
}
```

---

## Issue 6: Enum/Type Declaration Issues

**File:** `examples/poll_coindesk_bitcoin_vs_usd_rate.v`

```bash
# Reproduce
./vnew -autofree -cc clang examples/poll_coindesk_bitcoin_vs_usd_rate.v -o /tmp/test
```

**Expected Error:**
```
error: expected ';' after expression
term__green _t1; /* if prepend */
           ^
```

---

## Testing Strategy

### Quick Sanity Test
```bash
# Test a working example
./vnew -autofree run examples/hello_world.v

# Test a failing example
./vnew -autofree examples/binary_search_tree.v
```

### Comprehensive Test
```bash
# Run the test script to check all examples
bash /tmp/comprehensive_autofree_test.sh > autofree_test_results.txt
```

### Individual Debug
```bash
# For detailed investigation, use -g -keepc to preserve generated C
./vnew -autofree -g -keepc -cc clang examples/file.v -o /tmp/test

# Then inspect the generated C code
cat /tmp/v_1001/*.tmp.c | grep -A 10 "line_number_from_error"
```

---

## Expected Success Cases

These programs should compile successfully with `-autofree`:

```bash
./vnew -autofree run examples/hello_world.v
./vnew -autofree run examples/fibonacci.v 10
./vnew -autofree run examples/hanoi.v
./vnew -autofree run examples/euler.v
./vnew -autofree run examples/quick_sort.v
./vnew -autofree run examples/sudoku.v
./vnew -autofree run examples/primes.v
./vnew -autofree run examples/json.v
./vnew -autofree run examples/cli.v
```

---

## Notes

1. Using `-cc clang` instead of default TCC often provides better error messages
2. Adding `-g` preserves V source line numbers in error messages
3. Adding `-keepc` preserves generated C code in `/tmp/v_*/` for inspection
4. Some errors cascade - fixing one may reveal others
5. The `-autofree` flag is experimental and not enabled by default
