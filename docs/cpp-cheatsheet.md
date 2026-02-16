# C++ Cheat Sheet (exam-friendly)

One **concept/command** + **one example** each. Quick reference for exams.

---

## Table of contents

| # | Section |
|---|---------|
| 1 | [Compile & run](#1-compile--run) |
| 2 | [Basics](#2-basics) |
| 3 | [Functions](#3-functions) |
| 4 | [Class & struct](#4-class--struct) |
| 5 | [Inheritance & polymorphism](#5-inheritance--polymorphism) |
| 6 | [Pointers](#6-pointers) |
| 7 | [Smart pointers](#7-smart-pointers) |
| 8 | [STL vector](#8-stl-vector) |
| 9 | [STL map & unordered_map](#9-stl-map-unordered_map) |
| 10 | [Algorithms](#10-algorithms) |
| 11 | [Lambda](#11-lambda) |
| 12 | [Ranges (C++20)](#12-ranges-c20) |
| 13 | [Exception](#13-exception) |
| 14 | [Const, static, namespace](#14-const-static-namespace) |
| 15 | [Template](#15-template) |
| 16 | [Move & RAII (brief)](#16-move--raii-brief) |

---

## 1. Compile & run

| Command | Example |
|--------|---------|
| Compile + link (g++) | `g++ -std=c++17 -o prog main.cpp` |
| Run | `./prog` (Unix) or `prog.exe` (Windows) |
| Compile only (no link) | `g++ -std=c++17 -c main.cpp` |

```bash
g++ -std=c++17 -o hello hello.cpp && ./hello
```

---

## 2. Basics

| Concept | Example |
|--------|---------|
| Variable, type | `int x = 42;` `double d = 3.14;` |
| Reference (alias) | `int& r = x;` — r is another name for x |
| Const | `const int c = 10;` — cannot change c |
| Range-based for | `for (int n : v) cout << n;` |
| Auto | `auto x = 42;` — compiler deduces type |

```cpp
std::vector<int> v = {1, 2, 3};
for (int n : v) std::cout << n << ' ';
```

---

## 3. Functions

| Concept | Example |
|--------|---------|
| Function | `int add(int a, int b) { return a + b; }` |
| Pass by reference | `void f(int& x) { x = 0; }` — can modify x |
| Pass by const ref | `void g(const std::vector<int>& v)` — no copy, no change |
| Default argument | `int h(int a, int b = 0) { return a + b; }` |

```cpp
void swap(int& a, int& b) { int t = a; a = b; b = t; }
```

---

## 4. Class & struct

| Concept | Example |
|--------|---------|
| Class with member | `class C { public: int x; void set(int n) { x = n; } };` |
| Constructor | `C() : x(0) {}` or `C(int n) : x(n) {}` |
| Struct (default public) | `struct S { int a; int b; };` |

```cpp
struct Point { int x, y; };
Point p{1, 2};
```

---

## 5. Inheritance & polymorphism

| Concept | Example |
|--------|---------|
| Inheritance | `class D : public B { };` |
| Override | `void f() override { }` — overrides base virtual |
| Virtual | `virtual void f();` — polymorphic call |
| Pure virtual (abstract) | `virtual void f() = 0;` — must override |

```cpp
class Base { public: virtual void f() { } };
class Derived : public Base { public: void f() override { } };
Base* p = new Derived(); p->f();  // calls Derived::f
```

---

## 6. Pointers

| Concept | Example |
|--------|---------|
| Pointer | `int* p = &x;` — p holds address of x |
| Dereference | `*p = 5;` — change value at address |
| New / delete | `int* p = new int(42);` ... `delete p;` |

```cpp
int x = 10;
int* p = &x;
*p = 20;  // x is now 20
```

---

## 7. Smart pointers

| Concept | Example |
|--------|---------|
| unique_ptr (one owner) | `auto p = std::make_unique<int>(42);` |
| shared_ptr (ref count) | `auto p = std::make_shared<int>(42);` |
| No manual delete | Destructor frees when out of scope |

```cpp
auto p = std::make_unique<std::vector<int>>();
p->push_back(1);
// no delete needed
```

---

## 8. STL vector

| Concept | Example |
|--------|---------|
| Create | `std::vector<int> v = {1, 2, 3};` or `std::vector<int> v(10);` |
| Size | `v.size()` |
| Access | `v[0]` or `v.at(0)` |
| Push back | `v.push_back(4);` |
| Iterate | `for (auto it = v.begin(); it != v.end(); ++it)` or range-for |

```cpp
std::vector<int> v = {3, 1, 2};
std::sort(v.begin(), v.end());  // v = {1, 2, 3}
```

---

## 9. STL map & unordered_map

| Concept | Example |
|--------|---------|
| map (sorted key) | `std::map<std::string, int> m; m["a"] = 1;` |
| unordered_map (hash) | `std::unordered_map<std::string, int> u; u["a"] = 1;` |
| Check key | `if (m.count("a"))` or `m.find("a") != m.end()` |

```cpp
std::unordered_map<int, int> count;
for (int x : nums) count[x]++;
```

---

## 10. Algorithms

| Concept | Example |
|--------|---------|
| Sort | `std::sort(v.begin(), v.end());` |
| Sort with lambda | `std::sort(v.begin(), v.end(), [](int a, int b) { return a > b; });` |
| Find | `auto it = std::find(v.begin(), v.end(), 42);` |
| Count | `int n = std::count(v.begin(), v.end(), 7);` |

```cpp
std::vector<int> v = {5, 2, 8, 1};
std::sort(v.begin(), v.end(), [](int a, int b) { return a > b; });  // 8 5 2 1
```

---

## 11. Lambda

| Concept | Example |
|--------|---------|
| No capture | `[](int x) { return x * 2; }` |
| Capture by value | `[x]() { return x; }` |
| Capture by reference | `[&x]() { x = 0; }` |
| Capture all by value/reference | `[=]` or `[&]` |

```cpp
auto f = [](int a, int b) { return a + b; };
int r = f(1, 2);  // 3
```

---

## 12. Ranges (C++20)

**std::ranges algorithms** (pass range, no `.begin()`/`.end()`):

| Command | Example |
|--------|---------|
| `std::ranges::sort(r)` | `std::ranges::sort(v);` — sort whole range |
| `std::ranges::sort(r, comp)` | `std::ranges::sort(v, std::greater{});` — descending |
| `std::ranges::find(r, val)` | `auto it = std::ranges::find(v, 42);` |
| `std::ranges::count(r, val)` | `int n = std::ranges::count(v, 7);` |
| `std::ranges::count_if(r, pred)` | `int n = std::ranges::count_if(v, [](int x){ return x > 0; });` |
| `std::ranges::min_element(r)` | `auto it = std::ranges::min_element(v);` |
| `std::ranges::max_element(r)` | `auto it = std::ranges::max_element(v);` |
| `std::ranges::all_of(r, pred)` | `bool ok = std::ranges::all_of(v, [](int x){ return x > 0; });` |
| `std::ranges::any_of(r, pred)` | `bool ok = std::ranges::any_of(v, [](int x){ return x == 0; });` |
| `std::ranges::none_of(r, pred)` | `bool ok = std::ranges::none_of(v, [](int x){ return x < 0; });` |

**std::views** (lazy; use `r | std::views::...`):

| Command | Example |
|--------|---------|
| `std::views::filter(pred)` | `v \| std::views::filter([](int x){ return x > 0; })` |
| `std::views::transform(f)` | `v \| std::views::transform([](int x){ return x * 2; })` |
| `std::views::take(n)` | `v \| std::views::take(5)` — first 5 |
| `std::views::drop(n)` | `v \| std::views::drop(2)` — skip first 2 |
| `std::views::reverse` | `v \| std::views::reverse` |
| `std::views::iota(start)` | `std::views::iota(0)` — 0,1,2,... |
| `std::views::iota(start, end)` | `std::views::iota(0, 10)` — 0..9 |
| `std::views::keys` | `m \| std::views::keys` — keys of map |
| `std::views::values` | `m \| std::views::values` — values of map |

**Aggregate commands** (sum, min, max, reduce):

| Command | Example |
|--------|---------|
| `std::accumulate(beg, end, init)` | `int sum = std::accumulate(v.begin(), v.end(), 0);` — sum (init=0) |
| `std::accumulate(beg, end, init, op)` | `int prod = std::accumulate(v.begin(), v.end(), 1, std::multiplies{});` |
| `std::reduce(beg, end)` | `int sum = std::reduce(v.begin(), v.end());` — sum (C++17, may be parallel) |
| `std::reduce(beg, end, init)` | `int sum = std::reduce(v.begin(), v.end(), 0);` |
| `std::ranges::min(r)` | `int m = std::ranges::min(v);` — smallest value (range) |
| `std::ranges::max(r)` | `int m = std::ranges::max(v);` — largest value |
| `std::ranges::minmax(r)` | `auto [lo, hi] = std::ranges::minmax(v);` — min and max |

*Include `<numeric>` for `std::accumulate` and `std::reduce`.*

```cpp
// Pipeline: filter evens, square, take 3
auto r = v | std::views::filter([](int n){ return n % 2 == 0; })
           | std::views::transform([](int n){ return n * n; })
           | std::views::take(3);
for (int x : r) std::cout << x << ' ';
```

---

## 13. Exception

| Concept | Example |
|--------|---------|
| Throw | `throw std::runtime_error("msg");` |
| Try / catch | `try { f(); } catch (const std::exception& e) { }` |

```cpp
try {
    if (x < 0) throw std::invalid_argument("x must be >= 0");
} catch (const std::exception& e) {
    std::cerr << e.what();
}
```

---

## 14. Const, static, namespace

| Concept | Example |
|--------|---------|
| Const member function | `int get() const { return x; }` — doesn't change *this |
| Static (one per class) | `static int count;` |
| Namespace | `namespace N { void f(); }` — call `N::f();` |

```cpp
class C {
public:
    int get() const { return x; }
    static int n;
private:
    int x;
};
```

---

## 15. Template

| Concept | Example |
|--------|---------|
| Function template | `template<typename T> T add(T a, T b) { return a + b; }` |
| Class template | `template<typename T> class Box { T value; };` |

```cpp
template<typename T>
T max(T a, T b) { return a > b ? a : b; }
max(3, 5);   // 5
max(3.0, 5.0);  // 5.0
```

---

## 16. Move & RAII (brief)

| Concept | Example |
|--------|---------|
| std::move | `std::move(x)` — treat as rvalue (allow move) |
| RAII | Acquire in ctor, release in dtor (e.g. file, lock) |

```cpp
std::vector<int> a = {1, 2, 3};
std::vector<int> b = std::move(a);  // a is now empty, b has data
```

---

## Quick reference

| Need | Use |
|------|-----|
| Dynamic array | `std::vector<T>` |
| Sorted key→value | `std::map<K,V>` |
| Fast key→value | `std::unordered_map<K,V>` |
| Unique ownership | `std::unique_ptr<T>` |
| Shared ownership | `std::shared_ptr<T>` |
| Sort | `std::sort(begin, end)` or with lambda |
| Custom comparison | Lambda in sort/count_if/find_if |

---

## See also

- [Practice Questions](practice-questions.md) — problems with solutions  
- [Vector Reference](vector-reference.md) — full vector API  
- [Ranges & Views](ranges-and-views.md), [Lambdas](lambdas.md), [Smart Pointers](smart-pointers.md)
