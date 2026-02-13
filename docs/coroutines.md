# Coroutines (C++20)

**Coroutines** are functions that can suspend and resume. They let you write asynchronous or lazy code (e.g. generators, async I/O) without hand-written state machines. The C++20 standard defines the language support; the standard library provides **std::generator** (C++23) and **std::coroutine_handle**; common use is with custom promise types or third-party libraries. This document covers the idea, keywords, and a simple generator-style example.

---

## 1. What is a coroutine?

A **coroutine** is a function that can **suspend** (pause) and later **resume**. When it suspends, control returns to the caller; when it resumes, it continues from where it left off. Local variables are preserved across suspend/resume.

Use cases:

- **Generators**: produce a sequence of values one at a time (lazy).
- **Async I/O**: suspend until data is ready, then resume without blocking a thread.
- **State machines**: express stateful logic as sequential code instead of callbacks.

---

## 2. Keywords

- **co_return** — end the coroutine and optionally return a value (like return for a coroutine).
- **co_yield** — produce a value to the caller and suspend; execution resumes when the caller asks for the next value (in a generator).
- **co_await** — suspend until an awaitable (e.g. a future or custom type) is ready, then resume.

A function is a coroutine if its body contains **co_return**, **co_yield**, or **co_await**.

---

## 3. Generator idea (co_yield)

A **generator** yields a sequence of values. The caller gets values one by one; the coroutine runs until the next **co_yield** or **co_return**.

C++20 does not ship a **std::generator** in the standard; C++23 adds it. Conceptually:

```cpp
// Conceptual: C++23 has std::generator; before that you use a library or hand-roll.
generator<int> count(int n) {
    for (int i = 0; i < n; ++i)
        co_yield i;
}

// Usage (conceptual):
for (int x : count(5)) {
    std::cout << x << ' ';  // 0 1 2 3 4
}
```

Each **co_yield** sends a value to the caller and suspends; when the caller asks for the next value, the coroutine resumes after the **co_yield**.

---

## 4. Awaitables (co_await)

**co_await expr** suspends the coroutine until the **awaitable** (expr) is ready. The awaitable type must support certain operations (await_ready, await_suspend, await_resume). **std::suspend_always** / **std::suspend_never** are trivial awaitables used in promise types.

```cpp
// In a promise type you often see:
struct Promise {
    std::suspend_always initial_suspend() { return {}; }
    std::suspend_always final_suspend() noexcept { return {}; }
    void return_void() {}
    generator::promise_type get_return_object();
    void unhandled_exception() { std::terminate(); }
};
```

Libraries (e.g. cppcoro, or async frameworks) provide awaitables for “resume when I/O completes” or “resume on a thread pool.”

---

## 5. Promise type and coroutine handle

The compiler translates a coroutine into code that uses a **promise type** and a **coroutine handle**. The promise type:

- Defines what the coroutine returns (e.g. a generator object).
- Defines behaviour at start (initial_suspend), end (final_suspend), **co_yield** (yield_value), **co_return** (return_value or return_void), and exceptions (unhandled_exception).

You usually don’t write the body of the coroutine in terms of the promise directly; you use a library type (e.g. **std::generator** in C++23) or a type that documents its promise interface. The **coroutine_handle** is used internally to resume the coroutine.

---

## 6. Simple mental model

- **co_yield value** — “give this value to the caller and pause; when the caller asks for the next, resume here.”
- **co_await something** — “pause until something is ready; when it is, resume here.”
- **co_return** — “finish the coroutine and (optionally) produce a final result.”

Libraries build on this to give you **generator&lt;T&gt;** (range of T), **task&lt;T&gt;** (async result), etc.

---

## 7. Compiler and library support

- C++20: language support (co_await, co_yield, co_return, promise, coroutine_handle) is in the language; the standard library has minimal types (e.g. **std::coroutine_handle**, **std::suspend_always**).
- C++23: **std::generator** for synchronous generators.
- For async I/O or thread-pool tasks, use a library that provides the promise and awaitable types (or write your own).

---

## 8. Quick reference

| Keyword | Meaning |
|--------|--------|
| co_yield expr | Produce value, suspend; resume when caller asks for next (generator) |
| co_await expr | Suspend until expr is ready; then resume |
| co_return [expr] | Finish coroutine; optionally return value |

---

## See also

- [Lazy evaluation](lazy-evaluation.md) – generators as lazy sequences
- [Ranges & Views](ranges-and-views.md) – ranges and lazy views
- [Threading](threading.md) – threads vs coroutines (cooperative multitasking)
