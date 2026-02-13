# const Correctness

**const correctness** means marking what does not change: parameters, member functions, and variables. It documents intent, lets the compiler catch mistakes, and allows passing temporaries and const objects where only non-mutating access is needed. This document covers where and how to use **const**.

---

## 1. const variables

A **const** variable cannot be modified after initialization.

```cpp
const int maxSize = 100;
// maxSize = 200;  // Error
```

Use for named constants and for values that should not change in a scope.

---

## 2. const parameters

**Const reference** parameters (`const T&`) promise the function will not modify the argument. Callers can pass temporaries and const objects.

```cpp
void print(const std::string& s) {
    // s[0] = 'x';  // Error
    std::cout << s;
}
print("hello");        // OK: temporary binds to const &
const std::string c = "hi";
print(c);              // OK
```

**Const pointer** parameters (`const T*` or `T const*`) promise the function will not modify the pointed-to object.

```cpp
void use(const int* p) {
    // *p = 1;  // Error
    int x = *p;  // OK: read only
}
```

Prefer **const** on parameters that are not modified; it’s part of the function’s contract. See [Functions](functions.md) and [Pointers & references](pointers-and-references.md).

---

## 3. const member functions

A **const member function** promises it does not modify the object (no non-mutable members changed). You can call it on const objects and const references.

```cpp
class Widget {
    int value_;
public:
    int get() const { return value_; }   // OK: doesn’t modify
    void set(int v) { value_ = v; }     // modifies *this
};

const Widget w;
w.get();   // OK
// w.set(1);  // Error: set is non-const
```

Mark every member function that doesn’t modify the object as **const**. Getters and predicates should be const.

---

## 4. mutable members

A **mutable** member can be modified even in a const member function. Use for cache, lock state, or other “physical” state that doesn’t affect the logical value.

```cpp
class Cached {
    mutable int cache_ = -1;
    int compute() const;
public:
    int value() const {
        if (cache_ < 0) cache_ = compute();
        return cache_;
    }
};
```

Use **mutable** sparingly; it should not change the object’s observable behaviour.

---

## 5. const and return types

- **Return by const value** (e.g. `const T get()`) is rarely useful for non-class types and can prevent move. Prefer `T get()`.
- **Return by const reference** is useful when returning a view of existing data that must not be modified: `const std::string& name() const;`
- **Return by const pointer** when the caller should not modify the pointed-to object: `const Node* find() const;`

Never return a const reference (or pointer) to a local variable; the object is destroyed when the function returns.

---

## 6. Const and overloading

You can overload on const: one version for const objects, one for non-const (e.g. **operator[]** on containers).

```cpp
class Buffer {
public:
    int& operator[](size_t i) { return data_[i]; }
    const int& operator[](size_t i) const { return data_[i]; }
private:
    std::vector<int> data_;
};
```

Const objects use the const overload; non-const objects use the non-const overload. See [Operator overloading](operator-overloading.md).

---

## 7. Const and iteration

Use **const** in range-for when you don’t modify elements:

```cpp
for (const auto& item : container) { ... }
```

Use **cbegin** / **cend** when you need const iterators so the elements are not modifiable through the iterator.

---

## 8. Quick reference

| Place       | Use const when |
|------------|------------------|
| Parameter  | Function does not modify the argument (`const T&`, `const T*`) |
| Member function | Function does not modify the object (`void f() const`) |
| Variable   | Value does not change after init |
| Return     | Returning a view that must not be modified (`const T&`, `const T*`) |

---

## See also

- [Functions](functions.md) – const parameters and return types
- [Class](class.md) – const member functions
- [Pointers & references](pointers-and-references.md) – const pointer, pointer to const
- [Operator overloading](operator-overloading.md) – const and non-const overloads
