# Templates

Templates let you write code that works with many types (or values) without duplicating it. The compiler generates concrete functions or classes when you use a template with specific arguments. This document covers function templates, class templates, template parameters, specialization, and variadic templates.

---

## 1. Function templates

### 1.1 Basic syntax

Declare a **template** with `template</* parameters */>`; then define the function. The template parameters are placeholders the compiler fills in when you call the function.

```cpp
template<typename T>
T max(T a, T b) {
    return (a > b) ? a : b;
}

int main() {
    max(1, 2);       // T = int
    max(1.0, 2.0);   // T = double
    max(1, 2.0);     // Error or deduction to one type, depending on compiler
}
```

`typename` (or `class`) introduces a **type parameter**. The name `T` is conventional; you can use any identifier.

### 1.2 Template argument deduction

The compiler infers the template arguments from the function arguments. All parameters that contribute to deduction must match the same type `T` unless you have multiple parameters.

```cpp
template<typename T>
T add(T a, T b) {
    return a + b;
}

add(1, 2);      // T = int
add(1, 2.0);    // Error: T would be int for a, double for b — ambiguous
```

To allow different types for the two arguments (and a possibly different return type), use two type parameters or a single parameter for the result:

```cpp
template<typename T, typename U>
auto add(T a, U b) -> decltype(a + b) {
    return a + b;
}
// or in C++14: auto add(T a, U b) { return a + b; }

add(1, 2.0);    // T = int, U = double; return type from a + b
```

### 1.3 Explicit template arguments

You can specify the template arguments explicitly instead of relying on deduction.

```cpp
max<int>(1, 2);           // T = int
max<double>(1, 2);        // T = double; 1 and 2 converted to double
add<int, double>(1, 2.0); // T = int, U = double
```

Explicit arguments are required when the compiler cannot deduce them (e.g. return type only, or no function parameters use that type).

```cpp
template<typename T>
T getDefault() {
    return T{};
}
auto x = getDefault<int>();   // must specify T
```

### 1.4 Const and reference parameters

Template parameters can be deduced as value, reference, or const reference. Be explicit when you want a particular kind of parameter.

```cpp
template<typename T>
void byValue(T x);       // T deduced; x is a copy

template<typename T>
void byRef(T& x);        // T deduced; x is lvalue reference (lvalues only)

template<typename T>
void byConstRef(const T& x);  // works for lvalues and temporaries
```

Using a **forwarding reference** (`T&&`) gives one parameter that can bind to both lvalues and rvalues; see [Move semantics](move-semantics.md) and perfect forwarding.

---

## 2. Class templates

### 2.1 Defining a class template

Like function templates, class templates are declared with `template</* parameters */>` before the class. Member functions can be defined inside the class or outside (with the same template header).

```cpp
template<typename T>
class Box {
public:
    explicit Box(const T& value) : value_(value) {}
    const T& get() const { return value_; }
    void set(const T& value) { value_ = value; }
private:
    T value_;
};

// Usage: you must supply the template argument (no deduction for class until C++17)
Box<int> i(42);
Box<std::string> s("hello");
```

### 2.2 Member functions defined outside

When defining a member function outside the class, repeat the template header and qualify the name with `ClassName<T>`.

```cpp
template<typename T>
class Box {
public:
    void set(const T& value);
};

template<typename T>
void Box<T>::set(const T& value) {
    value_ = value;
}
```

### 2.3 Class template argument deduction (CTAD, C++17)

The compiler can deduce the template arguments from the constructor arguments in many cases.

```cpp
std::pair p(1, 2.0);           // std::pair<int, double>
std::vector v = {1, 2, 3};     // std::vector<int>
std::lock_guard lock(mutex);    // std::lock_guard<decltype(mutex)>
```

For your own types, deduction guides can be provided if the constructor alone is not enough.

---

## 3. Template parameters

### 3.1 Type parameters

`typename T` or `class T`: `T` is a type. There is no difference between `typename` and `class` here.

```cpp
template<typename T, class U>
void f(T a, U b);
```

### 3.2 Non-type parameters

Templates can take **values** (integral, pointer, enum, and in C++20 certain other types) as well as types.

```cpp
template<int N>
struct FixedSizeBuffer {
    char data[N];
};

template<typename T, int Size>
class Array {
    T data_[Size];
};

FixedSizeBuffer<128> buf;
Array<double, 10> arr;
```

### 3.3 Default template arguments

Type and (where allowed) non-type parameters can have defaults. Defaults apply to the rightmost parameters.

```cpp
template<typename T = int, int N = 10>
class Buffer { /* ... */ };

Buffer<> b1;        // T = int, N = 10
Buffer<double> b2;  // T = double, N = 10
Buffer<double, 20> b3;
```

### 3.4 Template template parameters

A template parameter can itself be a template (a “template template” parameter). Useful for generic containers or policies.

```cpp
template<template<typename> typename Container, typename T>
class Adapter {
    Container<T> data_;
};

Adapter<std::vector, int> a;   // Container<T> = std::vector<int>
```

Older code may use `template<typename> class Container`; the meaning is the same.

---

## 4. Specialization

### 4.1 Full specialization

