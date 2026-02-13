# Move Semantics

**Move semantics** let the language transfer ownership of resources (e.g. dynamic memory, file handles) from one object to another without copying. That enables efficient “sink” parameters and return values and underpins types like `std::unique_ptr` and standard containers. This document covers rvalue references, move constructor and move assignment, and when moves happen.

---

## 1. Why move?

Copying can be expensive: it duplicates data and may allocate. For temporary or “source” objects that will no longer be used, we can **move** instead: steal the internal state (e.g. pointer, buffer) and leave the source in a valid but unspecified state. No duplicate allocation, often just a few pointer/field assignments.

---

## 2. Lvalues and rvalues

- **Lvalue**: has identity; can be on the left of `=`; can have its address taken (e.g. variable, function returning reference).
- **Rvalue**: temporary or “about to be destroyed”; typically cannot have its address taken (e.g. literal, result of `std::move(x)`, function returning by value).

Rough rule: if you can take its address, it’s an lvalue; otherwise it’s often an rvalue. The compiler uses this to choose overloads.

---

## 3. Rvalue references (T&&)

An **rvalue reference** (`T&&`) binds to rvalues (temporaries, moved-from objects). It does **not** bind to non-const lvalues (unless you use `std::move` to cast to rvalue).

```cpp
void takeRvalue(int&& x) {}
void takeLvalue(int& x) {}

int a = 1;
takeRvalue(42);       // OK: 42 is rvalue
takeRvalue(a);        // Error: a is lvalue
takeRvalue(std::move(a));  // OK: cast a to rvalue
takeLvalue(a);        // OK
```

- **std::move(x)**: casts `x` to an rvalue reference. It does not move by itself; it just allows the compiler to select move overloads. The actual move happens in the move constructor or move assignment of the type.

---

## 4. Move constructor

Signature: `ClassName(ClassName&& other) noexcept`.

It “steals” the guts of `other` and leaves `other` in a valid state (often empty) so that `other`’s destructor can run safely.

```cpp
class Buffer {
    char* data_ = nullptr;
    size_t size_ = 0;
public:
    Buffer(Buffer&& other) noexcept
        : data_(other.data_)
        , size_(other.size_) {
        other.data_ = nullptr;
        other.size_ = 0;
    }
    ~Buffer() { delete[] data_; }
};
```

After the move, the source (`other`) should be safe to destroy and to assign to; don’t assume its contents are still there.

---

## 5. Move assignment

Signature: `ClassName& operator=(ClassName&& other) noexcept`.

Release the current resource, then take the resource from `other`, and leave `other` empty (or valid-but-unspecified).

```cpp
Buffer& operator=(Buffer&& other) noexcept {
    if (this != &other) {
        delete[] data_;
        data_ = other.data_;
        size_ = other.size_;
        other.data_ = nullptr;
        other.size_ = 0;
    }
    return *this;
}
```

Always check for self-assignment (`this != &other`).

---

## 6. When moves happen

The compiler uses move when:

- **Initializing** from an rvalue: `T b = std::move(a);` or `T b = makeT();` (return value is rvalue).
- **Assigning** from an rvalue: `b = std::move(a);`
- **Passing** an rvalue to a parameter `T&&` or `T` (temporary or `std::move(x)`).
- **Returning** a local object by value: the compiler can use move (or RVO) so returning large objects is cheap.

If no move is defined, copy is used. If the type is move-only (e.g. `std::unique_ptr`), copy is disabled and move is the only way to transfer ownership.

---

## 7. noexcept and move

Containers and standard types often only use move if the move operations are **noexcept**, so that they can provide strong exception guarantees. Mark move constructor and move assignment **noexcept** when they don’t throw.

---

## 8. Copy vs move

- **Copy**: two independent copies; source unchanged.
- **Move**: one object gets the resource; source is left in a valid but unspecified state (often empty).

If you don’t declare copy/move, the compiler may generate them. It generates move only if there is no user-declared copy, move, or destructor. See [Constructors & destructors](constructors-and-destructors.md) and the rule of five.

---

## 9. Forwarding references (T&& in templates)

In a **template** `template<typename T> void f(T&& x)`, `T&&` is a **forwarding reference** (formerly “universal reference”): it can bind to both lvalues and rvalues. Use **std::forward<T>(x)** inside the function to preserve value category when passing `x` on to another function.

```cpp
template<typename T>
void wrapper(T&& x) {
    other(std::forward<T>(x));  // lvalue stays lvalue, rvalue stays rvalue
}
```

Used for “perfect forwarding” in generic code and wrappers. Don’t confuse with rvalue references in non-template code.

---

## 10. Quick reference

| Concept | Meaning |
|--------|--------|
| Rvalue | Temporary or “disposable”; can bind to `T&&` |
| std::move(x) | Cast to rvalue so move overloads can be used |
| Move ctor | `T(T&&)` — take resource from source |
| Move assign | `T& operator=(T&&)` — release *this, take from source |
| noexcept | Mark move ops noexcept so std lib can use them |
| std::forward<T> | In templates, preserve value category when forwarding |

---

## See also

- [Constructors & destructors](constructors-and-destructors.md) – move as special members
- [RAII](raii.md) – move transfers ownership of resources
- [Smart pointers](smart-pointers.md) – unique_ptr is move-only
- [Pointers & references](pointers-and-references.md) – rvalue references briefly
- [Templates](templates.md) – forwarding references
