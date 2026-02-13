# Programming in C++

This document ties together **header/cpp separation**, **static**, **const**, and other practices using **classes** and real project layout. All examples use classes and modern C++ style. For each topic in depth see the linked docs.

---

## 1. Separation of header and implementation

### 1.1 Why separate?

- **Headers (.h, .hpp)**: Declarations (types, function signatures, class interface). Included by other files. Keeps the **interface** visible without implementation details.
- **Source (.cpp)**: Definitions (function bodies, static member definitions). Compiled once per .cpp; linked together.

Result: faster rebuilds (change one .cpp → recompile that file only), clear API, and fewer dependencies.

### 1.2 Include guards

Every header must prevent being included more than once in the same translation unit. Use **include guards** (or **#pragma once** on supported compilers).

```cpp
// widget.h
#ifndef WIDGET_H
#define WIDGET_H

class Widget {
public:
    Widget(int id);
    int id() const;
    void setId(int id);

private:
    int id_;
};

#endif // WIDGET_H
```

### 1.3 Declarations in header, definitions in .cpp

**widget.h** (declarations only):

```cpp
#ifndef WIDGET_H
#define WIDGET_H

class Widget {
public:
    Widget(int id);
    int id() const;
    void setId(int id);

private:
    int id_;
};

#endif
```

**widget.cpp** (definitions):

```cpp
#include "widget.h"

Widget::Widget(int id) : id_(id) {}

int Widget::id() const {
    return id_;
}

void Widget::setId(int id) {
    id_ = id;
}
```

The class body stays in the header so that code that uses `Widget` knows its size and interface. Member function **bodies** that are not inline go in the .cpp so only one translation unit compiles them.

### 1.4 Inline and small functions in headers

Very small or performance-critical functions can be defined **in the header** (implicitly inline) so the compiler can inline calls. Keep them short.

```cpp
// widget.h
class Widget {
public:
    int id() const { return id_; }  // inline in header
    void setId(int id) { id_ = id; }
private:
    int id_;
};
```

For larger functions, prefer declaration in header and definition in .cpp.

### 1.5 What goes where (summary)

| In header | In .cpp |
|-----------|--------|
| Class definition (members, declarations) | Member function definitions (unless inline) |
| Function declarations | Function definitions |
| constexpr / inline function definitions | Static data member definitions |
| Template definitions (usually) | Non-inline, non-template code |

See [Class](class.md), [Functions](functions.md).

---

## 2. Using static in a multi-file project

### 2.1 Static data member (one per class)

Declare in the class; **define** exactly once in **one .cpp** (no `static` in the definition).

**counter.h**:

```cpp
#ifndef COUNTER_H
#define COUNTER_H

class Counter {
public:
    Counter();
    ~Counter();
    static int count();
private:
    static int count_;  // declaration only
};

#endif
```

**counter.cpp**:

```cpp
#include "counter.h"

int Counter::count_ = 0;  // definition (no 'static' here)

Counter::Counter() {
    ++count_;
}

Counter::~Counter() {
    --count_;
}

int Counter::count() {
    return count_;
}
```

See [Static](static.md), [Class](class.md).

### 2.2 Static member function (no this)

Static member functions only use static members. Declare in header, define in .cpp like any other member.

```cpp
// counter.h
class Counter {
public:
    static int count();
private:
    static int count_;
};

// counter.cpp
int Counter::count_ = 0;
int Counter::count() { return count_; }
```

### 2.3 File-local helpers (internal linkage)

In a .cpp, use **anonymous namespace** (or file-scope **static**) so helper names don’t leak to the linker. Classes and functions can be in the anonymous namespace too.

**widget.cpp**:

```cpp
#include "widget.h"
#include <string>

namespace {
    static const int kDefaultId = 0;

    std::string formatLabel(const Widget& w) {
        return "Widget#" + std::to_string(w.id());
    }
}

Widget::Widget(int id) : id_(id) {}
// ...
```

See [Static](static.md), [Namespaces](namespaces.md).

### 2.4 Static local (one instance per function)

Use a **static local** when a function needs one shared object (e.g. a cache or counter) that lives for the whole program.

```cpp
// cache.h
class ResultCache {
public:
    static const std::string& getDefaultKey();
};

// cache.cpp
const std::string& ResultCache::getDefaultKey() {
    static const std::string key = "default";  // one instance, initialized once
    return key;
}
```

---

## 3. Using const in class-based code

### 3.1 Const member functions (don’t modify *this)

Mark every member function that does not modify the object as **const**. Then you can call it on const objects and const references.

**widget.h**:

```cpp
class Widget {
public:
    Widget(int id);
    int id() const;           // getter: does not modify
    void setId(int id);      // setter: modifies
    double value() const;    // read-only
private:
    int id_;
    double value_ = 0.0;
};
```

**widget.cpp**:

```cpp
int Widget::id() const {
    return id_;
}

void Widget::setId(int id) {
    id_ = id;
}

double Widget::value() const {
    return value_;
}
```

Usage:

```cpp
const Widget w(1);
w.id();      // OK: id() const
w.value();   // OK
// w.setId(2);  // Error: setId is non-const
```

See [Const correctness](const-correctness.md), [Class](class.md).

### 3.2 Const parameters (don’t modify the argument)

Use **const** for parameters that are not modified. Prefer **const T&** for expensive types.

```cpp
// logger.h
class Logger {
public:
    void log(const std::string& message) const;  // doesn't change *this or message
    void append(const std::vector<int>& data);
};
```

```cpp
// logger.cpp
void Logger::log(const std::string& message) const {
    // message is read-only; *this is read-only
}

void Logger::append(const std::vector<int>& data) {
    // data is read-only; we might change *this
}
```

### 3.3 Const and overloading (e.g. operator[])

Provide both const and non-const overloads when you expose element access: const overload returns const reference for read-only use.

```cpp
// buffer.h
class Buffer {
public:
    const int& operator[](std::size_t i) const { return data_[i]; }
    int& operator[](std::size_t i) { return data_[i]; }
private:
    std::vector<int> data_;
};
```

See [Operator overloading](operator-overloading.md).

### 3.4 Const data members and initializer list

Const and reference members must be initialized in the **member initializer list**; they cannot be assigned in the body.

```cpp
// config.h
class Config {
public:
    Config(int id, const std::string& name);
    int id() const { return id_; }
    const std::string& name() const { return name_; }
private:
    const int id_;
    const std::string name_;
};

// config.cpp
Config::Config(int id, const std::string& name)
    : id_(id), name_(name) {}
```

See [Constructors & destructors](constructors-and-destructors.md).

---

## 4. Complete example: a small class in header + cpp

**account.h**:

```cpp
#ifndef ACCOUNT_H
#define ACCOUNT_H

#include <string>

class Account {
public:
    explicit Account(const std::string& owner);
    const std::string& owner() const;
    double balance() const;
    void deposit(double amount);
    void withdraw(double amount);

private:
    std::string owner_;
    double balance_ = 0.0;
};

#endif
```

**account.cpp**:

```cpp
#include "account.h"

Account::Account(const std::string& owner) : owner_(owner) {}

const std::string& Account::owner() const {
    return owner_;
}

double Account::balance() const {
    return balance_;
}

void Account::deposit(double amount) {
    if (amount > 0)
        balance_ += amount;
}

void Account::withdraw(double amount) {
    if (amount > 0 && amount <= balance_)
        balance_ -= amount;
}
```

**main.cpp** (or another .cpp):

```cpp
#include "account.h"
#include <iostream>

int main() {
    Account acc("Alice");
    acc.deposit(100.0);
    acc.withdraw(30.0);
    std::cout << acc.owner() << ": " << acc.balance() << '\n';
    return 0;
}
```

---

## 5. Example: class with static member and const

**reporter.h**:

```cpp
#ifndef REPORTER_H
#define REPORTER_H

#include <string>

class Reporter {
public:
    explicit Reporter(const std::string& name);
    const std::string& name() const;
    void report(const std::string& message) const;
    static int instanceCount();

private:
    std::string name_;
    static int count_;
};

#endif
```

**reporter.cpp**:

```cpp
#include "reporter.h"

int Reporter::count_ = 0;  // definition

Reporter::Reporter(const std::string& name) : name_(name) {
    ++count_;
}

Reporter::~Reporter() {
    --count_;
}

const std::string& Reporter::name() const {
    return name_;
}

void Reporter::report(const std::string& message) const {
    // use name_ and message (read-only)
}

int Reporter::instanceCount() {
    return count_;
}
```

---

## 6. Example: RAII class (resource in header/cpp)

**file_handle.h**:

```cpp
#ifndef FILE_HANDLE_H
#define FILE_HANDLE_H

#include <string>

class FileHandle {
public:
    explicit FileHandle(const std::string& path);
    ~FileHandle();
    FileHandle(const FileHandle&) = delete;
    FileHandle& operator=(const FileHandle&) = delete;
    bool isOpen() const;
    std::size_t read(void* buf, std::size_t size);

private:
    void* file_ = nullptr;  // e.g. FILE* or handle
};

#endif
```

**file_handle.cpp**:

```cpp
#include "file_handle.h"
#include <cstdio>
#include <stdexcept>

namespace {
    const char* defaultMode = "rb";
}

FileHandle::FileHandle(const std::string& path) {
    file_ = std::fopen(path.c_str(), defaultMode);
    if (!file_)
        throw std::runtime_error("cannot open: " + path);
}

FileHandle::~FileHandle() {
    if (file_) {
        std::fclose(static_cast<std::FILE*>(file_));
        file_ = nullptr;
    }
}

bool FileHandle::isOpen() const {
    return file_ != nullptr;
}

std::size_t FileHandle::read(void* buf, std::size_t size) {
    if (!file_) return 0;
    return std::fread(buf, 1, size, static_cast<std::FILE*>(file_));
}
```

See [RAII](raii.md), [Exception handling](exception-handling.md).

---

## 7. Including other headers

- **In the header**: Include only what the **header** needs for its declarations (e.g. **std::string** for a member). Prefer forward declarations when you only need a pointer or reference (e.g. `class X;`) to reduce compile time.
- **In the .cpp**: Include the matching header first, then other headers (standard, then third-party, then your own). The .cpp needs full definitions for what it uses.

```cpp
// widget.h
#include <string>   // needed for member std::string name_
class Other;        // forward declaration if we only have Other* or Other&

class Widget {
    std::string name_;
    Other* other_ = nullptr;
};
```

```cpp
// widget.cpp
#include "widget.h"
#include "other.h"  // full definition for use of Other
```

---

## 8. Lambdas with classes

Use **lambdas** for callbacks, predicates, and custom behaviour stored or passed by classes. Lambdas capture `this` or members as needed; keep lifetime in mind (see [Lambdas](lambdas.md)).

### 8.1 Callbacks and std::function in a class

Store a callable (e.g. callback) with **std::function**; set it with a lambda.

```cpp
// notifier.h
#include <functional>
#include <string>

class Notifier {
public:
    using Callback = std::function<void(const std::string&)>;
    void setCallback(Callback cb) { callback_ = std::move(cb); }
    void notify(const std::string& message) const {
        if (callback_) callback_(message);
    }
private:
    Callback callback_;
};

// usage
Notifier n;
n.setCallback([](const std::string& msg) {
    std::cout << "Got: " << msg << '\n';
});
n.notify("hello");
```

### 8.2 Algorithms with lambdas (class data)

Use lambdas with **std::sort**, **std::find_if**, **std::for_each** on member containers or in member functions.

```cpp
// task_list.h
#include <vector>
#include <string>

struct Task {
    int id;
    std::string name;
    int priority;
};

class TaskList {
public:
    void add(Task t);
    void sortByPriority();
    std::vector<Task> highPriority(int minPrio) const;
private:
    std::vector<Task> tasks_;
};

// task_list.cpp
void TaskList::sortByPriority() {
    std::ranges::sort(tasks_, [](const Task& a, const Task& b) {
        return a.priority > b.priority;
    });
}

std::vector<Task> TaskList::highPriority(int minPrio) const {
    std::vector<Task> out;
    std::ranges::copy_if(tasks_,
        std::back_inserter(out),
        [minPrio](const Task& t) { return t.priority >= minPrio; });
    return out;
}
```

### 8.3 Capturing this in a class member

When a lambda is created inside a member function and uses members, capture **this** (or **\[=\]** / **\[&\]**; prefer explicit **\[this\]** or **\[*this\]** for clarity and safety).

```cpp
class Worker {
    int threshold_ = 10;
public:
    void run() {
        auto check = [this](int x) { return x > threshold_; };
        if (check(15)) { /* ... */ }
    }
};
```

See [Lambdas](lambdas.md), [Functions](functions.md).

---

## 9. Ranges, views, and lazy evaluation

Use **ranges** and **views** (C++20) on container members; pipelines are **lazy** until you iterate. See [Ranges & Views](ranges-and-views.md), [Lazy evaluation](lazy-evaluation.md).

### 9.1 Range algorithms on class data

Prefer **std::ranges** algorithms so you pass the whole range (e.g. a member vector) instead of begin/end.

```cpp
// analytics.h
#include <vector>
#include <algorithm>
#include <ranges>

class Analytics {
public:
    explicit Analytics(std::vector<double> data) : data_(std::move(data)) {}
    double sum() const {
        double s = 0;
        for (double x : data_) s += x;
        return s;
    }
    std::vector<double> above(double threshold) const {
        auto v = data_ | std::views::filter([threshold](double x) { return x > threshold; });
        return std::vector<double>(v.begin(), v.end());
    }
private:
    std::vector<double> data_;
};
```

### 9.2 Lazy view pipelines (no extra storage)

Build a pipeline with **views::filter**, **views::transform**, **views::take**; iteration happens when you loop or materialize. No intermediate container for the full filtered/transformed sequence.

```cpp
#include <ranges>
#include <vector>
#include <iostream>

class DataSource {
public:
    const std::vector<int>& values() const { return values_; }
    void add(int x) { values_.push_back(x); }
private:
    std::vector<int> values_;
};

// usage: lazy pipeline over DataSource's data
DataSource ds;
for (int x : {5, 10, 15, 20, 25}) ds.add(x);

auto evens_times_2 = ds.values()
    | std::views::filter([](int n) { return n % 2 == 0; })
    | std::views::transform([](int n) { return n * 2; });

for (int x : evens_times_2)  // 20, 40
    std::cout << x << ' ';
```

### 9.3 Composing views with take (lazy prefix)

Use **views::take** so only the first N elements are computed; the rest of the range is never traversed.

```cpp
auto firstThreeSquared = ds.values()
    | std::views::transform([](int n) { return n * n; })
    | std::views::take(3);
// Only 3 elements are computed when you iterate
```

See [Ranges & Views](ranges-and-views.md), [Lazy evaluation](lazy-evaluation.md), [Iterators](iterators.md).

---

## 10. Threading with classes

Use **std::thread**, **std::mutex**, and **std::lock_guard** (or **std::scoped_lock**) to protect shared state inside a class. See [Threading](threading.md), [RAII](raii.md).

### 10.1 Class with a mutex (thread-safe wrapper)

Protect member data with a **std::mutex**; lock in every public method that reads or writes it. Use **std::lock_guard** so the lock is released on return or exception.

```cpp
// thread_safe_queue.h
#include <queue>
#include <mutex>
#include <optional>

template<typename T>
class ThreadSafeQueue {
public:
    void push(T value) {
        std::lock_guard<std::mutex> lock(mtx_);
        queue_.push(std::move(value));
    }
    std::optional<T> pop() {
        std::lock_guard<std::mutex> lock(mtx_);
        if (queue_.empty()) return std::nullopt;
        T v = std::move(queue_.front());
        queue_.pop();
        return v;
    }
    bool empty() const {
        std::lock_guard<std::mutex> lock(mtx_);
        return queue_.empty();
    }
private:
    mutable std::mutex mtx_;
    std::queue<T> queue_;
};
```

### 10.2 Running work in a thread (lambda capturing this)

Start a **std::thread** with a lambda that runs a member function or uses member data; capture **this** only if the object outlives the thread, or use a copy/smart pointer.

```cpp
class Worker {
public:
    void start() {
        thread_ = std::thread([this]() { run(); });
    }
    void join() { if (thread_.joinable()) thread_.join(); }
    ~Worker() { join(); }
private:
    void run() { /* use member data; protect with mutex if shared */ }
    std::thread thread_;
};
```

See [Threading](threading.md), [RAII](raii.md).

---

## 11. Templates with classes

Use **class templates** for generic types and **template member functions** when behaviour depends on a type. Template definitions usually stay in headers. See [Templates](templates.md).

### 11.1 Class template (generic container-like type)

```cpp
// buffer.h
#ifndef BUFFER_H
#define BUFFER_H

#include <vector>
#include <stdexcept>

template<typename T>
class Buffer {
public:
    explicit Buffer(std::size_t capacity) : data_(capacity) {}
    T& at(std::size_t i) {
        if (i >= data_.size()) throw std::out_of_range("Buffer::at");
        return data_[i];
    }
    const T& at(std::size_t i) const {
        if (i >= data_.size()) throw std::out_of_range("Buffer::at");
        return data_[i];
    }
    std::size_t size() const { return data_.size(); }
private:
    std::vector<T> data_;
};

#endif
```

Usage: **Buffer&lt;int&gt;**, **Buffer&lt;std::string&gt;**; each instantiation is a separate type.

### 11.2 Template member function (e.g. assign from any range)

A non-template class can have a **template member function** to accept any type that supports the operations you use.

```cpp
// builder.h
#include <vector>
#include <ranges>

class Builder {
public:
    template<std::ranges::range R>
    void addAll(R&& r) {
        for (auto&& x : r)
            data_.push_back(static_cast<int>(x));
    }
    const std::vector<int>& data() const { return data_; }
private:
    std::vector<int> data_;
};

// usage
Builder b;
b.addAll(std::vector{1, 2, 3});
b.addAll(std::views::iota(0, 5));
```

### 11.3 Concepts (C++20) to constrain template parameters

Use **concepts** to document and enforce requirements on template type parameters. See [Concepts](concepts.md).

```cpp
#include <concepts>

template<std::totally_ordered T>
class SortedBag {
public:
    void add(const T& value);
    const T& min() const;
private:
    std::vector<T> data_;
};
```

See [Templates](templates.md), [Concepts](concepts.md).

---

## 12. Inheritance and polymorphism

Use **inheritance** for an “is-a” relationship and **virtual** functions for runtime polymorphism. Base class destructor should be **virtual** if you delete through a base pointer. See [Inheritance](inheritance.md), [Polymorphism](polymorphism.md).

### 12.1 Base and derived classes (header layout)

Declare the base class first; derived class inherits with **: public Base**. Virtual functions in the base are overridden in the derived with **override**.

```cpp
// shape.h
#ifndef SHAPE_H
#define SHAPE_H

class Shape {
public:
    virtual ~Shape() = default;
    virtual double area() const = 0;   // pure virtual: interface
};

#endif

// circle.h
#ifndef CIRCLE_H
#define CIRCLE_H

#include "shape.h"

class Circle : public Shape {
public:
    explicit Circle(double radius) : radius_(radius) {}
    double area() const override { return 3.14159 * radius_ * radius_; }
private:
    double radius_;
};

#endif
```

### 12.2 Using polymorphism (base pointer / reference)

Code that works with **Shape*** or **Shape&** can work with any derived type; the correct **area()** is called at runtime.

```cpp
#include "shape.h"
#include "circle.h"
#include <memory>
#include <vector>

std::vector<std::unique_ptr<Shape>> shapes;
shapes.push_back(std::make_unique<Circle>(2.0));

for (const auto& s : shapes)
    std::cout << "Area: " << s->area() << '\n';  // virtual dispatch
```

### 12.3 Slicing: avoid passing polymorphic objects by value

Pass by **pointer** or **reference** (or **std::unique_ptr&lt;Base&gt;**). Passing by value slices: only the base part is copied.

```cpp
void process(Shape& s) { /* OK: no slice */ }
void process(Shape s) { /* BAD: slices; s is only Shape part */ }
```

See [Inheritance](inheritance.md), [Polymorphism](polymorphism.md), [Compile-time & runtime polymorphism](compile-time-and-runtime-polymorphism.md).

---

## 13. Smart pointers and move semantics in classes

Use **smart pointers** for owned heap objects and **move semantics** to transfer ownership or avoid copies. See [Smart pointers](smart-pointers.md), [Move semantics](move-semantics.md).

### 13.1 Class holding a unique_ptr (exclusive ownership)

```cpp
// widget_owner.h
#include <memory>

class Widget;

class WidgetOwner {
public:
    explicit WidgetOwner(std::unique_ptr<Widget> w);
    const Widget* get() const { return widget_.get(); }
    Widget* get() { return widget_.get(); }
private:
    std::unique_ptr<Widget> widget_;
};

// implementation
WidgetOwner::WidgetOwner(std::unique_ptr<Widget> w) : widget_(std::move(w)) {}
```

### 13.2 Move constructor and move assignment (rule of five)

When the class manages a resource (or has members that are expensive to copy), define **move constructor** and **move assignment** (and consider deleting or defining copy). Mark them **noexcept** when possible.

```cpp
// buffer.h
#include <vector>

class Buffer {
public:
    Buffer() = default;
    Buffer(Buffer&& other) noexcept
        : data_(std::move(other.data_)) {}
    Buffer& operator=(Buffer&& other) noexcept {
        if (this != &other)
            data_ = std::move(other.data_);
        return *this;
    }
    // copy: delete or define as needed
    Buffer(const Buffer&) = delete;
    Buffer& operator=(const Buffer&) = delete;
private:
    std::vector<int> data_;
};
```

### 13.3 Returning a unique_ptr from a factory (class)

Factory functions can return **std::unique_ptr&lt;Base&gt;** so the caller owns the object. No slicing; ownership is clear.

```cpp
std::unique_ptr<Shape> makeCircle(double r) {
    return std::make_unique<Circle>(r);
}
```

See [Smart pointers](smart-pointers.md), [Move semantics](move-semantics.md), [RAII](raii.md).

---

## 14. Exceptions in class code

Constructors can throw to signal failure; use **RAII** so that if a constructor throws after acquiring a resource, destructors of already-constructed members run. See [Exception handling](exception-handling.md), [RAII](raii.md).

### 14.1 Throwing from a constructor

If construction cannot succeed, throw; the object is not created and its destructor does not run. Member and base destructors for fully constructed subobjects do run.

```cpp
Config::Config(const std::string& path) {
    if (path.empty())
        throw std::invalid_argument("path must be non-empty");
    // ...
}
```

### 14.2 Destructors must not throw

If a destructor throws (e.g. during stack unwinding), **std::terminate** is often called. Design destructors to not throw; catch and log inside the destructor if you must call something that might throw.

See [Exception handling](exception-handling.md), [Constructors & destructors](constructors-and-destructors.md).

---

## 15. Quick reference

| Topic | Practice |
|-------|----------|
| Headers / .cpp | Include guards; declarations in header, definitions in .cpp; static data member defined in one .cpp |
| static | Static members: declare in class, define in one .cpp; file-local: anonymous namespace; static local for one instance per function |
| const | const member functions; const parameters; const overloads for accessors |
| Lambdas | Callbacks (std::function), algorithms (sort, filter, copy_if), capture this or *this with care |
| Ranges / views | std::ranges algorithms; views (filter, transform, take) for lazy pipelines over container members |
| Threading | std::mutex + std::lock_guard in class; std::thread with lambda; ensure object outlives thread or copy |
| Templates | Class templates and template member functions in headers; use concepts to constrain (C++20) |
| Inheritance | public base; virtual destructor; override; pass by reference/pointer to avoid slicing |
| Polymorphism | Virtual functions; base pointer/reference or unique_ptr&lt;Base&gt;; dynamic_cast when needed |
| Smart pointers / move | unique_ptr for ownership; move ctor/assign for transfer; return unique_ptr from factories |
| Exceptions | Throw from ctor on failure; never throw from destructor; rely on RAII for cleanup |

---

## See also

- [Class](class.md) – members, access, static members
- [Static](static.md) – all uses of static
- [Const correctness](const-correctness.md) – const in parameters and members
- [Lambdas](lambdas.md) – capture, std::function
- [Ranges & Views](ranges-and-views.md) – range algorithms and views
- [Lazy evaluation](lazy-evaluation.md) – lazy pipelines
- [Threading](threading.md) – threads, mutexes, lock_guard
- [Templates](templates.md) – class and function templates
- [Concepts](concepts.md) – constraining templates
- [Inheritance](inheritance.md) – base and derived classes
- [Polymorphism](polymorphism.md) – virtual functions
- [Smart pointers](smart-pointers.md) – unique_ptr, shared_ptr
- [Move semantics](move-semantics.md) – move constructor and assignment
- [RAII](raii.md) – resource management in classes
- [Exception handling](exception-handling.md) – throwing and handling
- [Constructors & destructors](constructors-and-destructors.md) – initializer list, rule of five
- [Namespaces](namespaces.md) – anonymous namespace for file scope
