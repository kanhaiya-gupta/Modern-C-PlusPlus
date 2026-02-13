# Functions

A function groups a block of code that can be called by name, take arguments, and optionally return a value. This document covers declaration, parameters, return types, overloading, and modern C++ features.

---

## 1. Declaration vs Definition

- **Declaration**: Tells the compiler the name, parameters, and return type. No body.
- **Definition**: The full function including the body. Must appear once (or once per translation unit for `inline`).

```cpp
// Declaration (often in a header)
int add(int a, int b);

// Definition (in header or .cpp)
int add(int a, int b) {
    return a + b;
}
```

Headers usually declare; one `.cpp` (or the header for `inline`) provides the definition.

---

## 2. Parameters: How Arguments Are Passed

### 2.1 Pass by value

A copy is made. Changes inside the function do not affect the caller. Use for small, cheap-to-copy types (e.g. `int`, `double`, small structs).

```cpp
void byValue(int x) {
    x = 99;  // only the local copy changes
}

int main() {
    int a = 1;
    byValue(a);
    // a is still 1
}
```

### 2.2 Pass by reference (non-const)

No copy; the parameter is an alias for the argument. Use when the function must modify the argument.

```cpp
void byRef(int& x) {
    x = 99;
}

int main() {
    int a = 1;
    byRef(a);
    // a is now 99
}
```

### 2.3 Pass by const reference

No copy; the parameter cannot be modified. Preferred for expensive-to-copy types (e.g. `std::string`, containers) when you don’t need to modify the argument.

```cpp
void byConstRef(const std::string& s) {
    // s.size(); OK
    // s = "other";  // Error: s is const
}

void print(const std::vector<int>& v) {
    for (int x : v) std::cout << x << ' ';
}
```

### 2.4 Pass by pointer

The parameter is an address. Use when you need “optional” or “nullable” semantics, or when the API is C-style. In modern C++, prefer references when “must be valid” and `std::optional` or overloads when “optional.”

**Optional output (legacy / C-style):**

```cpp
void maybeSet(int* p) {
    if (p) *p = 42;
}

int main() {
    int x = 0;
    maybeSet(&x);        // x becomes 42
    maybeSet(nullptr);   // no crash, no write
}
```

**Calling C-style APIs when you own the object with a smart pointer:** pass the raw pointer with `.get()` so the callee does not take ownership.

```cpp
#include <memory>

void c_style_api(int* p);  // doesn't take ownership

int main() {
    auto p = std::make_unique<int>(10);
    c_style_api(p.get());  // OK: non-owning raw pointer
    // p still owns the int
}
```

**Transferring ownership into a function:** take `std::unique_ptr` by value (or by rvalue reference). The caller uses `std::move`.

```cpp
void takeOwnership(std::unique_ptr<Widget> w) {
    // this function now owns w; it will be destroyed when we return
}

int main() {
    auto w = std::make_unique<Widget>();
    takeOwnership(std::move(w));  // w is now null; ownership transferred
}
```

**Shared ownership:** pass `std::shared_ptr` by value or by const reference depending on whether the function needs to keep a copy.

```cpp
void useShared(const std::shared_ptr<Widget>& w) {
    // can use *w; doesn't extend lifetime
}

void keepCopy(std::shared_ptr<Widget> w) {
    // keeps a shared copy; lifetime extended
}
```

### 2.5 Default arguments

Default values are used when the caller omits trailing arguments. Defaults are specified in the declaration (usually the header).

```cpp
void greet(const std::string& name, int times = 1) {
    for (int i = 0; i < times; ++i)
        std::cout << "Hello, " << name << '\n';
}

greet("Alice");     // times = 1
greet("Bob", 3);    // times = 3
```

Rules:

- Only trailing parameters can have defaults.
- Defaults are resolved at the call site; avoid defaulting parameters that depend on non-defaulted ones in confusing ways.

---

## 3. Return Types

### 3.1 Return by value

The caller gets a copy (or a move, if the type is moveable). Normal choice for most types.

```cpp
std::string getName() {
    return "Alice";
}

int sum(int a, int b) {
    return a + b;
}
```

For large types, rely on move semantics and RVO so returning by value is efficient.

### 3.2 Return by reference

Returns an alias to an existing object. **Never return a reference to a local variable** (undefined behaviour).

```cpp
// OK: return reference to existing object
int& getMax(int& a, int& b) {
    return (a > b) ? a : b;
}

// WRONG: returning reference to local
int& bad() {
    int x = 42;
    return x;  // undefined behaviour
}
```

### 3.3 Return by const reference

Use when returning a const view into existing data (e.g. a member or a static).

```cpp
const std::string& getDefaultName() {
    static const std::string name = "Default";
    return name;
}
```

### 3.4 Return by reference and lifetime

Only return references to objects that outlive the function call: statics, caller-provided references/pointers, or data owned by the caller (e.g. member of an object that stays alive).

### 3.5 Return by smart pointer

When returning an **owned** heap object, return a smart pointer instead of a raw pointer. That makes ownership clear and avoids leaks.

**Exclusive ownership — return `std::unique_ptr`:**

```cpp
#include <memory>

std::unique_ptr<Widget> makeWidget(int id) {
    return std::make_unique<Widget>(id);
}

int main() {
    auto w = makeWidget(1);  // caller owns the Widget
}
```

