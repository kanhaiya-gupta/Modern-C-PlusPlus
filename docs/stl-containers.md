# STL Containers

The **Standard Template Library (STL)** provides the standard containers, iterators, and algorithms. This document is a concise reference for the main container types and their complexity. For the big picture and “which container to use,” see [Containers](containers.md).

---

## 1. Sequence containers

### std::vector&lt;T&gt;

- **Layout**: Contiguous storage.
- **Key operations**: `push_back`, `pop_back`, `operator[]`, `at`, `size`, `resize`, `reserve`, `clear`.
- **Iterators**: Random access; invalidated on reallocation (insert/erase can reallocate).
- **Complexity**: Amortized O(1) `push_back`; O(1) random access; O(n) insert/erase in the middle.

```cpp
#include <vector>
std::vector<int> v = {1, 2, 3};
v.push_back(4);
v.reserve(100);
int x = v[0];
```

### std::deque&lt;T&gt;

- **Layout**: Chunks of elements; not one contiguous block.
- **Key operations**: `push_back`, `push_front`, `pop_back`, `pop_front`, `operator[]`, `size`.
- **Complexity**: O(1) push/pop at both ends; O(1) random access; O(n) insert/erase in the middle.

### std::list&lt;T&gt;

- **Layout**: Doubly linked list.
- **Key operations**: `push_back`, `push_front`, `insert`, `erase`, `splice`, no `operator[]`.
- **Iterators**: Bidirectional; stable (except erased element). Pointers/references to elements stay valid until erase.
- **Complexity**: O(1) insert/erase at a known position; no random access.

### std::array&lt;T, N&gt;

- **Layout**: Fixed-size aggregate; no dynamic allocation.
- **Key operations**: `operator[]`, `at`, `size`, `fill`; supports aggregate init.
- **Complexity**: O(1) access; size fixed at compile time.

### std::string

- **Layout**: Like vector of char; contiguous.
- **Key operations**: `operator[]`, `at`, `size`, `append`, `substr`, `find`, `compare`, `c_str`, and many more.
- **Complexity**: Similar to vector for indexing and append; find is O(n) or more depending on search.

---

## 2. Ordered associative containers

Require a **strict weak ordering** (default `std::less<Key>`) or a custom comparator. Elements are logically sorted by key.

### std::map&lt;Key, Value&gt;

- **Key operations**: `operator[]`, `at`, `insert`, `emplace`, `find`, `erase`, `count`, `lower_bound`, `upper_bound`.
- **Iterators**: Bidirectional; iterate in sorted key order.
- **Complexity**: O(log n) for insert, find, erase.

### std::set&lt;Key&gt;

- **Key operations**: `insert`, `emplace`, `find`, `erase`, `count`, `lower_bound`.
- **Complexity**: O(log n) for insert, find, erase.

### std::multimap / std::multiset

- Allow duplicate keys; `equal_range`, `count` for multiple matches.
- **Complexity**: Same as map/set (O(log n)).

---

## 3. Unordered associative containers

Require **hash** (e.g. `std::hash<Key>`) and **equality** (e.g. `operator==`). Order is unspecified.

### std::unordered_map&lt;Key, Value&gt;

- **Key operations**: `operator[]`, `at`, `insert`, `emplace`, `find`, `erase`, `count`, `bucket_count`, `rehash`.
- **Complexity**: Average O(1) insert, find, erase; worst case O(n).

### std::unordered_set&lt;Key&gt;

- **Key operations**: `insert`, `emplace`, `find`, `erase`, `count`.
- **Complexity**: Average O(1).

---

## 4. Container adapters

Do not provide iterators; they wrap a sequence container (default shown).

| Adapter | Default underlying | Main operations |
|---------|--------------------|------------------|
| **std::stack&lt;T&gt;** | std::deque&lt;T&gt; | push, pop, top |
| **std::queue&lt;T&gt;** | std::deque&lt;T&gt; | push, pop, front, back |
| **std::priority_queue&lt;T&gt;** | std::vector&lt;T&gt;, std::less&lt;T&gt; | push, pop, top |

---

## 5. Complexity summary

| Container | Index / find | Insert (typical) | Erase (typical) |
|-----------|-------------|------------------|------------------|
| vector | O(1) | O(1) amortized at end; O(n) middle | O(n) |
| deque | O(1) | O(1) at ends; O(n) middle | O(n) |
| list | — | O(1) at position | O(1) at position |
| map/set | — | O(log n) | O(log n) |
| unordered_map/set | — | O(1) avg | O(1) avg |

---

## 6. Include headers

```cpp
#include <vector>
#include <deque>
#include <list>
#include <array>
#include <string>
#include <map>
#include <set>
#include <unordered_map>
#include <unordered_set>
#include <stack>
#include <queue>
```

---

## See also

- [Containers](containers.md) – overview and which container to choose
- [Iterators](iterators.md) – iterator categories and usage
- [Ranges & Views](ranges-and-views.md) – range-based algorithms and views
