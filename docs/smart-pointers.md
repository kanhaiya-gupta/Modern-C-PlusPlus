# Smart Pointers

Smart pointers are RAII wrappers around raw pointers. They express **ownership** and automatically manage lifetime, so you rarely need `new`/`delete` or raw owning pointers. The standard provides `std::unique_ptr`, `std::shared_ptr`, and `std::weak_ptr`.

---

## 1. Why smart pointers?

Raw pointers do not indicate who owns the object or when to delete it. That leads to leaks, double-deletes, and use-after-free.

```cpp
// Who deletes? When? Easy to forget or delete twice.
Foo* p = new Foo();
bar(p);
delete p;  // what if bar() stored p and deletes it later?
```

Smart pointers make ownership explicit and tie resource lifetime to scope (or to shared reference count), so destruction is automatic and predictable. See [RAII](raii.md) for the pattern.

---

## 2. std::unique_ptr — exclusive ownership

### 2.1 Concept

- **One** owner at a time. The unique_ptr that owns the object is responsible for deleting it.
- **Move-only**: copying is disabled; ownership is transferred by moving.
- Zero overhead when you use it by value (no reference counting).

### 2.2 Basic usage

```cpp
#include <memory>

// Prefer make_unique (C++14)
std::unique_ptr<int> p = std::make_unique<int>(42);
std::unique_ptr<std::string> s = std::make_unique<std::string>("hello");

// Or from raw pointer (when you must; e.g. from a C API)
std::unique_ptr<int> q( new int(10) );
```

### 2.3 Ownership transfer (move)

```cpp
std::unique_ptr<int> a = std::make_unique<int>(1);
// std::unique_ptr<int> b = a;   // Error: copy deleted
std::unique_ptr<int> b = std::move(a);  // a is now null, b owns the int

// After move, use the new owner
std::cout << *b << '\n';   // 1
// *a;  // undefined: a is empty
```

### 2.4 Accessing the object

- `*p` / `p->member` — dereference (undefined if `p` is empty).
- `p.get()` — raw pointer (non-owning; do not delete). Use for legacy APIs.
- `p.reset()` — replace managed object (old one is destroyed) or release and set to null.
- `p.release()` — return raw pointer and give up ownership; caller must delete or take over.

```cpp
std::unique_ptr<int> p = std::make_unique<int>(99);
int* raw = p.get();   // use raw for a C function that doesn't take ownership
some_c_api(raw);

if (p) {
    *p = 100;
}

p.reset();            // deletes 100, p is now null
p.reset(new int(5));  // p now owns 5

int* orphan = p.release();  // p is null; you must delete orphan (or assign to another unique_ptr)
```

### 2.5 Arrays

`std::unique_ptr<T[]>` uses `delete[]`. Prefer `std::array` or `std::vector` when you can; use this when you need a dynamic array owned by a unique_ptr.

```cpp
std::unique_ptr<int[]> arr(new int[10]);
arr[0] = 1;
// make_unique<T[]>(n) in C++14
auto buf = std::make_unique<int[]>(100);
```

### 2.6 Custom deleter

When the resource is not allocated with plain `new` (e.g. C API, file handle), use a custom deleter.

```cpp
// Functor
struct FileCloser {
    void operator()(FILE* fp) const { if (fp) fclose(fp); }
};
std::unique_ptr<FILE, FileCloser> file(fopen("data.txt", "r"));

// Lambda
auto del = [](int* p) { free(p); };
std::unique_ptr<int, decltype(del)> p((int*)malloc(sizeof(int)), del);
```

---

## 3. std::shared_ptr — shared ownership

### 3.1 Concept

- **Multiple** shared_ptrs can refer to the same object. The object is destroyed when the last shared_ptr is destroyed or reset.
- Uses **reference counting** (and typically a control block). Some overhead in size and time.
- Copyable and movable; copying increments the count, moving transfers ownership of the handle.

### 3.2 Basic usage

```cpp
#include <memory>

std::shared_ptr<int> p = std::make_shared<int>(42);
std::shared_ptr<int> q = p;   // same object, count is 2

std::cout << *p << '\n';  // 42
p.reset();                 // count is 1 (q still owns)
q.reset();                 // count 0 → object destroyed
```

### 3.3 Prefer make_shared

`std::make_shared<T>(...)` allocates the object and the control block together (one allocation, better locality, one ref count to manage).

```cpp
auto p = std::make_shared<Widget>(1, "hello");
```

Use `std::shared_ptr<T>(new T(...))` only when you need a custom deleter or when `make_shared` is not suitable (e.g. custom new). Avoid:

```cpp
// Bad: two allocations, and if second (control block) fails, the first leaks
std::shared_ptr<Widget> p(new Widget());
```

### 3.4 use_count and unique

- `p.use_count()` — number of shared_ptrs sharing ownership (approximate; for debugging).
- `p.unique()` — true when `use_count() == 1`.

Avoid designing logic around `use_count()`; it’s mainly for diagnostics.

### 3.5 Custom deleter

Same idea as unique_ptr: when the resource isn’t created with `new T`, provide a deleter.

```cpp
std::shared_ptr<FILE> file(fopen("log.txt", "w"), fclose);
```

The deleter type is part of the shared_ptr type when you pass it as a template argument; otherwise it’s erased (type-erased deleter).

---

