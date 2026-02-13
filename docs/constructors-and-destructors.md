# Constructors & Destructors

**Constructors** initialize objects when they are created; **destructors** clean up when objects are destroyed. Together they enforce the lifetime and invariants of your types. This document covers the main forms of constructors, destructors, and the rules the compiler follows when you don’t declare them.

---

## 1. Constructors

### 1.1 Name and syntax

- Name is the **class name** (no return type).
- No return value (not even `void`).
- Can be overloaded (different parameter lists).

```cpp
class Widget {
public:
    Widget();                    // default
    Widget(int id);             // one argument
    Widget(int id, const std::string& name);
};
```

### 1.2 Default constructor

A **default constructor** can be called with no arguments. It initializes the object so it is in a valid state.

```cpp
class Widget {
    int id_;
    std::string name_;
public:
    Widget() : id_(0), name_("") {}
    // or use in-class initializers:
    // int id_ = 0;
    // std::string name_{};
};
Widget w;  // default constructor
```

If you don’t declare any constructor, the compiler may generate a **defaulted** default constructor. It is deleted if a non-defaultable member (e.g. reference, const without initializer) or base prevents it.

### 1.3 Member initializer list

Constructors should prefer a **member initializer list** to assign in the body. List members (and base classes) in the order they are **declared** in the class, not the order in the list.

```cpp
class Example {
    std::string name_;
    int id_;
public:
    Example(const std::string& name, int id)
        : name_(name), id_(id) {}
};
```

- **Must** use the list for: const members, reference members, base classes, and members with no default constructor.
- **Should** use the list for others too; otherwise you default-initialize then assign (extra work, and not possible for const/reference).

### 1.4 Parameterized constructors: how to take arguments

Constructors can take parameters **by value**, **by reference**, **by rvalue reference**, or **by smart pointer**. Choose based on whether you need a copy, want to avoid copying, need to modify the argument, or are taking ownership.

#### 1.4.1 By value

Use for small, cheap-to-copy types (e.g. `int`, `double`, small structs). The parameter is a copy; the caller’s object is unchanged.

```cpp
class Point {
    double x_, y_;
public:
    Point(double x, double y) : x_(x), y_(y) {}
};
Point p(1.0, 2.0);
```

If the type is moveable, the caller can pass a temporary and the copy may be elided or become a move.

#### 1.4.2 By const reference

Use for expensive-to-copy types when you only read the argument (e.g. `std::string`, containers). No copy; the constructor uses the original object without modifying it.

```cpp
class Person {
    std::string name_;
    int age_;
public:
    Person(const std::string& name, int age) : name_(name), age_(age) {}
};
Person p("Alice", 30);  // name is not copied until stored in name_
```

Use **const T&** for parameters you don’t modify. Temporaries can bind to **const T&**.

#### 1.4.3 By non-const reference

Use when the constructor must **modify** the argument (e.g. take ownership of a handle from it) or when you need to store a reference to the argument. The caller must pass an lvalue.

```cpp
class Sink {
    std::vector<int>& ref_;  // reference member: must bind in initializer list
public:
    explicit Sink(std::vector<int>& ref) : ref_(ref) {}
    void add(int x) { ref_.push_back(x); }
};
std::vector<int> v;
Sink s(v);  // s holds a reference to v
s.add(1);   // v now has 1
```

Reference members must be initialized in the member initializer list and cannot be rebound.

#### 1.4.4 By rvalue reference (move)

Use when the constructor **takes ownership** of a resource from the argument and the type is moveable. The source is left in a valid but unspecified state. See [Move semantics](move-semantics.md).

```cpp
class Buffer {
    std::vector<int> data_;
public:
    explicit Buffer(std::vector<int>&& data) : data_(std::move(data)) {}
};
std::vector<int> vec = {1, 2, 3};
Buffer b(std::move(vec));  // vec may be empty; b owns the elements
```

Taking **T&&** and moving into a member is the usual pattern for “sink” parameters that take ownership.

