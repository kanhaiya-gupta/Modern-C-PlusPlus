# Iterators

**Iterators** abstract the notion of “position” in a sequence. They let algorithms and range-based for work uniformly on containers, views, and streams. The standard defines **iterator categories** (input, forward, bidirectional, random access, contiguous) and **sentinel** for “end” positions. This document covers the main categories, how to use iterators, and how they relate to ranges.

---

## 1. What is an iterator?

An **iterator** is an object that refers to an element (or past-the-end) in a sequence. You can:

- **Dereference** (`*it`) to get the element.
- **Increment** (`++it`) to move to the next element (and for some categories, decrement or add an integer).
- **Compare** with another iterator or a **sentinel** (e.g. `it != end`).

Containers provide **begin()** and **end()**; algorithms take iterator (or iterator + sentinel) pairs or ranges. See [Ranges & Views](ranges-and-views.md) for the range abstraction.

---

## 2. Iterator categories

Categories describe what operations an iterator supports. Stronger categories support everything weaker categories do, plus more.

| Category | Operations | Example |
|----------|-------------|---------|
| **Input** | Read once, increment (++) | Stream iterators, some view iterators |
| **Forward** | Read, increment; multi-pass | std::forward_list |
| **Bidirectional** | Forward + decrement (--) | std::list, std::map |
| **Random access** | Bidirectional + +n, -n, &lt;, [] | std::vector, std::deque |
| **Contiguous** (C++17) | Random access + contiguous storage | std::vector, std::array |

Algorithms are specified in terms of categories: e.g. **std::sort** needs random access; **std::find** only needs input.

---

## 3. begin and end

- **begin(c)** / **c.begin()** — iterator to the first element (or past-the-end if empty).
- **end(c)** / **c.end()** — past-the-end; not dereferenceable. **it != end(c)** is the usual loop condition.

```cpp
std::vector<int> v = {1, 2, 3};
for (auto it = v.begin(); it != v.end(); ++it)
    std::cout << *it << ' ';
```

**cbegin** / **cend** return const iterators (read-only). **rbegin** / **rend** return reverse iterators (for traversing backward).

---

## 4. Using iterators with algorithms

Algorithms from **&lt;algorithm&gt;** take iterator ranges: **first** and **last** (one past the last element).

```cpp
#include <algorithm>
#include <vector>

std::vector<int> v = {3, 1, 4, 1, 5};
std::sort(v.begin(), v.end());
auto it = std::find(v.begin(), v.end(), 4);
if (it != v.end())
    *it = 42;
```

With C++20 ranges you often pass the whole range instead of begin/end; see [Ranges & Views](ranges-and-views.md).

---

## 5. Invalidating iterators

Iterators can become **invalid** when the underlying sequence is modified (e.g. reallocation, erase). After **push_back** on a **std::vector**, all iterators may be invalid if reallocation happened. After **erase** on a container, iterators to the erased element (and sometimes others) are invalid. Don’t use invalidated iterators.

---

## 6. Reverse iterators

**rbegin()** and **rend()** return reverse iterators. Incrementing a reverse iterator moves backward in the sequence. **base()** converts to the corresponding normal iterator.

```cpp
for (auto it = v.rbegin(); it != v.rend(); ++it)
    std::cout << *it << ' ';  // reverse order
```

---

## 7. Iterator traits and distance

**std::iterator_traits&lt;It&gt;** expose the iterator’s **value_type**, **difference_type**, **category**, etc. **std::distance(first, last)** gives the number of steps from first to last (O(1) for random access, O(n) for input/forward/bidirectional). **std::advance(it, n)** moves **it** by **n** steps.

---

## 8. Sentinels (C++20)

A **sentinel** is a type that can be compared to an iterator to denote the end of a range, but it might not be the same type as the iterator (e.g. “null” or “end of stream”). Ranges in C++20 use **iterator + sentinel** pairs; **std::ranges::end(r)** may return a sentinel. That allows “unbounded” or custom end conditions without a full iterator type.

---

## 9. Quick reference

| Concept | Meaning |
|--------|--------|
| begin/end | Start and past-the-end of a sequence |
| *it, ++it | Dereference and advance |
| Categories | Input → Forward → Bidirectional → Random access → Contiguous |
| Invalidated | Don’t use iterators after reallocation or erase that invalidates them |
| Reverse | rbegin(), rend() for backward iteration |
| Ranges | C++20: pass range instead of (begin, end) where possible |

---

## See also

- [Containers](containers.md) – containers and their iterators
- [STL Containers](stl-containers.md) – iterator invalidation rules per container
- [Ranges & Views](ranges-and-views.md) – ranges and views built on iterators
- [Templates](templates.md) – algorithms written in terms of iterator types
