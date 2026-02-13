# constexpr

**constexpr** marks values and functions that can be evaluated at **compile time**. That allows constants in types (e.g. array sizes), compile-time computation, and better optimization. This document covers constexpr variables, functions, and C++20 improvements.

---

## 1. constexpr variables

A **constexpr variable** must be initialized with a constant expression. Its value is available at compile time and is implicitly const.

```cpp
constexpr int maxSize = 100;
constexpr double pi = 3.14159;
int arr[maxSize];  // OK: constant expression

constexpr int square(int x) { return x * x; }
constexpr int n = square(10);  // 100 at compile time
```

Use constexpr for named constants that you need in constant expressions (e.g. template arguments, array bounds, switch cases).

---

## 2. constexpr functions

A **constexpr function** can be evaluated at compile time when its arguments are constant expressions. Otherwise it runs at runtime. Restrictions (before C++14/C++20) have been relaxed: C++14 allows multiple statements and loops; C++20 allows more (e.g. virtual, try-catch in limited forms).

```cpp
constexpr int factorial(int n) {
    if (n <= 1) return 1;
    return n * factorial(n - 1);
}
constexpr int f5 = factorial(5);  // 120 at compile time
int x = 5;
int f = factorial(x);  // runtime call
```

- If all arguments are constant, the call can be used in a constant expression (e.g. template argument, constexpr variable initializer).
- If any argument is non-constant, the function is still valid but runs at runtime.

---

## 3. consteval (C++20)

**consteval** functions must produce a constant; they are only evaluated at compile time. Use when the result must never be computed at runtime.

```cpp
consteval int doubleIt(int x) {
    return 2 * x;
}
constexpr int a = doubleIt(10);  // OK
int b = doubleIt(rand());         // Error: argument not constant
```

---

## 4. constinit (C++20)

**constinit** ensures that a variable with static or thread storage duration is initialized with a constant expression. It does not make the variable const; it only guarantees constant initialization (e.g. no static initialization order issues).

```cpp
constinit int global = 42;  // constant initialization
```

Use for globals that must be initialized at load time.

---

## 5. Use in types and templates

constexpr enables compile-time choices and fixed-size structures:

```cpp
template<int N>
struct FixedString {
    char data[N];
    constexpr int size() const { return N - 1; }
};
constexpr FixedString<5> s = "hello";
```

Standard types like **std::array**, **std::tuple**, and many **std::** functions are constexpr-friendly so you can use them in constant expressions (C++14/17/20).

---

## 6. Guidelines

- Use **constexpr** for variables and functions that can be constant; the compiler can use them at compile time when possible.
- Prefer **constexpr** over macros for named constants.
- Use **consteval** when the function must only run at compile time.
- Keep constexpr functions simple so they stay valid in constant evaluation (no undefined behaviour, no operations that aren’t allowed in constant expressions).

---

## 7. Quick reference

| Keyword   | Meaning |
|----------|---------|
| constexpr | Variable or function that can be evaluated at compile time |
| consteval | Function that must be evaluated at compile time (C++20) |
| constinit | Variable initialized with a constant expression (C++20) |

---

## See also

- [Functions](functions.md) – constexpr and consteval functions
- [Templates](templates.md) – non-type template parameters and compile-time logic
- [Type deduction](type-deduction.md) – auto and decltype
