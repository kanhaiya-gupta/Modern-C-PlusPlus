# Namespaces

**Namespaces** group names (types, functions, variables) to avoid collisions and to organize the code. The standard library uses `std`; your code can use a project namespace (e.g. `mylib`) and nested or anonymous namespaces for internal linkage. This document covers defining namespaces, using them, and common patterns.

---

## 1. Defining a namespace

Put declarations and definitions inside `namespace name { ... }`. Namespaces can be split across files (multiple `namespace mylib { ... }` blocks add to the same namespace).

```cpp
namespace mylib {
    class Widget {};
    void process(Widget& w);
    const int defaultSize = 10;
}

// In another file:
namespace mylib {
    void helper();  // adds to mylib
}
```

---

## 2. Using namespace members

**Fully qualified name:** `Namespace::name` — use when you want to be explicit or there are multiple namespaces.

```cpp
mylib::Widget w;
mylib::process(w);
std::vector<int> v;
```

**using declaration:** `using Ns::name;` — brings one name into the current scope.

```cpp
using std::vector;
vector<int> v;  // same as std::vector<int>
```

**using directive:** `using namespace Ns;` — brings all names from `Ns` into the current scope (for the rest of the scope). Use sparingly; can cause name clashes.

```cpp
using namespace std;  // avoid in headers; sometimes used in .cpp
cout << "hello";
```

In **headers**, prefer fully qualified names or `using` declarations for a few symbols. Avoid `using namespace` in headers so you don’t force those names on every includer.

---

## 3. Nested namespaces

Namespaces can be nested. C++17 allows a short form.

```cpp
namespace outer {
    namespace inner {
        void f();
    }
}
// C++17:
namespace outer::inner {
    void g();
}
```

Access: `outer::inner::f()` or, after `using namespace outer::inner;`, just `f()`.

---

## 4. Anonymous (unnamed) namespace

An **anonymous namespace** is `namespace { ... }` in a .cpp file. Names inside it have **internal linkage**: they are visible only in that translation unit. Use instead of `static` for file-local functions and variables.

```cpp
// in file.cpp
namespace {
    int localCounter = 0;
    void localHelper() {}
}
void publicApi() {
    localHelper();
}
```

No name from another .cpp can refer to `localCounter` or `localHelper`; no link conflicts.

---

## 5. Inline namespaces (C++11)

An **inline namespace** is `inline namespace name { ... }`. Its names are visible in the enclosing namespace as if they were declared there. Used for versioning or ABI layers.

```cpp
namespace lib {
    inline namespace v1 {
        void api();
    }
}
lib::api();   // OK: v1 is “inlined”
lib::v1::api();  // also OK
```

If you add `namespace v2 { ... }` later (non-inline), callers can opt in with `lib::v2::api()` without breaking existing `lib::api()`.

---

## 6. Namespace alias

A **namespace alias** shortens a long or nested name.

```cpp
namespace fs = std::filesystem;
namespace my = mycompany::project::module;
fs::path p;
my::Widget w;
```

Useful for long project names or when switching between backends (e.g. `namespace io = mylib::impl::posix;`).

---

## 7. ADL (argument-dependent lookup)

**Argument-dependent lookup** (Koenig lookup): when you call an unqualified function (e.g. `swap(a, b)`), the compiler looks up the function in the namespaces of the types of the arguments as well as in the current scope. That’s why `std::cout << x` finds `operator<<` in the namespace of `x` (and in `std` for the stream).

```cpp
namespace mylib {
    struct Tag {};
    void foo(Tag);
}
mylib::Tag t;
foo(t);  // finds mylib::foo because Tag is in mylib
```

Useful for operators and non-member functions that “belong” to a type. Keep ADL in mind when placing such functions in the same namespace as the type.

---

## 8. Best practices

- Use a **project or library namespace** for your public API (e.g. `mylib`, `mylib::io`).
- In **headers**: avoid `using namespace`; use `Namespace::name` or a few `using Ns::name` if needed.
- In **.cpp** files: `using namespace std` or `using std::vector` is acceptable if it doesn’t cause clashes.
- Use **anonymous namespace** in .cpp for file-local helpers and constants.
- Prefer **namespace aliases** for long or versioned names.

---

## 9. Quick reference

| Construct | Meaning |
|-----------|--------|
| `namespace N { }` | Define or extend namespace N |
| `N::name` | Fully qualified name |
| `using N::name;` | Bring one name into current scope |
| `using namespace N;` | Bring all names of N (use sparingly) |
| `namespace { }` | Anonymous namespace; internal linkage |
| `inline namespace N { }` | Names in N also visible in enclosing namespace |
| `namespace alias = N;` | Shorter name for a namespace |

---

## See also

- [Class](class.md) – types and their scope
- [Templates](templates.md) – templates are often defined in namespaces
- [Functions](functions.md) – free functions and overloads in namespaces
