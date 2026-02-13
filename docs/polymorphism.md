# Polymorphism

**Polymorphism** means “many forms”: the same interface can behave differently depending on the actual type of the object. In C++ you get **runtime polymorphism** (via virtual functions and inheritance) and **compile-time polymorphism** (via templates and overloading). This document focuses on runtime polymorphism; see [Compile-time & runtime polymorphism](compile-time-and-runtime-polymorphism.md) for both.

---

## 1. Runtime polymorphism (virtual functions)

With **virtual** functions, the call is bound at **runtime** based on the **dynamic type** of the object (the type it was created as), not the **static type** (the type of the variable or pointer).

```cpp
class Shape {
public:
    virtual double area() const = 0;  // pure virtual: no implementation in base
    virtual ~Shape() = default;
};

class Circle : public Shape {
    double r_;
public:
    Circle(double r) : r_(r) {}
    double area() const override { return 3.14159 * r_ * r_; }
};

class Square : public Shape {
    double s_;
public:
    Square(double s) : s_(s) {}
    double area() const override { return s_ * s_; }
};

Shape* p = new Circle(1.0);
p->area();  // calls Circle::area() because *p is really a Circle
delete p;   // virtual destructor → calls Circle::~Circle() then Shape::~Shape()
```

The **base** defines the interface (here, `area()`); **derived** classes provide the implementation. Code that works with `Shape*` or `Shape&` works with any concrete shape without knowing the exact type.

---

## 2. Pure virtual and abstract classes

A **pure virtual** function has `= 0` and no body in the base. A class with at least one pure virtual function is **abstract**: you cannot create objects of that type, only of derived types that implement all pure virtuals.

```cpp
class Abstract {
public:
    virtual void mustImplement() = 0;
    virtual ~Abstract() = default;
};
// Abstract a;  // Error: abstract class
```

Abstract classes are used to define **interfaces** (contracts) that concrete classes must fulfil.

---

## 3. override and final

- **override**: put on a derived function that is meant to override a base virtual. The compiler checks that a matching base virtual exists; catches typos and wrong signatures.

```cpp
class Derived : public Base {
    void f() override;  // must match Base::f()
};
```

- **final**: put on a virtual to prevent further overrides, or on a class to prevent further derivation.

```cpp
class Base {
    virtual void f() final;
};
class Last final : public Base {};  // no class can derive from Last
```

---

## 4. Virtual destructor

If you ever delete an object through a **base pointer**, the base class must have a **virtual** destructor. Otherwise only the base part is destroyed (undefined behaviour).

```cpp
class Base {
public:
    virtual ~Base() = default;
};
```

See [Inheritance](inheritance.md) and [Constructors & destructors](constructors-and-destructors.md).

---

## 5. How it works (brief)

The compiler typically uses a **vtable** (virtual table) per class and a **vptr** (pointer to that table) in each object. A call through a base pointer goes through the vptr to the right table and then to the right function. You don’t manage this yourself; just declare virtual functions and destructors where needed.

---

## 6. Slicing reminder

Polymorphism works through **pointers or references**. If you pass a derived object **by value** as a base, the object is sliced: only the base part is copied, and virtual calls on that copy use the base’s implementation. Always use Base* or Base& (or smart pointers) for polymorphic use. See [Inheritance](inheritance.md#6-slicing).

---

## 7. When to use runtime polymorphism

- **Same interface, different behaviour**: multiple implementations of the same contract (e.g. different shapes, different strategies).
- **Extensibility**: new derived types can be added without changing code that uses the base interface.
- **Heterogeneous collections**: e.g. `std::vector<std::unique_ptr<Shape>>` holding different shape types.

When the set of types is fixed and known at compile time, [templates](templates.md) (compile-time polymorphism) are often simpler and faster.

---

## 8. Quick reference

| Concept | Meaning |
|--------|--------|
| virtual | Function chosen at runtime by dynamic type |
| pure virtual (= 0) | No implementation in base; makes class abstract |
| override | Derived overrides base virtual; compiler checks |
| final | No further override / no further derivation |
| Virtual dtor | Required if you delete via base pointer |

---

## See also

- [Inheritance](inheritance.md) – base and derived, virtual destructor
- [Class](class.md) – members and access
- [Compile-time & runtime polymorphism](compile-time-and-runtime-polymorphism.md) – virtual vs templates/overloading
- [Constructors & destructors](constructors-and-destructors.md) – virtual destructor
