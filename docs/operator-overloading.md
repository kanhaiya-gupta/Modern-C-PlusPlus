# Operator Overloading

**Operator overloading** lets you define how operators (e.g. `+`, `==`, `[]`, `<<`) behave for your types. Used well, it makes code readable and consistent with built-in types. This document covers the main overloadable operators, conventions, and when to use (or avoid) overloading.

---

## 1. Basics

You define overloads as **member functions** or **free (non-member) functions**. The compiler picks them based on the types of the operands.

- **Member**: first (left) operand is `*this`; use for operators that modify or strongly “belong to” the object (e.g. `+=`, `[]`).
- **Non-member**: both operands are arguments; use when the left operand is not your type (e.g. `std::ostream& << MyType`) or for symmetry (e.g. `a + b` and `b + a`).

```cpp
class Vec {
    int x_, y_;
public:
    Vec(int x, int y) : x_(x), y_(y) {}
    Vec operator+(const Vec& other) const {
        return Vec(x_ + other.x_, y_ + other.y_);
    }
    Vec& operator+=(const Vec& other) {
        x_ += other.x_; y_ += other.y_;
        return *this;
    }
};
```

---

## 2. Overloadable operators

You can overload most operators (not `::`, `.*`, `.`, `?:`). Common ones:

| Operator | Typical form | Notes |
|----------|----------------|--------|
| `+`, `-`, `*`, `/` | Member or non-member | Prefer non-member for symmetry; often implement `op=` as member and `op` in terms of it |
| `==`, `!=` | Non-member (or member) | Prefer non-member; implement `!=` as `!(a == b)` |
| `<`, `<=`, `>`, `>=` | Non-member | For ordering; C++20 can use `<=>` (spaceship) and get all from one |
| `+=`, `-=`, etc. | Member | Modify `*this`; return `*this` by reference |
| `[]` | Member | Take index; often two overloads: const and non-const |
| `()` | Member | Functor / callable object |
| `<<`, `>>` | Non-member | Stream I/O; left operand is stream |
| `++`, `--` | Member | Prefix `operator++()`; suffix `operator++(int)` with dummy int |
| `!`, `&&`, `\|\|` | Prefer free | Short-circuit behaviour is only for built-in types; overloads don’t short-circuit |
| `=` | Member only | Copy/move assignment; see [Constructors & destructors](constructors-and-destructors.md) |

---

## 3. Comparison: == and !=

Prefer **non-member** for symmetry (e.g. mixed `MyType` and `int`). Implement `!=` in terms of `==`.

```cpp
class Id {
    int value_;
public:
    bool operator==(const Id& other) const { return value_ == other.value_; }
    bool operator!=(const Id& other) const { return !(*this == other); }
};

// Or non-member for symmetry:
bool operator==(const Id& a, const Id& b) { return a.value() == b.value(); }
bool operator!=(const Id& a, const Id& b) { return !(a == b); }
```

C++20: you can define only `operator==` and get `!=` automatically if you use `operator==(const Id&, const Id&)` and don’t define `!=` (or use a defaulted `!=`).

---

## 4. Spaceship operator <=> (C++20)

**Spaceship** `operator<=>` returns a comparison category type. The compiler can generate `==`, `!=`, `<`, `<=`, `>`, `>=` from it (and from `==` alone for equality). Reduces boilerplate.

```cpp
#include <compare>
class Point {
    int x_, y_;
public:
    auto operator<=>(const Point&) const = default;  // lexicographic comparison of x_, y_
};
// ==, !=, <, <=, >, >= are all available
```

Use `= default` when member-wise comparison is what you want; otherwise implement `<=>` (and optionally `==`) by hand.

---

## 5. Subscript operator []

Usually two overloads: one **const** (read-only), one non-const (can modify). Return reference to the element.

```cpp
class Buffer {
    std::vector<int> data_;
public:
    int& operator[](size_t i) { return data_[i]; }
    const int& operator[](size_t i) const { return data_[i]; }
};
```

---

## 6. Stream operators << and >>

Left operand is the stream; must be **non-member** (or member of the stream type, which you can’t add). Return the stream reference for chaining.

```cpp
std::ostream& operator<<(std::ostream& out, const Vec& v) {
    return out << '(' << v.x() << ", " << v.y() << ')';
}
std::istream& operator>>(std::istream& in, Vec& v) {
    int x, y;
    in >> x >> y;
    v = Vec(x, y);
    return in;
}
```

---

## 7. Increment and decrement (++ and --)

- **Prefix** `++x`: `operator++()` — increment, return `*this` by reference.
- **Postfix** `x++`: `operator++(int)` — dummy `int` distinguishes it; usually implement as “copy, prefix, return copy.”

```cpp
class Counter {
    int n_ = 0;
public:
    Counter& operator++() { ++n_; return *this; }
    Counter operator++(int) {
        Counter old = *this;
        ++*this;
        return old;
    }
};
```

Same idea for `--`.

---

## 8. Call operator () — functors

Overloading `()` makes an object **callable** (a functor). Used with algorithms and in places that expect a function-like object.

```cpp
class Greater {
public:
    bool operator()(int a, int b) const { return a > b; }
};
std::sort(v.begin(), v.end(), Greater());
```

Lambdas are syntactic sugar for a closure type with `operator()`. See [Lambdas](lambdas.md).

---

## 9. Guidelines

- **Be consistent** with built-in and standard types (e.g. `+` should not mutate; `==` should be symmetric and stable).
- **Prefer non-member** for binary operators when the left operand isn’t your type or you want symmetry.
- **Return references** from `+=`, `=`, `[]` (non-const) so you can chain or assign.
- **Keep semantics clear**: don’t overload `+` to do something unrelated to addition.
- Consider **C++20 spaceship** to define one comparison and get the rest.

---

## 10. Quick reference

| Operator | Usual form | Return |
|----------|------------|--------|
| `a + b` | Non-member or member | New value |
| `a += b` | Member | `*this` (reference) |
| `a == b` | Non-member preferred | bool |
| `a[i]` | Member, const + non-const | Reference to element |
| `<< stream` | Non-member | stream reference |
| `++a` | Member `operator++()` | Reference to *this |
| `a++` | Member `operator++(int)` | Old value (copy) |
| `a()` | Member `operator()` | Whatever you need |

---

## See also

- [Class](class.md) – members and const member functions
- [Constructors & destructors](constructors-and-destructors.md) – copy/move assignment
- [Lambdas](lambdas.md) – callable objects and `operator()`
- [Concepts](concepts.md) – requirements like `equality_comparable`