#### 1.4.5 By smart pointer (taking ownership)

Use **std::unique_ptr&lt;T&gt;** when the constructor **takes exclusive ownership** of a heap object. The caller transfers ownership with **std::move**.

```cpp
class WidgetHolder {
    std::unique_ptr<Widget> widget_;
public:
    explicit WidgetHolder(std::unique_ptr<Widget> w) : widget_(std::move(w)) {}
};
WidgetHolder h(std::make_unique<Widget>());
// or: auto w = std::make_unique<Widget>(); WidgetHolder h(std::move(w));
```

Use **std::shared_ptr&lt;T&gt;** when the constructor **shares ownership**. The caller can pass by value (increments ref count) or by const reference (no increment; use if you only need to use the object, not store a copy).

```cpp
class SharedResource {
    std::shared_ptr<Resource> resource_;
public:
    explicit SharedResource(std::shared_ptr<Resource> r) : resource_(std::move(r)) {}
    // or: SharedResource(const std::shared_ptr<Resource>& r) : resource_(r) {}
};
auto res = std::make_shared<Resource>();
SharedResource s1(res);   // ref count 2
SharedResource s2(std::move(res));  // ref count still 2; res is null
```

See [Smart pointers](smart-pointers.md).

#### 1.4.6 By pointer (optional or non-owning)

Use a **raw pointer** when the argument is optional (e.g. “parent” or “config”) or when the class does **not** take ownership. Check for **nullptr** before use.

```cpp
class Node {
    Node* parent_ = nullptr;
    std::string name_;
public:
    explicit Node(const std::string& name, Node* parent = nullptr)
        : parent_(parent), name_(name) {}
    Node* parent() const { return parent_; }
};
Node root("root");
Node child("child", &root);  // child does not own root
```

Do not use a raw pointer parameter to transfer ownership; use **std::unique_ptr** instead.

#### 1.4.7 Summary: constructor parameter choices

| Goal | Parameter type | Example |
|------|----------------|---------|
| Copy; cheap type | By value | `Widget(int id)` |
| Read-only; expensive type | const T& | `Person(const std::string& name)` |
| Modify argument or store reference | T& | `Sink(std::vector<int>& ref)` |
| Take ownership (moveable type) | T&& | `Buffer(std::vector<int>&& data)` |
| Take exclusive ownership (heap) | std::unique_ptr&lt;T&gt; | `Holder(std::unique_ptr&lt;Widget&gt; w)` |
| Share ownership | std::shared_ptr&lt;T&gt; | `Shared(std::shared_ptr&lt;Resource&gt; r)` |
| Optional / non-owning | T* | `Node(const std::string& name, Node* parent)` |

### 1.5 Copy constructor

A **copy constructor** creates an object from another object of the same type. Signature: `ClassName(const ClassName& other)` (or non-const in rare cases).

```cpp
class Buffer {
    std::unique_ptr<char[]> data_;
    size_t size_;
public:
    Buffer(const Buffer& other)
        : size_(other.size_) {
        data_ = std::make_unique<char[]>(size_);
        std::copy_n(other.data_.get(), size_, data_.get());
    }
};
```

If you don’t declare one, the compiler may generate one that copies each member. It is deleted if a member is non-copyable (e.g. `std::unique_ptr`).

### 1.6 Move constructor (C++11)

A **move constructor** takes an rvalue reference and “steals” resources from the source so that the source can be left in a valid but unspecified state.

```cpp
class Buffer {
public:
    Buffer(Buffer&& other) noexcept
        : data_(std::move(other.data_))
        , size_(other.size_) {
        other.size_ = 0;
    }
};
```

See [Move semantics](move-semantics.md) for details.

### 1.7 Delegating constructors

A constructor can call another constructor of the same class in the initializer list (**delegation**).

