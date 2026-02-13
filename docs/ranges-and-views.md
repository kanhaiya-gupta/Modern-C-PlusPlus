# Ranges & Views (C++20)

The **ranges** library (C++20) generalizes iterators and algorithms to work with **ranges**: anything you can iterate over (containers, views, generator-like sequences). **Views** are lazy, non-owning ranges that adapt or transform other ranges. This document covers range concepts, range-based algorithms, and views.

---

## 1. What is a range?

A **range** is something that has a **begin** and an **end** (or a **sentinel**), so you can iterate over its elements. Containers (vector, map, etc.), views, and (in C++23) **std::generator** are ranges.

- **Range**: type that has `std::ranges::begin(r)` and `std::ranges::end(r)` (or satisfies the range concept).
- **View**: range that is typically lazy, non-owning, and copyable in O(1) (e.g. a “window” over another range).

Algorithms in **std::ranges** take a range (or ranges) instead of iterator pairs, so you can write **sort(v)** instead of **sort(v.begin(), v.end())**.

---

## 2. Range-based algorithms

Include **&lt;algorithm&gt;** and use the **std::ranges** versions. They take a range as the first argument and optionally a projection.

```cpp
#include <algorithm>
#include <vector>
#include <ranges>

std::vector<int> v = {3, 1, 4, 1, 5};
std::ranges::sort(v);                    // sort whole range
std::ranges::sort(v, std::greater<>());  // descending

auto it = std::ranges::find(v, 4);      // returns iterator
bool found = it != v.end();

int count = std::ranges::count(v, 1);   // 2
```

Many algorithms return **subrange** or iterators; they don’t require `.begin()`/`.end()`.

---

## 3. Views — lazy and composable

**Views** are ranges that usually:

- Do **not** own data; they refer to or transform another range.
- Are **lazy**: elements are computed when you iterate, not when you create the view.
- Are **composable**: you can pipe one view into another.

Create views with **std::views** or the **std::ranges::views** namespace. Use **|** to pipe.

```cpp
#include <ranges>
#include <vector>

std::vector<int> v = {1, 2, 3, 4, 5, 6};

// Even numbers, then square them
auto even_sq = v
    | std::views::filter([](int x) { return x % 2 == 0; })
    | std::views::transform([](int x) { return x * x; });

for (int x : even_sq)
    std::cout << x << ' ';  // 4 16 36
```

No temporary container of “all even numbers” or “all squares” is built; elements are produced on demand. See [Lazy evaluation](lazy-evaluation.md).

---

## 4. Common views

| View | Purpose |
|------|--------|
| **views::filter(pred)** | Elements that satisfy predicate |
| **views::transform(f)** | Transform each element by f |
| **views::take(n)** | First n elements |
| **views::drop(n)** | Skip first n elements |
| **views::reverse** | Iterate in reverse order |
| **views::keys** / **views::values** | Keys or values of key-value ranges (e.g. map) |
| **views::iota(start)** | Infinite (or bounded) sequence start, start+1, ... |
| **views::split(delim)** | Split range by delimiter |

```cpp
auto first3 = v | std::views::take(3);
auto skip2 = v | std::views::drop(2);
auto rev = v | std::views::reverse;
auto nums = std::views::iota(0, 10);  // 0..9
```

---

## 5. Range concepts

Concepts (C++20) describe kinds of ranges:

- **std::ranges::range** — has begin/end.
- **std::ranges::view** — range that is a view (copyable, O(1) copy, etc.).
- **std::ranges::sized_range** — has a size in O(1).
- **std::ranges::random_access_range** — random access iterators.
- **std::ranges::common_range** — begin and end have the same type (needed for some legacy APIs).

Use them to constrain templates or to check capabilities (e.g. “this algorithm needs random_access_range”).

---

## 6. Projections

Many range algorithms accept a **projection**: a callable that is applied to each element before the algorithm’s operation (e.g. compare, find).

```cpp
struct Person { std::string name; int age; };
std::vector<Person> people = {{"Alice", 30}, {"Bob", 25}};
std::ranges::sort(people, {}, &Person::age);   // sort by age
std::ranges::sort(people, std::ranges::greater(), &Person::name);  // by name, descending
```

The **{}** is the comparator (default); the third argument is the projection (here, member pointer).

---

## 7. Creating a range from iterators

**std::ranges::subrange(it, sentinel)** wraps a pair of iterator and sentinel into a range. Useful when you have iterators from an algorithm (e.g. find) and want to pass a range to another algorithm or view.

```cpp
auto [first, last] = std::ranges::find(v, 0);
if (first != last)
    std::ranges::sort(std::ranges::subrange(first, last));
```

---

## 8. Quick reference

| Idea | Tool |
|------|------|
| Algorithm on whole container | std::ranges::sort(v), find(v, x), count(v, x), etc. |
| Lazy filter/transform | views::filter(pred), views::transform(f) |
| First n / skip n | views::take(n), views::drop(n) |
| Reverse | views::reverse |
| Compose | v \| views::filter(...) \| views::transform(...) |
| Projection | Algorithm(range, comparator, projection) |

---

## See also

- [Lazy evaluation](lazy-evaluation.md) – views as lazy ranges
- [Iterators](iterators.md) – iterators underlying ranges
- [Containers](containers.md) – standard containers as ranges
- [Concepts](concepts.md) – range concepts
