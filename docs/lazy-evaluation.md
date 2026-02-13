# Lazy Evaluation

**Lazy evaluation** means work is done only when a result is needed, not when an expression is built. In C++, this shows up in **views** (C++20), **ranges**, **generators**, and in types that defer computation until you read or iterate. This document covers the idea and how it appears in the standard library and coroutines.

---

## 1. Eager vs lazy

- **Eager**: as soon as you form an expression or call a function, all work runs and results are stored. Example: **std::vector** after **transform** over a vector — you’d first compute every transformed value and store them.
- **Lazy**: you build a “recipe” or a view; the actual computation happens when you **use** the result (e.g. when you iterate or access an element). No full result is materialized until needed.

Lazy evaluation can save memory and time when you only need part of a sequence (e.g. “first 5 even squares”) or when the sequence is conceptually infinite.

---

## 2. C++20 views are lazy

**std::views::filter**, **std::views::transform**, and similar **views** do not iterate the underlying range until you iterate the view. They produce elements on demand.

```cpp
#include <ranges>
#include <vector>

std::vector<int> v = {1, 2, 3, 4, 5};
auto evens = v | std::views::filter([](int x) { return x % 2 == 0; });
// No iteration yet; evens is a view (a recipe).

for (int x : evens)   // Now elements are produced one by one
    std::cout << x;   // 2 4
```

So “filter + transform” does not create an intermediate container of all filtered or transformed values; it computes each element when the loop asks for it. See [Ranges & Views](ranges-and-views.md).

---

## 3. Composing lazy pipelines

You can chain views with **|**. Each step is still lazy; the whole pipeline runs only when you iterate the final view.

```cpp
auto result = v
    | std::views::filter([](int x) { return x > 2; })
    | std::views::transform([](int x) { return x * 2; })
    | std::views::take(2);

for (int x : result)  // only 2 elements computed: 6, 8
    std::cout << x << ' ';
```

So “take(2)” stops the pipeline after two elements; not all elements are processed.

---

## 4. Infinite ranges

**std::views::iota** can represent an unbounded sequence. You can’t store it eagerly; you use it lazily (e.g. with **take** or in a loop that stops).

```cpp
auto naturals = std::views::iota(1);  // 1, 2, 3, ...
auto first10 = naturals | std::views::take(10);
for (int n : first10)
    std::cout << n << ' ';  // 1 2 3 ... 10
```

---

## 5. Generators (coroutines)

A **generator** (e.g. with **co_yield** in a coroutine) produces values one at a time when the consumer asks for the next. That’s lazy: the coroutine runs only until the next **co_yield** (or end). See [Coroutines](coroutines.md).

```cpp
// Conceptual: generator yields values on demand
generator<int> count() {
    for (int i = 0; ; ++i)
        co_yield i;
}
// Only runs as far as you iterate
```

---

## 6. Short-circuit and conditionals

Logical operators **&&** and **||** are lazy in a different sense: they don’t evaluate the right operand if the result is already known. That’s built-in language behaviour, not a library feature, but it’s the same idea: don’t compute until needed.

---

## 7. When to use lazy evaluation

- **Large or infinite sequences**: you don’t want to allocate a full result; produce elements on demand.
- **Pipelines**: filter → transform → take; only the requested part is computed.
- **Performance**: avoid temporary containers and redundant passes when you only need a prefix or a single value.

When you need random access, multiple passes, or a stored collection, an eager container (e.g. **std::vector**) is appropriate; materialize the range (e.g. copy the view into a vector) if needed.

---

## 8. Quick reference

| Mechanism | Lazy behaviour |
|-----------|-----------------|
| std::views::* | No iteration until you iterate the view |
| co_yield (generator) | Coroutine runs only until next yield when consumer asks |
| \|\| and && | Right operand not evaluated if result known |
| Ranges pipeline | Whole pipeline runs only when iterating the final range |

---

## See also

- [Ranges & Views](ranges-and-views.md) – views and range pipelines
- [Coroutines](coroutines.md) – generators with co_yield
- [Containers](containers.md) – eager storage when you need it
