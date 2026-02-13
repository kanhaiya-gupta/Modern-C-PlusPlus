# Class

A **class** is a user-defined type that bundles data (member variables) and operations (member functions). It is the main building block of object-oriented design in C++. This document covers the basics: members, access specifiers, and how classes relate to structs.

---

## 1. Class vs struct

In C++, **class** and **struct** both define a type with members. The only difference is the **default access**:

- **class**: default access is **private**.
- **struct**: default access is **public**.

```cpp
class Point {
    double x, y;   // private by default
public:
    double getX() const { return x; }
    void setX(double v) { x = v; }
};

struct Data {
    int id;        // public by default
    std::string name;
};
```

Use **class** when you want encapsulation (data hidden by default); use **struct** when you have a simple data aggregate. Convention: `struct` for “plain data,” `class` when there are invariants and behaviour.

---

## 2. Members

### 2.1 Member variables (data members)

Variables declared inside the class store the object’s state. Each object of the class has its own copy (unless the member is `static`).

```cpp
class BankAccount {
    std::string owner_;
    double balance_;
public:
    // ...
};
```

Use a naming convention (e.g. trailing `_`) to distinguish members from parameters.

### 2.2 Member functions (methods)

Functions declared inside the class operate on the object. They can access all members (including private).

```cpp
class BankAccount {
    double balance_;
public:
    void deposit(double amount) {
        if (amount > 0) balance_ += amount;
    }
    double getBalance() const { return balance_; }
};
```

- **const member function**: `getBalance() const` — promises not to modify the object; can be called on const objects. Prefer `const` for getters and other non-mutating functions.

### 2.3 this

Inside a member function, **this** is a pointer to the current object. Usually you omit it when referring to members; use it when you need to pass the object or compare addresses.

```cpp
class Widget {
public:
    Widget* getThis() { return this; }
    void copyFrom(const Widget& other) {
        *this = other;  // assign to current object
    }
};
```

---

## 3. Access specifiers

Access controls who can use a member:

- **public**: accessible from anywhere.
- **private**: accessible only from this class (and friends).
- **protected**: accessible from this class and derived classes (see [Inheritance](inheritance.md)).

Specifiers apply until the next specifier or the end of the class. Typical order: public interface first, then protected (if any), then private implementation.

```cpp
class Example {
public:
    void publicApi();

protected:
    void hookForDerived();

private:
    int internal_;
};
```

---

## 4. Declaring and defining members

Members can be **declared** in the class and **defined** outside. For member functions, the definition uses the class name with `::`.

```cpp
class Example {
public:
    void declareOnly();  // declaration
    void definedInline() { /* body here */ }
};

void Example::declareOnly() {
    // definition outside the class
}
```

Inline definitions in the class are implicitly **inline** (allowed in multiple translation units). Large or rarely used functions are often defined in a .cpp file.

---

## 5. Constructors and destructors

Objects are created by **constructors** and destroyed by **destructors**. The compiler generates default ones if you don’t declare them. See [Constructors & destructors](constructors-and-destructors.md) for details.

```cpp
class Resource {
public:
    Resource() { /* acquire */ }
    ~Resource() { /* release */ }
};
```

---

## 6. Static members

A **static** member is shared by all objects of the class. There is one instance per class.

**Static data member:** defined once (usually in a .cpp). Declared in the class with `static`; defined outside without `static` (and with the class name).

```cpp
class Counter {
public:
    static int count;
    Counter() { ++count; }
    ~Counter() { --count; }
};
int Counter::count = 0;
```

**Static member function:** has no `this`; can only access static members. Call with `ClassName::function()` or on an object.

```cpp
class Counter {
public:
    static int getCount() { return count; }
private:
    static int count;
};
int main() {
    std::cout << Counter::getCount() << '\n';
}
```

Inline static data members (C++17) can be defined and initialized in the class:

```cpp
inline static int count = 0;
```

---

## 7. Nested types

A class can define types (classes, enums, type aliases) inside it. They are scoped to the class.

```cpp
class Tree {
public:
    enum class Traversal { Inorder, Preorder, Postorder };
    using NodeId = int;
    void traverse(Traversal order);
};
Tree::Traversal order = Tree::Traversal::Inorder;
```

---

## 8. Forward declaration

If you need to refer to a class before it is defined (e.g. a pointer or reference member), use a **forward declaration**. Define the class before you use it in a way that needs the full definition (e.g. member access, size).

```cpp
class Y;  // forward declaration
class X {
    Y* ptr_;  // OK: pointer only
};
class Y { /* full definition */ };
```

---

## 9. Incomplete type

Before the closing `};` of the class, the type is **incomplete**: you can declare pointers and references to it, but not use `sizeof` or access members. After the full definition, the type is complete.

---

## 10. Quick reference

| Topic | Summary |
|-------|---------|
| class vs struct | class: default private; struct: default public |
| const member function | Does not modify object; required for const objects |
| this | Pointer to current object |
| static member | One per class; no this in static functions |
| Nested type | Defined inside class; use Class::Type |

---

## See also

- [Constructors & destructors](constructors-and-destructors.md) – creating and destroying objects
- [Encapsulation](encapsulation.md) – hiding implementation with public/private
- [Inheritance](inheritance.md) – base and derived classes
- [Operator overloading](operator-overloading.md) – defining operators for your type
