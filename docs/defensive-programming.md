# Defensive Programming

**Defensive programming** means writing code that checks assumptions, validates inputs, and fails in a controlled way when something is wrong. It reduces bugs, makes failures easier to diagnose, and limits damage from invalid state. This document covers assertions, input validation, null and bounds checks, and how it ties to RAII, exceptions, and const correctness. See [Exception handling](exception-handling.md), [RAII](raii.md), and [Const correctness](const-correctness.md) for related topics.

---

## 1. What is defensive programming?

- **Check assumptions** (e.g. “this pointer is not null,” “index is in range”) before using them.
- **Validate inputs** at boundaries (e.g. function parameters, data from outside) and reject or handle invalid cases.
- **Fail fast and clearly** (assert, exception, or documented error return) instead of continuing with bad data and causing undefined behaviour or silent wrong results.
- **Use the type system and idioms** (RAII, const, smart pointers) so many classes of bugs are prevented by design.

Defensive programming is not “paranoid” code everywhere—it’s targeted checks at boundaries and critical points, plus consistent use of safe patterns.

---

## 2. Assertions (assert and static_assert)

Use **assert(condition)** to document and check **invariants** during development. If the condition is false, the program prints a message and typically aborts. Assertions are usually disabled in release builds (**NDEBUG** defined), so use them for “this must never happen” logic, not for recoverable errors.

```cpp
#include <cassert>

void process(int* data, std::size_t size) {
    assert(data != nullptr && "data must not be null");
    assert(size > 0 && "size must be positive");
    // ...
}
```

Use **static_assert(condition, "message")** for **compile-time** checks (e.g. type size, constant expressions). It never runs at runtime and cannot be disabled.

```cpp
static_assert(sizeof(int) >= 4, "int must be at least 4 bytes");
static_assert(std::is_same_v<T, int> || std::is_same_v<T, long>, "T must be int or long");
```

Use assertions for programmer errors (bugs); use **exceptions** or error returns for invalid input or runtime failures that the program might recover from. See [Exception handling](exception-handling.md).

---

## 3. Input validation

Validate **inputs at boundaries**: function parameters, data read from files or the network, user input. Decide what “valid” means and what to do when input is invalid: return an error, throw, or fix up (e.g. clamp) when that is well-defined.

```cpp
// Return a result struct instead of throwing, if that’s your design
struct ParseResult { bool ok; int value; };
ParseResult parsePositive(const std::string& s) {
    if (s.empty()) return {false, 0};
    int v = 0;
    for (char c : s) {
        if (c < '0' || c > '9') return {false, 0};
        v = v * 10 + (c - '0');
    }
    return {true, v};
}

// Or throw for invalid input at a public API boundary
void setSize(int size) {
    if (size < 0 || size > maxSize)
        throw std::invalid_argument("size out of range");
    size_ = size;
}
```

Validate once at the boundary; inside the module assume the data is already valid so you don’t repeat checks everywhere.

---

## 4. Null and pointer checks

Before **dereferencing a pointer**, ensure it is not null (or use a type that cannot be null, e.g. a reference or a smart pointer that you know is non-null).

```cpp
void use(int* p) {
    if (!p) return;  // or throw, or return an error
    *p = 42;
}
```

Prefer **references** for “must be valid” parameters so the type system enforces non-null. Prefer **smart pointers** for ownership so you don’t mix “who deletes” with “is it null.” See [Pointers & references](pointers-and-references.md), [Smart pointers](smart-pointers.md).

---

## 5. Bounds checking

Before **indexing into an array or container**, ensure the index is in range. Use **at()** when you want a runtime check (it throws **std::out_of_range**); use **operator[]** when you have already guaranteed the index is valid (e.g. in a loop with a valid range).

```cpp
std::vector<int> v = {1, 2, 3};
// v.at(10);   // throws std::out_of_range
// v[10];      // undefined behaviour

std::size_t i = getIndex();
if (i < v.size())
    v[i] = 0;
else
    // handle error
```

In loops, prefer **range-based for** or iterators so you don’t manage indices by hand. See [Containers](containers.md), [Iterators](iterators.md).

---

## 6. RAII and exception safety

Use **RAII** so that resources are released even when an error occurs or an exception is thrown. Then you don’t rely on “remember to release” along every path. Lock guards, smart pointers, and custom RAII types are defensive: they make leaks and double-release much harder. See [RAII](raii.md), [Exception handling](exception-handling.md).

---

## 7. Const and immutability

Use **const** so that values that shouldn’t change cannot be modified. That prevents accidental writes and documents intent. Const correctness is a form of defensive programming: the compiler enforces “read-only” where you mark it. See [Const correctness](const-correctness.md).

---

## 8. Defensive copies (when to copy)

When you store or pass data that might be modified by someone else, sometimes you make a **copy** so your object doesn’t depend on the lifetime or mutations of external data. For example, storing **std::string** by value instead of **const std::string&** in a member keeps a snapshot. Don’t over-copy; use references or views when you intentionally share. See [Pointers & references](pointers-and-references.md).

---

## 9. What not to do

- **Don’t** use assertions for recoverable errors (e.g. “file not found”). Use exceptions or error returns and handle them.
- **Don’t** ignore return values or error codes from functions that can fail.
- **Don’t** dereference pointers or index containers without ensuring validity first (or using a safe abstraction).
- **Don’t** disable or work around checks (e.g. casts that hide bugs) without a clear, documented reason.

---

## 10. Quick reference

| Practice | Purpose |
|----------|---------|
| assert(cond) | Invariants in debug; aborts if false (often disabled in release) |
| static_assert | Compile-time checks; never disabled |
| Validate at boundaries | Reject or handle invalid input once; assume valid inside |
| Check pointers before use | Avoid null dereference; prefer references/smart pointers |
| Bounds check | Use at() or check index &lt; size() before [] |
| RAII | Release resources on all paths; exception-safe |
| const | Prevent accidental modification; document read-only |

---

## See also

- [Exception handling](exception-handling.md) – throwing and handling errors
- [RAII](raii.md) – resource ownership and cleanup
- [Const correctness](const-correctness.md) – const parameters and members
- [Pointers & references](pointers-and-references.md) – null checks, references
- [Smart pointers](smart-pointers.md) – ownership and non-null by design