## 4. std::weak_ptr — non-owning reference to shared state

### 4.1 Concept

- **weak_ptr** refers to an object managed by **shared_ptr** but does **not** own it. It does not keep the object alive.
- Used to break **reference cycles** (e.g. A holds shared_ptr to B, B holds shared_ptr to A → never destroyed) and for caches/observers.

### 4.2 Creating and using

You construct weak_ptr from a shared_ptr. To use the object, you **lock** to get a shared_ptr; if the object is still alive, you get a valid shared_ptr and can use it.

```cpp
std::shared_ptr<int> s = std::make_shared<int>(42);
std::weak_ptr<int> w = s;

// Later, maybe s has been reset elsewhere
if (std::shared_ptr<int> locked = w.lock()) {
    std::cout << *locked << '\n';  // safe to use
} else {
    // object already destroyed
}
```

- `w.expired()` — true if the object has been destroyed (equivalent to `use_count() == 0`).
- `w.lock()` — returns a shared_ptr; empty if expired.

### 4.3 Breaking cycles

```cpp
struct Node {
    std::shared_ptr<Node> next;
    std::weak_ptr<Node> prev;  // break cycle: don’t keep parent alive
};
```

Without `weak_ptr`, a list that forms a cycle would never be destroyed.

---

## 5. When to use which

| Need | Use |
|------|-----|
| Single owner, clear lifetime | `std::unique_ptr` |
| Shared ownership, multiple owners | `std::shared_ptr` |
| Reference to shared-owned object without keeping it alive (cache, back-ref, observer) | `std::weak_ptr` |
| Non-owning “see” an object (parameter, observer) | Raw pointer or reference |

Default to **unique_ptr**. Use **shared_ptr** only when ownership is truly shared. Use **weak_ptr** when you need to refer to shared-owned data without affecting lifetime (e.g. cycles, caches).

---

## 6. Guidelines

### 6.1 Don’t use raw owning pointers

Prefer `make_unique` / `make_shared` (or unique_ptr/shared_ptr with a deleter) instead of `new`/`delete` and raw owning pointers.

### 6.2 Don’t mix raw and smart for ownership

If a function takes a raw pointer, clarify in the API whether it **takes ownership**. If it does not, pass `p.get()` from a unique_ptr or shared_ptr; do not pass a raw pointer you later delete yourself.

### 6.3 Avoid get() for ownership or long-term storage

`p.get()` gives a non-owning raw pointer. Storing it and using it after the smart pointer has destroyed the object is use-after-free. Store a shared_ptr or weak_ptr if you need to keep a reference.

### 6.4 Prefer unique_ptr as “sink” parameter

To transfer ownership into a function, take `std::unique_ptr<T>` by value (or by rvalue reference). The caller uses `std::move(p)`.

```cpp
void takeOwner(std::unique_ptr<Widget> p) {
    // now this function owns p
}
takeOwner(std::move(myWidget));
```

### 6.5 shared_ptr is not free

Reference counting has cost. Avoid shared_ptr when a single owner (unique_ptr) or a clear owner (e.g. one object that owns and deletes) is enough.

---

## 7. Common pitfalls

### 7.1 Reference cycles with shared_ptr only

If A and B hold shared_ptrs to each other, the ref count never reaches zero. Use **weak_ptr** for one of the links (e.g. back pointer or “parent”).

### 7.2 Multiple control blocks for the same object

Constructing `shared_ptr` from a raw pointer multiple times creates separate control blocks and leads to double delete:

```cpp
Widget* raw = new Widget();
std::shared_ptr<Widget> p1(raw);
std::shared_ptr<Widget> p2(raw);  // undefined behaviour: two control blocks
```

Always create the first shared_ptr from `make_shared` or from a single `new` and then copy that shared_ptr.

### 7.3 Returning unique_ptr

Returning a unique_ptr from a function is fine (move semantics). The compiler can elide the move.

```cpp
std::unique_ptr<Widget> makeWidget() {
    return std::make_unique<Widget>();
}
auto p = makeWidget();  // OK
```

### 7.4 this and shared_ptr

Do not create a **new** `shared_ptr` from `this` if the object might already be managed by shared_ptr elsewhere (e.g. if it was created by a factory that returns shared_ptr). That would create a second control block. Use **enable_shared_from_this** when a class needs to hand out a shared_ptr to itself:

```cpp
class Me : public std::enable_shared_from_this<Me> {
public:
    std::shared_ptr<Me> getPtr() { return shared_from_this(); }
};
// Only call getPtr() when the object is already owned by a shared_ptr.
```

---

## 8. Summary

| Type | Ownership | Copy | Overhead |
|------|-----------|------|----------|
| `unique_ptr` | Exclusive | No (move only) | None |
| `shared_ptr` | Shared | Yes | Ref count + control block |
| `weak_ptr` | None | Yes (from shared_ptr) | Control block only |

Use **unique_ptr** by default, **shared_ptr** when ownership is shared, and **weak_ptr** to refer to shared-owned objects without keeping them alive. Prefer **make_unique** and **make_shared**; use custom deleters when the resource isn’t created with plain `new`.

---

## See also

- [RAII](raii.md) – resource ownership and scope-based cleanup
- [Pointers & References](pointers-and-references.md) – raw pointers and when to avoid them
- [Move semantics](move-semantics.md) – how unique_ptr is move-only
