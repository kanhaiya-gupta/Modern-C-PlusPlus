# Containers

**Containers** hold collections of objects. The C++ standard library provides sequence containers (vector, deque, list), associative containers (map, set, multiset, multimap), unordered associative containers (unordered_map, unordered_set), and adapters (stack, queue, priority_queue). This document covers the container concept, which container to choose, and the main operations. For iterator details see [Iterators](iterators.md); for STL-specific reference see [STL Containers](stl-containers.md).

---

## 1. What is a container?

A container:

- Stores zero or more elements of a (single) element type.
- Offers operations to add, remove, and access elements (the exact set depends on the container).
- Manages the lifetime and layout of its elements (e.g. contiguous array, nodes, hash buckets).

Standard containers are **templates** (e.g. `std::vector<int>`) and support **iterators** for traversal and use with algorithms.

---

## 2. Categories

| Category | Examples | Main traits |
|----------|----------|-------------|
| **Sequence** | vector, deque, list, array | Order is explicit (insert position matters) |
| **Associative (ordered)** | map, set, multimap, multiset | Sorted by key; log-time lookup |
| **Associative (unordered)** | unordered_map, unordered_set, etc. | Hash-based; average constant-time lookup |
| **Adapters** | stack, queue, priority_queue | Restricted interface on top of a sequence |

---

## 3. Which container to use?

- **Default for a dynamic sequence**: **std::vector** — contiguous, cache-friendly, fast random access and back operations. Use unless you need different guarantees.
- **Frequent insert/erase at front**: **std::deque** (or list if you need stable pointers).
- **Sorted by key, key–value pairs**: **std::map** (or **std::set** for keys only). Log-time insert/lookup/erase.
- **Fast lookup by key, order doesn’t matter**: **std::unordered_map** / **std::unordered_set**. Average O(1) insert/lookup/erase; hashing and equality required.
- **Fixed size, known at compile time**: **std::array<T, N>**.
- **String of characters**: **std::string** (sequence of char with string operations).
- **LIFO / FIFO / priority**: **std::stack**, **std::queue**, **std::priority_queue** (backed by a sequence or deque).

---

## 4. Common interface (conceptually)

Many standard containers provide:

- **size()**, **empty()** — number of elements, whether empty.
- **begin()**, **end()** — iterators for range-based for and algorithms.
- **insert**, **erase** (forms vary) — add and remove elements.
- **clear()** — remove all elements.

Sequences also have **front()**, **back()**, **push_back**, **pop_back** (where applicable). Associative containers have **find**, **count**, **operator[]** (map-like), etc. Exact signatures and complexity depend on the container; see [STL Containers](stl-containers.md).

---

## 5. Sequence containers in brief

- **std::vector&lt;T&gt;** — dynamic array; contiguous; amortized O(1) push_back; O(1) random access; insert/erase in the middle O(n).
- **std::deque&lt;T&gt;** — double-ended queue; O(1) push_back/push_front; random access; insert/erase in the middle O(n).
- **std::list&lt;T&gt;** — doubly linked list; O(1) insert/erase at a known position; no random access; stable iterators/pointers if no erase.
- **std::array&lt;T, N&gt;** — fixed-size array; size known at compile time; no dynamic allocation.
- **std::string** — like a vector of char with string operations (compare, find, substr, etc.).

---

## 6. Associative containers in brief

- **std::map&lt;Key, Value&gt;** — unique keys; sorted by Key; log-time insert/find/erase.
- **std::set&lt;Key&gt;** — unique keys; sorted; log-time.
- **std::multimap**, **std::multiset** — allow duplicate keys; same ordering and complexity.
- **std::unordered_map&lt;Key, Value&gt;** — hash map; average O(1); keys need **hash** and **operator==**.
- **std::unordered_set&lt;Key&gt;** — hash set; average O(1).

---

## 7. Container adapters

- **std::stack&lt;T&gt;** — LIFO; by default uses **std::deque&lt;T&gt;**; push, pop, top.
- **std::queue&lt;T&gt;** — FIFO; by default **std::deque&lt;T&gt;**; push, pop, front, back.
- **std::priority_queue&lt;T&gt;** — largest (or custom order) on top; by default **std::vector&lt;T&gt;** and **std::less&lt;T&gt;**; push, pop, top.

They do not expose iterators; they restrict the interface to the abstract data type.

---

## 8. Range-based for and algorithms

All standard containers work with **range-based for** and with **iterators**:

```cpp
std::vector<int> v = {1, 2, 3};
for (int x : v) { ... }
for (auto it = v.begin(); it != v.end(); ++it) { ... }
std::sort(v.begin(), v.end());
```

See [Iterators](iterators.md) and [Ranges & Views](ranges-and-views.md) for modern range-based APIs.

---

## 9. Quick reference

| Need | Container |
|------|-----------|
| Dynamic array, default choice | vector |
| Insert at both ends | deque |
| Stable pointers, no random access | list |
| Fixed size | array |
| Sorted key–value / key only | map / set |
| Fast lookup by key, unsorted | unordered_map / unordered_set |
| LIFO / FIFO / priority | stack / queue / priority_queue |
| Text | string |

---

## See also

- [Iterators](iterators.md) – traversing containers
- [STL Containers](stl-containers.md) – detailed API and complexity
- [Ranges & Views](ranges-and-views.md) – ranges and range algorithms
- [Templates](templates.md) – container types are templates