You can provide a **full specialization** of a template for specific arguments. The specialization replaces the generic template for that exact set of arguments.

```cpp
template<typename T>
struct IsPointer {
    static constexpr bool value = false;
};

template<typename T>
struct IsPointer<T*> {
    static constexpr bool value = true;
};

IsPointer<int>::value;    // false
IsPointer<int*>::value;   // true
```

For function templates, full specialization is possible but overloading is often clearer. For classes, full specialization is common (e.g. `std::vector<bool>`).

### 4.2 Partial specialization (classes only)

**Partial specialization** restricts some template parameters but leaves others open. Only class templates can be partially specialized.

```cpp
template<typename T, typename U>
struct Pair { T first; U second; };

template<typename T>
struct Pair<T, T> {
    T first;
    T second;
    // both same type
};

Pair<int, double> a;  // generic
Pair<int, int> b;     // partial specialization
```

---

## 5. Variadic templates (C++11)

### 5.1 Parameter pack

A **parameter pack** is a list of zero or more template arguments. Use `...` to declare and expand the pack.

```cpp
template<typename... Ts>
struct Tuple {};

Tuple<> t0;
Tuple<int> t1;
Tuple<int, double, std::string> t2;
```

### 5.2 Variadic function template

You can take a pack of arguments and process them recursively or with a fold expression.

```cpp
// Base case
void print() {}

// Recursive case
template<typename T, typename... Rest>
void print(T first, Rest... rest) {
    std::cout << first << ' ';
    print(rest...);
}

print(1, 2.0, "hello");  // 1 2 hello
```

### 5.3 sizeof...(pack)

`sizeof...(name)` gives the number of elements in the pack.

```cpp
template<typename... Ts>
void count(Ts... args) {
    std::cout << sizeof...(Ts) << " types, " << sizeof...(args) << " args\n";
}
count(1, 2.0, "x");  // 3 types, 3 args
```

### 5.4 Fold expressions (C++17)

Folds reduce a pack with an operator. Syntax: `(pack op ...)` or `(... op pack)` etc.

```cpp
template<typename... Ts>
auto sum(Ts... args) {
    return (args + ...);  // right fold: a + (b + (c + d))
}

template<typename... Ts>
bool allTrue(Ts... args) {
    return (args && ...);
}

sum(1, 2, 3, 4);       // 10
allTrue(true, true, false);  // false
```

---

## 6. Dependent names and typename

Inside a template, a name that depends on a template parameter is a **dependent name**. The compiler may not know whether it is a type or a value until instantiation. Use `typename` to tell the compiler it is a type.

```cpp
template<typename T>
struct Trait {
    using value_type = typename T::value_type;  // T::value_type is a type
    static constexpr int N = T::size;           // T::size is a value
};

template<typename T>
void f() {
    typename std::vector<T>::iterator it;  // iterator is a type
}
```

Without `typename`, the compiler assumes `T::value_type` is a value; if it is actually a type, the code is ill-formed.

---

## 7. Template instantiation

The compiler **instantiates** a template when it needs the full definition for a given set of arguments. Only the instantiations that are used end up in the program.

- **Implicit instantiation**: happens when you use the template (e.g. call a function template or create a class template specialization).
- **Explicit instantiation**: you force an instantiation in one translation unit, e.g. `template class std::vector<int>;` or `template int max<int>(int, int);`.

Header-only libraries put template definitions in headers so that every translation unit that uses a given instantiation can see the definition and compile it (often with the same result due to inline and link-time optimization).

---

## 8. Common patterns and tips

### 8.1 Prefer generic code over specialization

When you can, write one generic template that works for all types. Use specialization (or overloading) only when you need different behaviour for specific types.

### 8.2 Avoid unnecessary constraints in the template

Let the template accept any type that supports the operations you use. Use [Concepts](concepts.md) (C++20) to document and enforce requirements instead of ad-hoc SFINAE or static_assert.

### 8.3 Typedef / using inside class templates

Use `using` or `typedef` to expose types that depend on template parameters.

```cpp
template<typename T>
class Container {
public:
    using value_type = T;
    using reference = T&;
    // ...
};
```

### 8.4 Template and separate compilation

Template definitions are usually in headers so the compiler can instantiate them where they are used. If you want to limit instantiation to one .cpp, use explicit instantiation there and declare the template `extern` in the header (advanced pattern).

---

## 9. Quick reference

| Need | Tool |
|------|------|
| One function for many types | Function template `template<typename T> void f(T x)` |
| One class for many types | Class template `template<typename T> class C` |
| Compiler infers type | Template argument deduction (call `f(42)` → `T = int`) |
| Force a type | Explicit args: `f<int>(42)` |
| Different behaviour for one type | Full specialization |
| Different behaviour for a family of types | Partial specialization (classes) or overloading (functions) |
| Arbitrary number of type/args | Variadic template `template<typename... Ts>` |
| Require operations on T | Concepts (C++20); see [Concepts](concepts.md) |

---

## See also

- [Functions](functions.md) – overloads, parameters, return types
- [Concepts](concepts.md) – constraining template parameters (C++20)
- [Move semantics](move-semantics.md) – forwarding references and `std::forward`
