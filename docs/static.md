# Static

The keyword **static** has several meanings in C++: **storage duration** (object lives for the whole program), **linkage** (visibility across translation units), **local variables** (one instance per function), and **class members** (shared by the class). This document covers all of these. For static members in detail see [Class](class.md).

---

## 1. Summary of uses

| Where | Meaning |
|-------|---------|
| **Global or namespace scope** | Static storage duration + **internal linkage** (visible only in this file) |
| **Local variable (in a function)** | Static storage duration: one instance, lives for whole program, initialized once |
| **Class/struct member** | One copy per class (not per object); no `this` for static member functions |

---

## 2. Static storage duration

Variables with **static storage duration** live from program start until program end. They are created once and not destroyed when scope ends.

- **Global and namespace-scope variables** have static storage duration by default.
- **Local variables** declared **static** also have static storage duration (and are initialized once, on first use).

```cpp
int global;           // static storage duration (and external linkage)

void f() {
    static int count = 0;  // one instance; initialized once; lives until program end
    ++count;
}
```

---

## 3. Static local variables

A **static local** is a variable inside a function that is declared **static**. There is exactly **one** instance; it is initialized the first time control passes through its declaration; it keeps its value between calls.

```cpp
int nextId() {
    static int id = 0;
    return ++id;
}
// nextId() returns 1, 2, 3, ...
```

Use for one-off initialization (e.g. a cache, a counter, or a “first call” flag). In multithreaded code, static locals need care (initialization is thread-safe in C++11, but subsequent access may need synchronization). See [Threading](threading.md).

---

## 4. Static linkage (file scope)

At **global or namespace scope**, **static** (or **anonymous namespace** in C++) gives the name **internal linkage**: it is visible only in the current translation unit (.cpp file). No symbol is exported to the linker, so the same name can exist in other files.

```cpp
// in file.cpp
static int localToFile = 42;   // internal linkage; not visible in other .cpp files
static void helper() {}        // same

// Prefer in C++:
namespace {
    int alsoLocal = 42;
    void alsoHelper() {}
}
```

In C++, **anonymous namespace** is usually preferred over **static** for file-local names. See [Namespaces](namespaces.md).

---

## 5. Static class data members

A **static data member** belongs to the class, not to each object. There is one copy shared by all objects. It has static storage duration.

- **Declaration** in the class: use **static**.
- **Definition** outside the class (usually in a .cpp): no **static** keyword; use `ClassName::member`.

```cpp
class Counter {
public:
    static int count;  // declaration
    Counter() { ++count; }
};
int Counter::count = 0;  // definition (one copy for all Counter objects)
```

**Inline static data members** (C++17) can be defined and initialized in the class:

```cpp
inline static int count = 0;
```

See [Class](class.md).

---

## 6. Static member functions

A **static member function** does not have a **this** pointer. It can only access **static** members (data or functions) and does not operate on a specific object. Call with `ClassName::name()` or on an object (object is not used).

```cpp
class Counter {
    static int count;
public:
    static int getCount() { return count; }
};
int main() {
    std::cout << Counter::getCount() << '\n';
}
```

Use for operations that don’t need object state (factories, utilities, access to static data). See [Class](class.md).

---

## 7. What static does not mean

- **static** does **not** mean “constant.” Use **const** or **constexpr** for constants.
- **static** does **not** mean “visible only in this function” for a local; it means “one instance, program lifetime.” For “only in this function” you just use a normal local (automatic storage).

---

## 8. thread_local (C++11)

For **thread-local** storage (one instance per thread), use **thread_local** instead of **static** when the variable is at namespace or static local scope. Each thread has its own copy.

```cpp
thread_local int perThread = 0;
void f() {
    thread_local int x = 0;  // one x per thread
}
```

---

## 9. Quick reference

| Context | Effect of static |
|---------|-------------------|
| Global/namespace variable or function | Internal linkage; not visible in other files |
| Local variable | One instance; program lifetime; initialized once |
| Class data member | One copy per class; shared by all objects |
| Class member function | No this; can only use static members |

---

## See also

- [Class](class.md) – static members in detail
- [Namespaces](namespaces.md) – anonymous namespace instead of file-scope static
- [Data types](data-types.md) – variables and types
- [Threading](threading.md) – thread_local and thread safety of static locals
