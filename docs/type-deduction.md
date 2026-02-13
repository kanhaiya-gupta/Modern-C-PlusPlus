# Type Deduction (auto, decltype)

The compiler can **deduce** types from initializers and expressions so you don’t have to write them explicitly. **auto** and **decltype** are the main tools. This document covers how deduction works and common pitfalls.

---

## 1. auto

**auto** asks the compiler to deduce the type from the initializer. The deduced type is the same as if the initializer were used to initialize a variable of that type (so references collapse, top-level const/volatile are dropped unless you keep them in the declarator).

```cpp
auto x = 42;           // int
auto y = 3.14;         // double
auto s = std::string("hello");  // std::string
auto p = &x;            // int*
```

Use **auto** when the type is obvious from the right-hand side or when it’s long or complex (e.g. iterators, lambdas).

---

## 2. auto and references / const

The rule: **auto** drops top-level const and does not deduce a reference unless you write `auto&` or `const auto&`.

```cpp
const int c = 10;
auto a = c;        // int (const dropped)
auto& b = c;       // const int& (reference to const)
const auto& d = c; // const int&

int x = 1;
auto& r = x;       // int&
```

- **auto** by value: copy; top-level const/ref stripped.
- **auto&**: lvalue reference; keeps const.
- **const auto&**: const lvalue reference; binds to temporaries too.
- **auto&&**: forwarding reference in generic code; can bind to lvalues or rvalues.

---

## 3. auto and initializer lists

`auto x = { 1, 2, 3 };` deduces to **std::initializer_list<int>**, not a container or array. To get a container, use explicit type or direct initialization.

```cpp
auto il = { 1, 2, 3 };     // std::initializer_list<int>
auto v = std::vector{ 1, 2, 3 };  // C++17: std::vector<int>
```

---

## 4. decltype

**decltype(expr)** yields the **declared type** of the expression: the type the entity would have if the expression were the name of a variable. It preserves references, const, and value category.

```cpp
int x = 0;
decltype(x) a;       // int
decltype((x)) b = x;  // int& (parentheses make it an lvalue expression)
decltype(std::move(x)) c = 0;  // int&&
```

Use **decltype** when you need the exact type of an expression (e.g. return types, template metaprogramming). **decltype(auto)** (C++14) deduces like **auto** but keeps references and cv-qualifiers from the initializer.

```cpp
int x = 1;
decltype(auto) r = x;   // int& (r refers to x)
decltype(auto) c = (x); // int& (parentheses make lvalue)
```

---

## 5. Trailing return type with decltype

When the return type depends on the parameters, use a trailing return type and **decltype**:

```cpp
template<typename T, typename U>
auto add(T a, U b) -> decltype(a + b) {
    return a + b;
}
```

In C++14 you can often write `auto add(T a, U b) { return a + b; }` and let the compiler deduce the return type.

---

## 6. Function template argument deduction

For function templates, template arguments are deduced from the function arguments. See [Templates](templates.md). **auto** in parameters (C++20) uses the same idea: the parameter is a deduced type.

```cpp
void f(auto x);  // C++20: template<typename T> void f(T x);
```

---

## 7. Pitfalls

- **Proxy types**: some expressions return proxy or temporary types (e.g. `std::vector<bool>::reference`). `auto v = vec[0];` might not be `bool`; use explicit type or understand the proxy.
- **auto and narrowing**: `auto x = 3.14;` is double; if you wanted int, write `int x = 3.14;` or `auto x = 3` or cast.
- **decltype((x))**: the double parentheses make `x` an lvalue expression, so `decltype((x))` is a reference type.

---

## 8. Quick reference

| Construct | Meaning |
|-----------|--------|
| `auto x = expr;` | Type of x is type of expr (value; ref/const stripped) |
| `auto& x = expr;` | Lvalue reference |
| `const auto& x = expr;` | Const lvalue reference |
| `decltype(expr)` | Exact type of expression (ref/cv preserved) |
| `decltype(auto) x = expr;` | Type of x matches expr (ref/cv preserved) |

---

## See also

- [Templates](templates.md) – template argument deduction
- [Functions](functions.md) – return type deduction, trailing return type
- [Concepts](concepts.md) – constraining auto (e.g. `std::integral auto`)
