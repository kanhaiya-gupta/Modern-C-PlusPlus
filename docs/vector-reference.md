# Vector Reference (std::vector)

A complete reference of **std::vector&lt;T&gt;** member functions and common operations. Vector is the default choice for a dynamic sequence: contiguous storage, O(1) amortized push_back, O(1) random access. See [Containers](containers.md) and [STL Containers](stl-containers.md) for comparison with other containers.

---

## 1. Header and type

```cpp
#include <vector>
std::vector<T> v;
```

---

## 2. Construction and assignment

| Operation | What it does |
|-----------|----------------|
| **vector()** | Default constructor: empty vector. |
| **vector(size_type n)** | Creates vector with **n** value-initialized elements. |
| **vector(size_type n, const T& value)** | Creates vector with **n** copies of **value**. |
| **vector(InputIt first, InputIt last)** | Creates vector from range [first, last). |
| **vector(const vector& other)** | Copy constructor. |
| **vector(vector&& other)** | Move constructor (C++11); **other** is left empty. |
| **vector(initializer_list&lt;T&gt; init)** | Creates vector from **{ a, b, c }**. |
| **operator=(const vector&)** | Copy assignment. |
| **operator=(vector&&)** | Move assignment (C++11). |
| **operator=(initializer_list&lt;T&gt;)** | Assign from **{ a, b, c }**; resizes as needed. |
| **assign(size_type n, const T& value)** | Replaces contents with **n** copies of **value**. |
| **assign(InputIt first, InputIt last)** | Replaces contents with range [first, last). |
| **assign(initializer_list&lt;T&gt;)** | Replaces contents with the initializer list. |

**Examples:**

```cpp
std::vector<int> v1;                      // v1 is empty
std::vector<int> v2(5);                   // v2 has 5 zeros: {0,0,0,0,0}
std::vector<int> v3(3, 10);               // v3: {10, 10, 10}
std::vector<int> v4(v3.begin(), v3.end()); // v4: copy of v3
std::vector<int> v5(v4);                  // v5: copy of v4
std::vector<int> v6(std::move(v5));       // v6 gets v5's buffer; v5 is empty
std::vector<int> v7 = {1, 2, 3};          // v7: {1, 2, 3}

v1 = v7;                                  // v1 is now {1, 2, 3}
v2 = {9, 8};                              // v2 is now {9, 8} (resized)
v3.assign(4, 7);                          // v3: {7, 7, 7, 7}
v4.assign(v7.begin() + 1, v7.end());      // v4: {2, 3}
v5.assign({5, 6, 7});                     // v5: {5, 6, 7}
```

---

## 3. Capacity

| Operation | What it does | Notes |
|-----------|----------------|-------|
| **empty()** | Returns **true** if size is 0. | O(1) |
| **size()** | Returns number of elements. | O(1) |
| **max_size()** | Returns maximum possible size (implementation limit). | O(1) |
| **reserve(size_type n)** | Requests capacity at least **n**. Does not change size; may reallocate. No effect if **n ≤ capacity()**. | Use before many **push_back** to avoid reallocations. |
| **capacity()** | Returns number of elements that can be held without reallocation. | **capacity() ≥ size()**. |
| **shrink_to_fit()** | Requests removal of unused capacity (non-binding). | C++11; implementation may ignore. |

**Important:** After **reserve(n)**, iterators and references stay valid until the next reallocation. **push_back** up to **capacity()** does not reallocate.

**Examples:**

```cpp
std::vector<int> v = {1, 2, 3};
v.empty();      // false
v.size();       // 3
v.capacity();   // >= 3 (implementation-defined)
v.max_size();   // large number (implementation limit)

v.reserve(100); // capacity now >= 100; size still 3
v.push_back(4); // no reallocation (size 4 <= capacity)
v.shrrink_to_fit(); // request to reduce capacity to size (non-binding)
```

---

## 4. Element access

