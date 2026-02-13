# Inheritance

**Inheritance** lets you define a new type (a **derived class**) that extends another type (a **base class**). The derived class gets the base’s members and can add or override behaviour. This document covers public inheritance, constructors and destructors, and when to use (or avoid) inheritance.

---

## 1. Basic syntax

Use a colon after the class name and the access specifier for the base, then the base class name.

```cpp
class Base {
public:
    void foo();
    int value_;
};

class Derived : public Base {
public:
    void bar();   // extra method
    int extra_;   // extra data
};

Derived d;
d.foo();       // from Base
d.bar();       // from Derived
d.value_;      // inherited (if public in Base)
```

**Public inheritance** (`: public Base`) means “Derived is-a Base”: the derived type models the same interface as the base and can be used where a Base is expected. Use public inheritance for **subtyping** (polymorphism). See [Polymorphism](polymorphism.md).

**Protected** and **private** inheritance exist but are rare; they don’t model “is-a” in the same way.

---

## 2. Access in derived classes

- **public** base members stay as declared in the base when accessed through the derived type (public → public, etc.) for **public** inheritance.
- **private** base members are never accessible in the derived class.
- **protected** base members are accessible in the derived class (and its derived classes), but not to outside code.

```cpp
class Base {
public:
    int pub;
protected:
    int prot;
private:
    int priv;
};

class Derived : public Base {
    void f() {
        pub;   // OK
        prot;  // OK
        // priv;  // Error: private in Base
    }
};
```

---

## 3. Constructors and destructors

- **Base is constructed first**, then members, then the derived constructor body. Base must be constructed before the derived object exists.
- **Destruction is reverse**: derived destructor body runs first, then members, then base destructor.

Use the **member initializer list** to pass arguments to the base constructor:

```cpp
class Base {
public:
    Base(int x) : x_(x) {}
private:
    int x_;
};

class Derived : public Base {
public:
    Derived(int x, int y) : Base(x), y_(y) {}
private:
    int y_;
};
```

If you don’t list the base in the initializer list, the base’s **default** constructor is used. If the base has no default constructor, you must call a specific base constructor explicitly.

---

## 4. Virtual destructor

If you use a class polymorphically (e.g. delete through a base pointer), the base destructor **must** be **virtual**. Otherwise only the base part is destroyed; the derived part is not (undefined behaviour).

```cpp
class Base {
public:
    virtual ~Base() = default;
};

class Derived : public Base {
    ~Derived() override = default;  // or implicit
};

Base* p = new Derived();
delete p;  // OK: calls Derived::~Derived() then Base::~Base()
```

See [Polymorphism](polymorphism.md) and [Constructors & destructors](constructors-and-destructors.md).

---

## 5. Overriding and virtual

- **virtual** in the base: the function can be overridden in derived classes; the call is dispatched based on the **dynamic** type of the object (runtime polymorphism).
- **override** (C++11) in the derived: marks that this function is intended to override a base virtual; the compiler checks that a matching base virtual exists.

```cpp
class Base {
public:
    virtual void f();
    virtual ~Base() = default;
};

class Derived : public Base {
public:
    void f() override;  // overrides Base::f
};
```

Use **override** so the compiler catches typos or signature mismatches.

---

## 6. Slicing

If you pass or store a derived object **by value** as a base type, only the base subobject is copied; the derived part is “sliced off.” Prefer references or pointers (or smart pointers) for polymorphism.

```cpp
void takeBase(Base b);  // copies only Base part
Derived d;
takeBase(d);  // slicing: d’s derived part is lost

void takeRef(Base& b);  // no copy, no slicing
takeRef(d);   // OK
```

---

## 7. Multiple inheritance

A class can have more than one direct base. Use it carefully; it can lead to ambiguity (same name in two bases) and the need for virtual bases. Prefer **composition** (member objects) or single inheritance when possible.

```cpp
class A {};
class B {};
class C : public A, public B {};
```

---

## 8. When to use inheritance

- Use **public inheritance** when you have a true “is-a” relationship and need polymorphism (same interface, different behaviour).
- Prefer **composition** (having a member of another type) when you only need to reuse implementation or data, not to substitute types.

---

## 9. Quick reference

| Topic | Summary |
|-------|---------|
| Syntax | `class Derived : public Base { ... };` |
| Base ctor | In initializer list: `Derived(...) : Base(args), ...` |
| Virtual dtor | Make base destructor `virtual` if you delete via base pointer |
| override | Use in derived to override base virtual; compiler checks |
| Slicing | Avoid passing polymorphic objects by value as base |

---

## See also

- [Class](class.md) – members and access
- [Constructors & destructors](constructors-and-destructors.md) – base/derived order, virtual destructor
- [Encapsulation](encapsulation.md) – protected and public
- [Polymorphism](polymorphism.md) – virtual functions and dynamic dispatch
- [Compile-time & runtime polymorphism](compile-time-and-runtime-polymorphism.md) – comparison of both
