# Compile-time & Runtime Polymorphism

C++ supports two main forms of polymorphism: **runtime** (virtual functions, one interface chosen at run time) and **compile-time** (templates and overloading, behaviour fixed when the program is built). This document compares them and when to use each.

---

## 1. Runtime polymorphism

**Mechanism:** Base class with **virtual** functions; derived classes **override** them. A pointer or reference to the base can refer to any derived type; the actual function called is determined at **runtime** from the object’s dynamic type.

**Characteristics:**

- Resolution: **at runtime** (vtable dispatch).
- Flexibility: new derived types can be added and used through the same base interface without recompiling existing code (e.g. plugins).
- Cost: indirection (vtable/vptr), possible cache effects; virtual calls cannot be inlined across the call boundary.
- Types: must share a common base; hierarchy is explicit.

**Typical use:** Heterogeneous collections (e.g. `vector<unique_ptr<Shape>>`), callbacks/observers, strategy-like behaviour when the set of types is open or loaded at runtime.

See [Polymorphism](polymorphism.md) and [Inheritance](inheritance.md).

```cpp
Shape* p = getShape();  // might be Circle, Square, ...
p->area();              // which area() runs is decided at runtime
```

---

## 2. Compile-time polymorphism

**Mechanism:** **Templates** (one implementation for many types) and **overloading** (different functions for different argument types). The compiler picks the function or generates the template instantiation at **compile time**; no vtable at runtime.

**Characteristics:**

- Resolution: **at compile time**.
- Flexibility: any type that satisfies the operations used in the template (or matches an overload) works; no shared base required. Adding a new type often means recompiling code that uses it.
- Cost: no vtable; calls can be inlined; possible code size increase from multiple instantiations.
- Types: no inheritance required; [concepts](concepts.md) (C++20) document requirements.

**Typical use:** Containers and algorithms (e.g. `std::vector<T>`, `std::sort`), generic utilities, when the set of types is known at compile time and you want maximum performance and inlining.

See [Templates](templates.md) and [Concepts](concepts.md).

```cpp
template<typename T>
T add(T a, T b) { return a + b; }
add(1, 2);      // int at compile time
add(1.0, 2.0);  // double at compile time
```

---

## 3. Side-by-side comparison

| Aspect | Runtime (virtual) | Compile-time (templates/overloads) |
|--------|--------------------|------------------------------------|
| When resolved | Runtime | Compile time |
| Mechanism | Virtual functions, vtables | Templates, overloading |
| Type requirement | Common base class | Same operations (duck typing / concepts) |
| Adding new “form” | New derived class; no recompile of base users if loaded dynamically | New type or overload; recompile code that uses it |
| Call cost | Indirect call, usually no inlining | Can be inlined |
| Code size | One implementation shared by all derived types | One (or more) instantiation per type |
| Errors | Often at runtime if wrong type/cast | At compile time when template/overload is used |

---

## 4. Overloading as compile-time polymorphism

**Overloading** is also compile-time polymorphism: the same name (e.g. `print`) refers to different functions depending on argument types, and the choice is made at **compile time**.

```cpp
void print(int x);
void print(const std::string& s);
void print(const std::vector<int>& v);

print(42);        // compiler picks print(int)
print("hello");   // compiler picks print(const std::string&)
```

No inheritance or virtual needed; the compiler picks the best match from the overload set. See [Functions](functions.md).

---

## 5. When to use which

- **Runtime polymorphism** when:
  - You have a fixed interface and multiple implementations chosen at runtime (e.g. different backends, plugins, strategies).
  - You need heterogeneous collections (different concrete types behind a common base pointer/reference).
  - The set of types can grow without recompiling (e.g. loadable modules).

- **Compile-time polymorphism** when:
  - You want generic code over many types with the same operations (containers, algorithms).
  - Performance and inlining matter; you’re not adding types at runtime.
  - You don’t want or need a common base (value types, primitives, third-party types).

You can combine both: e.g. a template function that works with any type, and inside it call a virtual function on a base interface when the type is part of a hierarchy.

---

## 6. Quick reference

| Goal | Use |
|------|-----|
| One interface, behaviour chosen at runtime | Virtual functions + inheritance |
| One interface, behaviour chosen at compile time | Templates + overloading (and concepts) |
| Heterogeneous collection, same base type | Runtime (base pointer/ref or smart pointer) |
| Generic algorithm over many unrelated types | Compile-time (templates) |
| No inheritance, “duck typing” | Compile-time (templates/concepts) |

---

## See also

- [Polymorphism](polymorphism.md) – virtual functions and runtime polymorphism
- [Inheritance](inheritance.md) – base and derived classes
- [Templates](templates.md) – generic code and compile-time polymorphism
- [Concepts](concepts.md) – constraining template types