| Operation | What it does | Notes |
|-----------|----------------|-------|
| **operator[](size_type i)** | Returns reference to element at index **i**. No bounds check. | O(1); undefined if **i ≥ size()**. |
| **at(size_type i)** | Returns reference to element at index **i**. **Throws std::out_of_range** if **i ≥ size()**. | O(1). |
| **front()** | Returns reference to first element. | Undefined if empty. |
| **back()** | Returns reference to last element. | Undefined if empty. |
| **data()** | Returns pointer to underlying array (T*). Elements are contiguous. | For C API or pointer arithmetic; valid range [data(), data() + size()). |

**Examples:**

```cpp
std::vector<int> v = {10, 20, 30, 40};
v[0];       // 10 (no bounds check)
v[2];       // 30
v.at(1);    // 20; if index >= 4, throws std::out_of_range
v.front();  // 10
v.back();   // 40
v.data();   // int* to first element; v.data()[i] same as v[i]

v[1] = 99;  // v: {10, 99, 30, 40}
v.back() = 0; // v: {10, 99, 30, 0}
```

---

## 5. Modifiers

| Operation | What it does | Complexity |
|-----------|----------------|------------|
| **clear()** | Destroys all elements; size becomes 0. Capacity may be unchanged. | O(n) |
| **insert(pos, const T& value)** | Inserts **value** before **pos**; returns iterator to new element. | O(n) |
| **insert(pos, size_type n, const T& value)** | Inserts **n** copies of **value** before **pos**. | O(n) |
| **insert(pos, InputIt first, InputIt last)** | Inserts range [first, last) before **pos**. | O(n) |
| **insert(pos, initializer_list&lt;T&gt;)** | Inserts list before **pos**. | O(n) |
| **emplace(pos, args...)** | Inserts element constructed from **args...** before **pos**; returns iterator to new element. | O(n) |
| **erase(pos)** | Removes element at **pos**; returns iterator to next element. | O(n) |
| **erase(first, last)** | Removes elements in [first, last); returns iterator to element after last removed. | O(n) |
| **push_back(const T& x)** | Appends copy of **x**. | Amortized O(1) |
| **push_back(T&& x)** | Appends by moving **x**. | Amortized O(1) |
| **emplace_back(args...)** | Appends element constructed from **args...** in place. | Amortized O(1) |
| **pop_back()** | Removes last element; size decreases by 1. Destructor is called. | O(1); undefined if empty. |
| **resize(size_type n)** | If **n &lt; size()**, erases trailing elements. If **n &gt; size()**, appends value-initialized elements. | O(n) |
| **resize(size_type n, const T& value)** | Same as **resize(n)** but new elements are copies of **value**. | O(n) |
| **swap(vector& other)** | Exchanges contents with **other**. Iterators/references now refer to the other vector. | O(1) |

**Iterator invalidation:** Insert/erase (except at end) and reallocation invalidate iterators, pointers, and references to elements. **push_back**/ **emplace_back** invalidate them only if reallocation happens (when **size() == capacity()** before the push).

**Examples:**

```cpp
std::vector<int> v = {1, 2, 3};

v.clear();                    // v is empty; capacity may be unchanged

v = {1, 2, 3};
v.insert(v.begin(), 0);       // v: {0, 1, 2, 3}
v.insert(v.end(), 2, 9);      // v: {0, 1, 2, 3, 9, 9}
v.insert(v.begin() + 2, {7, 8}); // v: {0, 1, 7, 8, 2, 3, 9, 9}
v.emplace(v.begin(), -1);     // v: {-1, 0, 1, 7, 8, 2, 3, 9, 9}

v.erase(v.begin());           // remove first: v: {0, 1, 7, 8, 2, 3, 9, 9}
v.erase(v.begin() + 2, v.begin() + 5); // v: {0, 1, 3, 9, 9}

v.push_back(10);              // v: {0, 1, 3, 9, 9, 10}
v.emplace_back(11);           // v: {..., 11}
v.pop_back();                 // v: {0, 1, 3, 9, 9, 10}

v.resize(4);                  // v: {0, 1, 3, 9} (trailing elements removed)
v.resize(6, 99);              // v: {0, 1, 3, 9, 99, 99}

std::vector<int> w = {100, 200};
v.swap(w);                    // v is now {100, 200}; w is {0, 1, 3, 9, 99, 99}
```