```cpp
class Widget {
    int id_;
    std::string name_;
public:
    Widget() : Widget(0, "") {}
    Widget(int id) : Widget(id, "") {}
    Widget(int id, const std::string& name) : id_(id), name_(name) {}
};
```

### 1.8 explicit constructors

A constructor that can be called with one argument is a **converting constructor**. The compiler may use it for implicit conversions. To forbid that, declare it **explicit**.

```cpp
class Id {
    int value_;
public:
    explicit Id(int v) : value_(v) {}
};
void use(Id id);
use(42);      // Error: no implicit conversion from int to Id
use(Id(42));  // OK: explicit
```

Prefer `explicit` for single-argument constructors unless you intentionally want implicit conversion.

### 1.9 = default and = delete

- **= default**: ask the compiler to generate the usual implementation (default constructor, copy/move, destructor).
- **= delete**: the function is deleted; any use is an error.

```cpp
class NonCopyable {
public:
    NonCopyable() = default;
    NonCopyable(const NonCopyable&) = delete;
    NonCopyable& operator=(const NonCopyable&) = delete;
};
```

---

## 2. Destructors

### 2.1 Name and syntax

- Name is **~** followed by the class name.
- No parameters; no return type. There is only one destructor per class.
- Called automatically when the object’s lifetime ends (scope exit, delete, etc.).

```cpp
class Resource {
    int* ptr_;
public:
    Resource() : ptr_(new int(0)) {}
    ~Resource() { delete ptr_; }
};
```

### 2.2 When destructors run

- **Automatic storage**: when the block ends.
- **Dynamic storage**: when `delete` is applied to a pointer to the object (or when a smart pointer’s last owner is destroyed).
- **Member or base subobject**: when the containing object’s destructor runs (after the derived/member destructor body).

Destructors are called in reverse order of construction: members and bases are destroyed after the destructor body runs, in reverse order of declaration.

### 2.3 Destructor and inheritance

Base destructors are called automatically. For polymorphic base classes, the destructor should be **virtual** if you delete through a base pointer; otherwise only the base destructor runs (undefined behaviour if the real type is derived). See [Inheritance](inheritance.md) and [Polymorphism](polymorphism.md).

```cpp
class Base {
public:
    virtual ~Base() = default;
};
```

### 2.4 = default and noexcept

You can default the destructor. Mark it **noexcept** (or leave it as the compiler does) so that move paths and container operations can assume no throw.

```cpp
~Resource() noexcept = default;
```

---

## 3. Rule of three / five / zero

- **Rule of three**: if you define copy constructor, copy assignment, or destructor (because of manual resource management), you usually need all three.
- **Rule of five**: add move constructor and move assignment when you care about move semantics.
- **Rule of zero**: prefer types that manage resources (e.g. smart pointers, containers) so the compiler-generated special members are correct; then you don’t define copy/move/destructor yourself.

Use = default when the generated behaviour is correct; use = delete to disable copying or moving.

---

## 4. Order of execution

**Construction:** base classes (in declaration order) → members (in declaration order) → constructor body.

**Destruction:** destructor body → members (reverse order) → base classes (reverse order).

---

## 5. Quick reference

| Item | Notes |
|------|--------|
| Ctor params | Value (cheap); const T& (read-only, expensive); T&& (move); unique_ptr (take ownership); shared_ptr (share); T* (optional/non-owning) |
| Default ctor | No args; use initializer list |
| Copy ctor | `ClassName(const ClassName&)` |
| Move ctor | `ClassName(ClassName&&) noexcept` |
| explicit | Prefer for single-argument ctors |
| Delegation | `: OtherCtor(args)` in initializer list |
| Destructor | ~ClassName(); virtual if base used polymorphically |
| = default / = delete | Use for special members when appropriate |

---

## See also

- [Class](class.md) – members and access
- [RAII](raii.md) – acquire in constructor, release in destructor
- [Move semantics](move-semantics.md) – move constructor and move assignment
- [Inheritance](inheritance.md) – base and derived constructors/destructors