**Shared ownership — return `std::shared_ptr`:**

```cpp
std::shared_ptr<Widget> getSharedWidget() {
    return std::make_shared<Widget>(2);
}
```

**Non-owning “find” / optional result:** returning a raw pointer or `std::optional<std::reference_wrapper<T>>` is fine when the caller does not take ownership. Never return a raw pointer that the caller is expected to `delete`; use `unique_ptr` or `shared_ptr` for that. See [Smart pointers](smart-pointers.md).

---

## 4. Function overloading

Same name, different parameter lists (number or types of parameters). The compiler picks the best match.

```cpp
void print(int x) {
    std::cout << "int: " << x << '\n';
}

void print(double x) {
    std::cout << "double: " << x << '\n';
}

void print(const std::string& s) {
    std::cout << "string: " << s << '\n';
}

print(42);           // int
print(3.14);         // double
print("hello");      // string (const char* -> const std::string&)
```

Return type alone does **not** participate in overloading; only the parameter list does.

---

## 5. Inline functions

`inline` is a hint that the compiler may paste the function body at the call site to avoid call overhead. Also allows the same definition in multiple translation units (one definition per TU).

```cpp
inline int min(int a, int b) {
    return (a < b) ? a : b;
}
```

Heavy use of `inline` can increase code size. Let the compiler decide unless you need it for header-only libraries or ODR.

---

## 6. constexpr and consteval functions (C++11 / C++20)

- **constexpr**: May be evaluated at compile time when all arguments are constant; otherwise runs at runtime.
- **consteval** (C++20): Must be evaluated at compile time.

```cpp
constexpr int square(int x) {
    return x * x;
}

constexpr int a = square(10);  // compile-time: a == 100
int b = square(rand());       // runtime

// C++20: must be compile-time
consteval int doubleIt(int x) {
    return 2 * x;
}
int c = doubleIt(5);  // OK, compile-time
```

Use constexpr for logic that can run at compile time (e.g. simple math, type traits).

---

## 7. Trailing return type (auto)

Useful when the return type depends on the parameters or to keep the declaration readable.

```cpp
template<typename T, typename U>
auto add(T a, U b) -> decltype(a + b) {
    return a + b;
}

// C++14: plain auto works for many cases
template<typename T, typename U>
auto addSimple(T a, U b) {
    return a + b;
}
```

---

## 8. Function pointers

A variable can hold the address of a function with a matching signature.

```cpp
int add(int a, int b) { return a + b; }
int mul(int a, int b) { return a * b; }

int main() {
    int (*op)(int, int) = add;
    std::cout << op(2, 3) << '\n';  // 5
    op = mul;
    std::cout << op(2, 3) << '\n';  // 6
}
```

Typedef or `using` improves readability:

```cpp
using BinaryOp = int(int, int);
BinaryOp* op = add;
```

---

## 9. std::function (C++11)

Stores any callable with a given signature: function pointers, lambdas, function objects.

```cpp
#include <functional>

std::function<int(int, int)> op;

op = [](int a, int b) { return a + b; };
std::cout << op(2, 3) << '\n';  // 5

op = [](int a, int b) { return a * b; };
std::cout << op(2, 3) << '\n';  // 6
```

Use when you need a uniform type for different callables (e.g. callbacks, event handlers). Prefer templates if you only need to accept callables without type erasure.

---

## 10. [[nodiscard]] (C++17)

Warns the caller if the return value is ignored. Good for functions whose return value is important (e.g. error codes, unique resources).

```cpp
[[nodiscard]] bool tryParse(const std::string& s, int& out) {
    // ...
    return true;
}

tryParse("42", x);   // compiler may warn: result ignored
if (tryParse("42", x)) { /* use x */ }  // OK
```

---

## 11. noexcept (C++11)

Marks a function as not throwing. Enables optimizations and can be part of the type system (e.g. move operations).

```cpp
void noThrow() noexcept {
    // must not throw; std::terminate if it does
}

void maybeThrow() noexcept(false) {
    // may throw (default for most functions)
}
```

Use for move constructors/assignments and other functions you guarantee won’t throw.

---

## 12. Quick reference: when to use what

| Scenario | Parameter / return | Example |
|----------|---------------------|--------|
| Small, cheap type, no change | By value | `void f(int x)` |
| Modify the argument | Non-const reference | `void f(int& x)` |
| Read-only, expensive type | Const reference | `void f(const std::string& s)` |
| Optional / nullable | Pointer or `std::optional` | `void f(int* p)` or `void f(std::optional<int>)` |
| Transfer ownership in | By value (move) | `void f(std::unique_ptr<T> p)` |
| Use object you own (e.g. C API) | Pass raw from smart ptr | `c_api(p.get())` |
| Return new or computed value | By value | `std::string getName()` |
| Return owned heap object | Smart pointer | `std::unique_ptr<T> make()` |
| Return existing object, no copy | Const reference (watch lifetime) | `const std::string& get()` |
| Callback / generic callable | Template or `std::function` | `template<typename F> void run(F&& f)` |

---

## See also

- [Lambdas](lambdas.md) – anonymous callable objects
- [Templates](templates.md) – generic functions and classes
- [Concepts](concepts.md) – constraining template parameters
- [Smart pointers](smart-pointers.md) – ownership, `unique_ptr`, `shared_ptr`, `weak_ptr`