---

## 6. Iterators

| Operation | What it does |
|-----------|----------------|
| **begin()** / **cbegin()** | Iterator to first element. |
| **end()** / **cend()** | Iterator past the last element. |
| **rbegin()** / **crbegin()** | Reverse iterator: last element. |
| **rend()** / **crend()** | Reverse iterator past the first element. |

Vector provides **random access iterators**: you can do **it + n**, **it - n**, **it[n]**, **&lt;** comparison, etc.

**Examples:**

```cpp
std::vector<int> v = {10, 20, 30, 40};
auto it = v.begin();
*it;           // 10
*(it + 2);     // 30
it[3];         // 40
it < v.end();  // true

for (auto it = v.begin(); it != v.end(); ++it) { /* *it */ }
for (auto it = v.cbegin(); it != v.cend(); ++it) { /* read-only */ }
for (auto it = v.rbegin(); it != v.rend(); ++it) { /* reverse: 40, 30, 20, 10 */ }

// Range-based for (uses begin/end)
for (int x : v) { /* x is each element */ }
```

---

## 7. Comparison (non-member)

**operator==**, **operator!=**, **operator&lt;** (and **&lt;=**, **&gt;**, **&gt;=**) compare vectors lexicographically (element by element). **operator&lt;** uses **operator&lt;** on **T**.

```cpp
std::vector<int> a = {1, 2}, b = {1, 2, 3};
a < b;   // true (a is prefix)
```

---

## 8. swap (non-member)

**std::swap(v1, v2)** — Swaps two vectors; same as **v1.swap(v2)**. O(1).

```cpp
std::vector<int> a = {1, 2}, b = {3, 4, 5};
std::swap(a, b);  // a: {3, 4, 5}, b: {1, 2}
```

---

## 9. Common algorithms used with vector

These are from **&lt;algorithm&gt;** or **&lt;ranges&gt;**; they work on vector iterators or the vector as a range.

| Algorithm | What it does |
|-----------|----------------|
| **std::sort(begin, end)** / **std::ranges::sort(v)** | Sorts elements (ascending by default). |
| **std::stable_sort(...)** | Stable sort (order of equal elements preserved). |
| **std::partial_sort(begin, mid, end)** | Sorts so [begin, mid) are the smallest (or largest with comparator). |
| **std::nth_element(begin, nth, end)** | Puts the nth element in sorted position; elements before (after) are ≤ (≥) it. |
| **std::find(begin, end, value)** | Returns iterator to first occurrence of **value**, or **end** if not found. |
| **std::find_if(begin, end, pred)** | Returns iterator to first element for which **pred** is true. |
| **std::count(begin, end, value)** | Counts elements equal to **value**. |
| **std::count_if(begin, end, pred)** | Counts elements for which **pred** is true. |
| **std::reverse(begin, end)** | Reverses the range in place. |
| **std::rotate(begin, mid, end)** | Rotates so *mid becomes first: [mid, end) then [begin, mid). |
| **std::unique(begin, end)** | “Removes” consecutive duplicates; returns new logical end. Often followed by **erase**. |
| **std::merge(...)** | Merges two sorted ranges into one (output iterator). |
| **std::fill(begin, end, value)** | Assigns **value** to every element. |
| **std::iota(begin, end, start)** | Fills with **start**, **start+1**, **start+2**, … |
| **std::min_element(begin, end)** | Iterator to minimum element. |
| **std::max_element(begin, end)** | Iterator to maximum element. |
| **std::minmax_element(begin, end)** | Pair of iterators: min and max. |
| **std::partition(begin, end, pred)** | Reorders so all elements for which **pred** is true come before the rest. |
| **std::stable_partition(...)** | Same, but relative order within each group is preserved. |
| **std::binary_search(begin, end, value)** | **true** if **value** is in the sorted range. |
| **std::lower_bound(begin, end, value)** | First position where **value** can be inserted keeping order. |
| **std::upper_bound(begin, end, value)** | First position after last **value**. |
| **std::equal_range(begin, end, value)** | Pair **{lower_bound, upper_bound}**. |

