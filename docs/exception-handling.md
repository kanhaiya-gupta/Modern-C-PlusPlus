# Exception Handling

**Exceptions** let you signal and handle errors without checking return codes at every call. When an exception is thrown, control jumps to a matching **catch** (or the program terminates if none is found). This document covers throw, try/catch, exception safety, and how it interacts with RAII.

---

## 1. Basic syntax

**throw** raises an exception. Usually you throw an object (often derived from **std::exception**).

```cpp
#include <stdexcept>

void mightFail(int x) {
    if (x < 0)
        throw std::invalid_argument("x must be non-negative");
    // ...
}
```

**try** and **catch** handle exceptions. The first matching catch in the call stack runs; then execution continues after the try-catch block (or the function exits).

```cpp
try {
    mightFail(-1);
} catch (const std::invalid_argument& e) {
    std::cerr << "Error: " << e.what() << '\n';
} catch (const std::exception& e) {
    std::cerr << "Exception: " << e.what() << '\n';
}
```

Catch by **const reference** (e.g. `const std::exception&`) to avoid slicing and unnecessary copies.

---

## 2. Exception propagation

If a function doesn’t catch an exception, it propagates to the caller. The stack is unwound: destructors of local objects are run. That’s why **RAII** is important: cleanup happens in destructors even when an exception is thrown. See [RAII](raii.md).

```cpp
void g() {
    FileHandle f("data.txt");  // RAII
    mightFail(42);             // if this throws, f’s destructor still runs
}
```

---

## 3. Standard exception hierarchy

**std::exception** is the common base. **std::runtime_error**, **std::logic_error**, **std::invalid_argument**, **std::out_of_range**, etc. derive from it and take a string (e.g. for **what()**).

```cpp
throw std::runtime_error("file not found");
throw std::invalid_argument("bad value");
throw std::out_of_range("index out of range");
```

Prefer standard types or types derived from **std::exception** so generic handlers can call **what()**.

---

## 4. noexcept (C++11)

**noexcept** marks a function as not throwing. If it does throw, **std::terminate** is called. Use for move operations, destructors, and performance-critical paths so the compiler can optimize (e.g. avoid unwind tables).

```cpp
void noThrow() noexcept {
    // must not throw
}
```

**noexcept** is part of the type system: you can overload or specialize on it. See [Functions](functions.md) and [Move semantics](move-semantics.md).

---

## 5. Exception safety guarantees

Common levels:

- **No-throw**: never throws (e.g. destructors, swap, move in many types).
- **Strong (commit-or-rollback)**: either succeeds or has no effect; no leaks, state unchanged on throw.
- **Basic**: no leaks; object is in a valid (but possibly changed) state.
- **No guarantee**: anything can happen.

Use RAII so that “no leaks” and “valid state” come from destructors. Prefer **noexcept** or strong guarantee where you can document it.

---

## 6. Don’t throw from destructors

Destructors are often called during stack unwinding. If a destructor throws, the program typically calls **std::terminate**. Design destructors to not throw; catch and swallow or log inside the destructor if you must call something that might throw.

---

## 7. Rethrow and catch-all

**throw;** with no expression rethrows the current exception (from inside a catch). Use to log and rethrow or to wrap in another exception.

```cpp
catch (const std::exception& e) {
    log(e.what());
    throw;  // rethrow same exception
}
```

**catch (...)** catches any exception. Use only when you need to do minimal cleanup and then rethrow or terminate; you cannot inspect the exception.

---

## 8. Quick reference

| Construct | Meaning |
|-----------|--------|
| throw expr; | Throw exception; stack unwinding starts |
| try { } catch (T& e) { } | Catch exceptions of type T (or derived) |
| catch (const T& e) | Prefer: catch by const reference |
| throw; | Rethrow current exception |
| noexcept | Function must not throw; terminate if it does |

---

## See also

- [RAII](raii.md) – cleanup in destructors when exceptions are thrown
- [Functions](functions.md) – noexcept
- [Constructors & destructors](constructors-and-destructors.md) – destructors and exceptions
