# Concepts (C++20)

Concepts name requirements on template arguments. They make templates easier to read, give clearer errors, and allow the compiler to choose overloads and specializations based on constraints. This document covers defining concepts, constraining templates, and common standard concepts.

---

## 1. Why concepts?

Without concepts, template errors appear when the compiler instantiates the template and finds an unsupported operation. The message can be long and refer to deep inside the template. You also cannot easily overload or specialize on “any type that has operation X.”

**Concepts** let you state requirements up front:

- Better error messages: the compiler can report “constraint not satisfied” at the call site.
- Overloading and specialization: you can have one function for “any type with `operator<`” and another for the rest.
- Documentation: the template declares what it needs from `T`.

---

## 2. Defining a concept

A **concept** is a named predicate: a constant expression of type `bool` that says whether a set of types (and optionally values) satisfies a requirement.

```cpp
#include <concepts>

// Concept that requires T to have operator<
template<typename T>
concept LessThanComparable = requires(T a, T b) {
    { a < b } -> std::convertible_to<bool>;
};

// Concept that requires a type to have a value_type member type
template<typename T>
concept HasValueType = requires {
    typename T::value_type;
};
```

Syntax:

- `concept Name = ...;` — the right-hand side must be a constraint expression (e.g. `requires { ... }`, or another concept, or a boolean constant expression).
- **requires expression** `requires (params) { requirements }` — lists operations that must be valid. The compiler checks that the required expressions are well-formed.

---

## 3. requires expressions

A **requires expression** produces a predicate that is true when all listed requirements are satisfied.

**Type requirements:** `typename T::value_type;` — the nested type must exist.

**Expression requirements:** `{ expr } -> concept;` — `expr` must be valid, and its result must satisfy the concept (e.g. `std::convertible_to<bool>`).

```cpp
template<typename T>
concept Incrementable = requires(T x) {
    { ++x } -> std::same_as<T&>;
    { x++ } -> std::same_as<T>;
};

template<typename T>
concept HasSize = requires(const T& t) {
    { t.size() } -> std::convertible_to<size_t>;
};
```

You can list multiple requirements; all must hold.

---

## 4. Constraining templates

### 4.1 Constrained type parameter

Use the concept name in place of `typename` (or in addition, with `typename T` then the concept).

```cpp
template<LessThanComparable T>
T min(T a, T b) {
    return (a < b) ? a : b;
}

// Same meaning, alternative syntax
template<typename T>
requires LessThanComparable<T>
T min(T a, T b) {
    return (a < b) ? a : b;
}
```

Only types that satisfy `LessThanComparable` can be used. Otherwise you get a clear constraint failure.

### 4.2 requires clause

A **requires clause** is `requires ConceptName<T>` (or a more complex constraint) after the template header. It applies the constraint to the template.

```cpp
template<typename T>
requires std::copyable<T> && HasValueType<T>
void process(T x) {
    typename T::value_type v{};
    T copy = x;
}
```

You can combine concepts with `&&` and `||`.

### 4.3 Constrained auto

`auto` placeholders can be constrained with a concept.

```cpp
template<LessThanComparable T>
void sort(std::vector<T>& v);

// Constrained auto in a generic lambda (C++20)
auto f = [](std::integral auto x) { return x * 2; };
f(42);   // OK
// f(3.14);  // constraint failure
```

---

## 5. Standard library concepts

The standard library provides many concepts in `<concepts>` and `<iterator>`.

**Core language concepts:**

- `std::same_as<T, U>` — same type (after stripping cv-ref).
- `std::derived_from<T, Base>` — T is derived from Base.
- `std::convertible_to<T, U>` — T can be converted to U (including explicit).
- `std::constructible_from<T, Args...>` — T can be constructed from Args.

**Comparison:**

- `std::equality_comparable_with<T, U>` — can compare with `==`, `!=`.
- `std::totally_ordered_with<T, U>` — `==`, `!=`, `<`, `<=`, `>`, `>=`.

**Object:**

- `std::movable<T>`, `std::copyable<T>` — move and copy semantics.
- `std::semiregular<T>`, `std::regular<T>` — default-constructible, copyable, etc.

**Callable:**

- `std::invocable<F, Args...>` — `f(args...)` is valid.
- `std::predicate<F, Args...>` — invocable and result convertible to bool.

**Example:**

```cpp
#include <concepts>

template<std::copyable T>
T duplicate(T x) {
    return x;
}

template<std::totally_ordered T>
const T& max(const T& a, const T& b) {
    return (a < b) ? b : a;
}
```

---

## 6. Overloading with concepts

Concepts allow you to overload on “what T can do” instead of a concrete type.

```cpp
template<typename T>
void print(const T& x) {
    std::cout << x << '\n';
}

template<std::ranges::range T>
void print(const T& range) {
    for (const auto& item : range) {
        std::cout << item << ' ';
    }
    std::cout << '\n';
}

print(42);              // first overload
print(std::vector{1,2,3});  // second (range overload is more specific)
```

The compiler picks the most constrained overload that is satisfied.

---

## 7. Combining and defining reusable concepts

Build complex constraints from simpler ones:

```cpp
template<typename T>
concept Numeric = std::integral<T> || std::floating_point<T>;

template<Numeric T>
T add(T a, T b) {
    return a + b;
}
```

Keep concepts focused and composable; use the standard concepts where they fit.

---

## 8. Quick reference

| Goal | Syntax |
|------|--------|
| Define a concept | `template<typename T> concept C = requires(T x) { ... };` |
| Require a type | `typename T::value_type;` |
| Require expression + result type | `{ x.f() } -> std::convertible_to<int>;` |
| Constrain template | `template<Concept T>` or `template<typename T> requires Concept<T>` |
| Constrain auto | `std::integral auto x` |
| Combine | `requires C1<T> && C2<T>` |

---

## See also

- [Templates](templates.md) – unconstrained templates and deduction
- [Functions](functions.md) – overloading
- [Ranges & Views](ranges-and-views.md) – range concepts and algorithms