With **C++20 ranges**: **std::ranges::sort(v)**, **std::ranges::find(v, value)**, **std::ranges::count_if(v, pred)**, etc. — pass the vector (or a view) instead of begin/end.

**Examples:**

```cpp
#include <vector>
#include <algorithm>
#include <ranges>

std::vector<int> v = {3, 1, 4, 1, 5};

std::sort(v.begin(), v.end());              // v: {1, 1, 3, 4, 5}
// std::ranges::sort(v);                    // same

auto it = std::find(v.begin(), v.end(), 4); // it points to 4
int n = std::count(v.begin(), v.end(), 1);  // n == 2
std::reverse(v.begin(), v.end());           // v: {5, 4, 3, 1, 1}

std::vector<int> a = {1, 3, 5}, b = {2, 4, 6};
std::vector<int> merged;
std::merge(a.begin(), a.end(), b.begin(), b.end(), std::back_inserter(merged));
// merged: {1, 2, 3, 4, 5, 6}

std::fill(v.begin(), v.end(), 0);           // v: {0, 0, 0, 0, 0}
std::iota(v.begin(), v.end(), 1);           // v: {1, 2, 3, 4, 5}

auto minIt = std::min_element(v.begin(), v.end()); // *minIt == 1
auto maxIt = std::max_element(v.begin(), v.end()); // *maxIt == 5

v = {1, 2, 3, 4, 5};
std::partition(v.begin(), v.end(), [](int x) { return x % 2 == 0; });
// evens first, then odds; order within groups unspecified

std::binary_search(v.begin(), v.end(), 3);   // true if 3 is in sorted range
auto lo = std::lower_bound(v.begin(), v.end(), 2); // first position for 2
auto hi = std::upper_bound(v.begin(), v.end(), 2); // first position after 2
auto [lo2, hi2] = std::equal_range(v.begin(), v.end(), 2);
```

---

## 10. Multi-dimensional vectors

A **2D vector** is a vector of vectors: **std::vector&lt;std::vector&lt;T&gt;&gt;**; each inner vector is a row (or column). You can extend to 3D or more by nesting further.

### 10.1 Declaration and dimensions

- **rows**: number of inner vectors (e.g. **grid.size()**).
- **columns**: number of elements in each row (e.g. **grid[0].size()**). Rows can have different sizes (jagged) unless you keep them fixed.

```cpp
#include <vector>

// 2D: vector of vector<int>
std::vector<std::vector<int>> grid;

// 3D: vector of vector of vector<int>
std::vector<std::vector<std::vector<int>>> cube;
```

### 10.2 Construction and initialization

**Fixed rows and columns (rectangular):**

```cpp
// R rows, C columns, all elements 0
int R = 3, C = 4;
std::vector<std::vector<int>> grid(R, std::vector<int>(C));
// grid.size() == 3, grid[0].size() == 4

// R rows, C columns, all elements -1
std::vector<std::vector<int>> grid2(R, std::vector<int>(C, -1));

// From initializer list (list of rows)
std::vector<std::vector<int>> grid3 = {
    {1, 2, 3},
    {4, 5, 6},
    {7, 8, 9}
};
```

**Jagged (rows can have different lengths):**

```cpp
std::vector<std::vector<int>> jagged = {
    {1, 2},
    {3, 4, 5},
    {6}
};
// jagged[0].size() == 2, jagged[1].size() == 3, jagged[2].size() == 1
```

### 10.3 Accessing elements

Use **grid[row][col]** for row and column index. **at(row, col)** is not a single call; use **grid.at(row).at(col)** for bounds-checked access.

```cpp
std::vector<std::vector<int>> grid = {
    {10, 20, 30},
    {40, 50, 60}
};

grid[0][0];         // 10
grid[1][2];         // 60
grid.at(0).at(1);   // 20 (throws if out of range)

grid[0][1] = 99;    // modify: row 0, col 1 is now 99
```

### 10.4 Resizing

Resize the outer vector (number of rows), then each row (number of columns). To keep a rectangular grid, resize every row when you change the number of columns.

