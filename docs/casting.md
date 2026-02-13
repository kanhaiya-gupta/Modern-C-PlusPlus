# Casting

**Casting** is explicit conversion from one type to another. C++ provides four named casts; each has a specific purpose and makes intent clear. This document covers implicit conversion, the four C++ casts, when to use (or avoid) each, and why to avoid C-style casts. For types and literals see [Data types](data-types.md); for polymorphism see [Inheritance](inheritance.md) and [Polymorphism](polymorphism.md).

---

## 1. Implicit vs explicit conversion

**Implicit conversion** happens automatically when the language allows it: e.g. **int** to **double**, **int** to **unsigned**, **derived*** to **base***, **array** to **pointer** (decay). The compiler applies standard conversions; no cast syntax is needed.

**Explicit conversion** is when you write a cast. Use it when the conversion is not implicit, when you want to make the conversion obvious, or when you need a specific kind of conversion (e.g. **const_cast**, **dynamic_cast**).

---

## 2. The four C++ casts

| Cast | Purpose | When to use |
|------|---------|-------------|
| **static_cast&lt;T&gt;(expr)** | “Normal” conversions | Numeric, base↔derived (when safe), void*↔T* |
| **dynamic_cast&lt;T&gt;(expr)** | Polymorphic down/ side cast | When you need a run-time check; pointers or references |
| **const_cast&lt;T&gt;(expr)** | Add or remove const/volatile | Only when you know the object is not really const |
| **reinterpret_cast&lt;T&gt;(expr)** | Reinterpret bit pattern | Low-level; implementation-defined; last resort |

Prefer the named cast that matches your intent so the compiler and readers know what you are doing.

---

## 3. static_cast

**static_cast&lt;T&gt;(expr)** performs conversions that are well-defined and checked at **compile time**. No run-time type check.

**Typical uses:**

- **Numeric conversions**: float ↔ int, int → double, enum → int. May narrow (e.g. double to int drops the fractional part).
- **Base → derived** (downcast): when you are sure the object is actually of the derived type. If you are wrong, undefined behaviour. Prefer **dynamic_cast** when the type is polymorphic and you are not certain.
- **Derived → base**: usually implicit; use **static_cast** only when needed (e.g. in templates).
- **void* ↔ T***: when you have a void pointer from a C API and know the real type. Cast to the correct pointer type before use.

```cpp
double d = 3.14;
int n = static_cast<int>(d);           // 3

Base* b = getBase();
Derived* d = static_cast<Derived*>(b); // only if *b is really a Derived

void* raw = malloc(sizeof(int));
int* p = static_cast<int*>(raw);
```

**Does not:** remove const (use **const_cast**); perform run-time type check (use **dynamic_cast**); reinterpret bits arbitrarily (use **reinterpret_cast**).

---

## 4. dynamic_cast

**dynamic_cast&lt;T&gt;(expr)** is for **polymorphic** types (types with virtual functions). It performs a **run-time** check. Use it to cast from a base pointer or reference to a derived type when you are not sure of the actual type.

- **Pointer form** `dynamic_cast&lt;Derived*&gt;(basePtr)`: returns a pointer to **Derived** if the object is (or derives from) **Derived**; otherwise returns **nullptr**. Check the result before use.
- **Reference form** `dynamic_cast&lt;Derived&&gt;(baseRef)`: if the object is not of the right type, throws **std::bad_cast**. Use when you expect the cast to succeed.

```cpp
Base* b = getBase();
if (Derived* d = dynamic_cast<Derived*>(b)) {
    // *b is (or derives from) Derived; use d
} else {
    // not Derived
}

Base& br = *b;
try {
    Derived& dr = dynamic_cast<Derived&>(br);
    // use dr
} catch (const std::bad_cast&) {
    // not Derived
}
```

Requires the base to have at least one virtual function (polymorphic type). Has a run-time cost. See [Polymorphism](polymorphism.md) and [Inheritance](inheritance.md).

---

## 5. const_cast

**const_cast&lt;T&gt;(expr)** adds or removes **const** (and **volatile**). It does not change the type in other ways.

**Use only when** the object is not actually const (e.g. you received a **const T&** but know it came from a non-const object, or you are calling a legacy API that takes a non-const pointer but does not modify). Removing const from an object that really is const and then modifying it is undefined behaviour.

```cpp
void legacyApi(int* p);  // doesn't modify *p but takes non-const

void wrapper(const int* p) {
    legacyApi(const_cast<int*>(p));  // only if *p is not really const
}
```

Do not use **const_cast** to “get around” const correctness in your own design; fix the design instead. See [Const correctness](const-correctness.md).

---

## 6. reinterpret_cast

**reinterpret_cast&lt;T&gt;(expr)** reinterprets the bit pattern of the value as another type. The result is **implementation-defined**. No conversion or type check—just “treat these bits as type T.” Use only for low-level code (e.g. serialization, hardware, specific ABI) when you know what you are doing.

```cpp
int i = 0x12345678;
float* fp = reinterpret_cast<float*>(&i);  // same bits, interpreted as float
// *fp is implementation-defined
```

Dangerous: can break aliasing rules and create invalid pointers. Prefer **static_cast** and typed APIs whenever possible.

---

## 7. C-style cast

A C-style cast is **(\*type*)(expr)** or **type(expr)**. The compiler tries **const_cast**, **static_cast**, and **reinterpret_cast** in an implementation-defined order. It can do more than you intend (e.g. remove const and change type) and is hard to search for.

**Avoid in C++.** Use the named cast that matches your intent: **static_cast** for “normal” conversions, **dynamic_cast** for polymorphic downcast, **const_cast** only when you must remove const, **reinterpret_cast** only for low-level reinterpretation.

---

## 8. Narrowing and safety

**Narrowing** (e.g. **double** → **int**, **long** → **short**) can lose information. **static_cast** allows it; **brace-initialization** can warn or error on narrowing in many contexts. Prefer designing interfaces so that narrowing is explicit and rare.

For polymorphic base→derived, **dynamic_cast** is safer than **static_cast** when you are not certain of the runtime type; check the result (pointer) or handle **bad_cast** (reference).

---

## 9. Quick reference

| Need | Cast |
|------|------|
| Numeric, base↔derived (when safe), void*↔T* | static_cast |
| Polymorphic downcast with run-time check | dynamic_cast |
| Add or remove const/volatile | const_cast |
| Reinterpret bits (low-level) | reinterpret_cast |
| Anything else | Prefer redesign; avoid C-style cast |

---

## See also

- [Data types](data-types.md) – types and a brief note on conversion
- [Const correctness](const-correctness.md) – when const_cast is (not) appropriate
- [Inheritance](inheritance.md) – base and derived types
- [Polymorphism](polymorphism.md) – virtual functions and dynamic_cast
