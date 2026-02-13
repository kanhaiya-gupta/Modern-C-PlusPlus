# Lambdas

A **lambda** is an anonymous function object: you define it at the call site and the compiler generates a closure type that can be called like a function. Lambdas are used with algorithms, callbacks, and concurrency. This document covers syntax, capture, and how they relate to `std::function` and overloads.

---

## 1. Basic syntax

A lambda has:

- **Capture list** `[]` — what (if any) from the surrounding scope is captured.
- **Parameters** `(params)` — like a function (optional if no params).
- **Body** `{ ... }` — the code to run.
- Optional **trailing return type** `-> T`.
- Optional **specifiers**: `mutable`, `constexpr`, `noexcept`.

```cpp
auto f = [](int x, int y) { return x + y; };
int r = f(1, 2);  // 3

// No parameters
auto g = [] { return 42; };

// Trailing return type (when inference isn't enough)
auto h = [](int x) -> double { return x * 1.5; };
```

If the body is a single `return` expression, you can omit the braces and the return type is deduced.

---

## 2. Capture list

The capture list says how the lambda gets access to variables from the enclosing scope.

| Capture | Meaning |
|--------|--------|
| `[]` | Capture nothing |
| `[=]` | Capture all by value (deprecated in some contexts; prefer explicit) |
| `[&]` | Capture all by reference (dangerous if lambda outlives scope) |
| `[x, &y]` | Capture `x` by value, `y` by reference |
| `[=, &ref]` | Capture all by value except `ref` by reference |
| `[&, copy]` | Capture all by reference except `copy` by value |
| `[this]` or `[=]` | Capture current object (pointer) for use in member context |
| `[*this]` (C++17) | Capture a copy of the current object |

**By value** `[x]`: the lambda gets a copy; changes inside the lambda don’t affect the original.  
**By reference** `[&x]`: the lambda uses the original; the variable must outlive the lambda.

```cpp
int a = 1, b = 2;
auto byVal = [a, b]() { return a + b; };   // copies
auto byRef = [&a, &b]() { return a + b; }; // references; a,b must live longer than lambda
```

Prefer explicit captures (`[x, &y]`) over `[=]` or `[&]` so lifetime and mutability are clear.

---

## 3. mutable

By default, the **operator()** of the generated closure is const: you cannot modify copies captured by value. **mutable** makes the body non-const so you can modify those copies (not the originals).

```cpp
int n = 0;
auto inc = [n]() mutable { return ++n; };
inc();  // returns 1; internal copy of n is 1
inc();  // returns 2
// n is still 0 in the outer scope
```

---

## 4. Return type

If the body is a single `return expr;`, the return type is deduced from `expr`. For multiple returns or when you want a different type, use a trailing return type:

```cpp
auto f = [](int x) -> long { return x * 2L; };
```

---

## 5. Lambdas as callables

Lambdas can be stored in **std::function** or passed to templates that accept callables (e.g. algorithms). See [Functions](functions.md) (std::function) and [Templates](templates.md).

```cpp
#include <functional>
#include <algorithm>
#include <vector>

std::function<int(int, int)> op = [](int a, int b) { return a + b; };
std::vector<int> v = {3, 1, 4, 1, 5};
std::sort(v.begin(), v.end(), [](int a, int b) { return a > b; });
```

---

## 6. Generic lambdas (C++14)

If a parameter is **auto**, the lambda becomes a template: the compiler generates an overload for each type used.

```cpp
auto add = [](auto a, auto b) { return a + b; };
add(1, 2);      // int
add(1.0, 2.0);  // double
add(std::string("a"), "b");  // std::string + const char*
```

---

## 7. constexpr and noexcept (C++17)

You can mark a lambda **constexpr** or **noexcept**. It is constexpr if the body satisfies constexpr rules.

```cpp
constexpr auto sq = [](int x) constexpr { return x * x; };
constexpr int n = sq(10);  // 100 at compile time
```

---

## 8. Capturing *this (C++17)

**[*this]** captures a copy of the current object. Use when the lambda might outlive the object (e.g. stored in a queue or callback) so you don’t hold a dangling `this`.

```cpp
class Worker {
    int id_;
public:
    auto getCallback() {
        return [*this]() { return id_; };  // safe if callback runs later
    }
};
```

---

## 9. Common pitfalls

- **Capturing by reference and using after scope**: if the lambda outlives the variable (e.g. stored or run on another thread), the reference dangles. Prefer by-value or ensure the referenced object outlives the lambda.
- **Default capture [=] or [&]**: can capture more than you intend (including `this` with [=]) and hide lifetime issues. Prefer explicit captures.
- **Modifying captured-by-value without mutable**: use `mutable` if you need to change the copy inside the lambda.

---

## 10. Quick reference

| Syntax | Meaning |
|--------|--------|
| `[] { }` | No capture, no params |
| `[x, &y]` | x by value, y by reference |
| `[=]`, `[&]` | All by value / by reference (use sparingly) |
| `mutable` | Allow modifying captures-by-value |
| `auto` params | Generic lambda (C++14) |
| `[*this]` | Capture copy of current object (C++17) |

---

## See also

- [Functions](functions.md) – std::function, function pointers, parameters
- [Templates](templates.md) – generic lambdas and callable parameters
- [Ranges & Views](ranges-and-views.md) – lambdas with range algorithms
- [Threading](threading.md) – lambdas as tasks or callbacks