```cpp
std::vector<std::vector<int>> grid(2, std::vector<int>(3, 0));
// 2x3 grid of zeros

grid.resize(4);                      // 4 rows; new rows are empty vectors
grid.resize(4, std::vector<int>(3));  // 4 rows, each row has 3 elements (value-initialized)

grid[0].resize(5);   // first row now has 5 elements (others unchanged)
grid[1].push_back(7); // first row now has 4 elements
```

### 10.5 Iterating

**By index:**

```cpp
for (size_t i = 0; i < grid.size(); ++i)
    for (size_t j = 0; j < grid[i].size(); ++j)
        grid[i][j] = 0;
```

**Range-based for (rows, then elements in row):**

```cpp
for (const auto& row : grid) {
    for (int x : row)
        std::cout << x << ' ';
    std::cout << '\n';
}
```

**With iterators:**

```cpp
for (auto rowIt = grid.begin(); rowIt != grid.end(); ++rowIt)
    for (auto colIt = rowIt->begin(); colIt != rowIt->end(); ++colIt)
        *colIt = 0;
```

### 10.6 Adding rows and columns

**Add a row:** push_back a vector of the right size.

```cpp
grid.push_back(std::vector<int>(C, 0));  // add row of C zeros
grid.push_back({1, 2, 3});               // add row with values 1, 2, 3
```

**Add a column:** for each row, push_back one element (or resize and set).

```cpp
for (auto& row : grid)
    row.push_back(0);  // add one column, value 0
```

### 10.7 When to use multi-dimensional vectors

- **vector&lt;vector&lt;T&gt;&gt;** — Flexible; rows can have different lengths. Slightly more overhead (each row is a separate allocation). Good for jagged data or when dimensions change.
- **vector&lt;T&gt; with index math** — One vector of size **rows * cols**; access **v[i * cols + j]** for row **i**, column **j**. One allocation; cache-friendly for row-major traversal. Good for fixed rectangular grids and performance.
- **std::array&lt;std::array&lt;T, C&gt;, R&gt;** — Fixed dimensions at compile time; no dynamic allocation.

**Example: single vector as 2D (row-major):**

```cpp
int R = 3, C = 4;
std::vector<int> grid(R * C, 0);
// access row i, col j: grid[i * C + j]
grid[1 * C + 2] = 42;  // row 1, col 2
```

### 10.8 Quick reference (multi-dimensional)

| Goal | Code |
|------|------|
| Declare 2D | **std::vector&lt;std::vector&lt;T&gt;&gt; grid;** |
| R×C, zeros | **grid(R, std::vector&lt;T&gt;(C));** |
| R×C, value v | **grid(R, std::vector&lt;T&gt;(C, v));** |
| From list | **grid = {{1,2},{3,4}};** |
| Access | **grid[i][j]** or **grid.at(i).at(j)** |
| Rows | **grid.size()** |
| Cols (row i) | **grid[i].size()** |
| Add row | **grid.push_back(std::vector&lt;T&gt;(C));** |
| Add column | **for (auto& row : grid) row.push_back(x);** |
| 1D as 2D | **v[i * C + j]** for row i, col j |

---

## 11. Quick reference table (members only)

| Category | Members |
|----------|---------|
| **Construct** | default, (n), (n, val), (first, last), copy, move, initializer_list |
| **Assign** | operator=, assign(n, val), assign(first, last), assign(init_list) |
| **Capacity** | empty, size, max_size, reserve, capacity, shrink_to_fit |
| **Access** | operator[], at, front, back, data |
| **Modify** | clear, insert, emplace, erase, push_back, emplace_back, pop_back, resize, swap |
| **Iterators** | begin, end, cbegin, cend, rbegin, rend, crbegin, crend |

---

## See also

- [Containers](containers.md) – when to use vector
- [STL Containers](stl-containers.md) – vector summary and other containers
- [Iterators](iterators.md) – iterator categories and invalidation
- [Ranges & Views](ranges-and-views.md) – range-based algorithms and views
- [Practice Questions](practice-questions.md) – problems using vectors
