# Encapsulation

**Encapsulation** means bundling data and the operations on that data inside a type, and hiding implementation details behind a **public interface**. Callers use the interface only; they don’t depend on how the type is implemented. This document covers access control, getters/setters, invariants, and how encapsulation relates to classes in C++.

---

## 1. The idea

- **Bundle** data (members) and behaviour (member functions) in one type (a [class](class.md)).
- **Hide** implementation: make data and helper logic **private** (or **protected** for [inheritance](inheritance.md)).
- **Expose** a **public** API: a small set of functions (and maybe types) that define how the type is used.

Benefits:

- **Invariants**: the class can enforce rules (e.g. “balance never negative”) in one place.
- **Flexibility**: you can change internal representation without breaking callers.
- **Simpler use**: callers don’t need to know internals.

---

## 2. Access specifiers

C++ gives you three levels of access:

| Specifier   | Who can access                                      |
|-------------|-----------------------------------------------------|
| **public**  | Any code                                            |
| **protected** | This class and [derived classes](inheritance.md)  |
| **private** | Only this class (and friends)                       |

Typical layout: put the **public interface first**, then **protected** (if any), then **private** implementation.

```cpp
class BankAccount {
public:
    void deposit(double amount);
    void withdraw(double amount);
    double balance() const;

private:
    double balance_ = 0;
    void log(const std::string& message);  // internal helper
};
```

Only `deposit`, `withdraw`, and `balance` are part of the contract. `balance_` and `log` are hidden; callers cannot touch them.

---

## 3. Enforcing invariants

An **invariant** is a condition that the class always keeps true. By keeping data private and allowing changes only through member functions, you can enforce it.

```cpp
class BankAccount {
public:
    void withdraw(double amount) {
        if (amount <= 0 || amount > balance_) return;  // or throw
        balance_ -= amount;
    }
    double balance() const { return balance_; }

private:
    double balance_ = 0;  // invariant: balance_ >= 0
};
```

If `balance_` were public, any code could set it to a negative value and break the invariant. Private data + controlled API keeps the invariant.

---

## 4. Getters and setters

**Getters** (accessors) expose read-only or controlled read access to state. Prefer **const** member functions when they don’t modify the object.

```cpp
class Point {
public:
    double x() const { return x_; }
    double y() const { return y_; }
    void setX(double x) { x_ = x; }
    void setY(double y) { y_ = y; }

private:
    double x_ = 0, y_ = 0;
};
```

- Use getters when you need to expose a value or a derived value.
- Use **setters** when you need to validate or side-effect on write; otherwise a simple public member (e.g. in a **struct** used as a data bag) might be enough.

Don’t add getters/setters for every member by habit; only expose what the abstraction needs.

---

## 5. Hiding implementation details

What stays **private** (or in a .cpp):

- Data members that are part of the representation.
- Helper functions used only inside the class.
- Types (nested classes, typedefs) that are not part of the public API.

Changing private members or adding new ones does not break the public API (as long as you don’t change the meaning of the public functions).

```cpp
class Widget {
public:
    int value() const;

private:
    // Could switch to a different representation later
    std::vector<int> data_;
    // int data_[100];  // old representation
};
```

---

## 6. Friends

A **friend** declaration gives a function or another class access to this class’s private (and protected) members. Use sparingly; it weakens encapsulation.

```cpp
class Widget {
    friend void debugPrint(const Widget& w);
    friend class WidgetTester;
private:
    int secret_;
};
void debugPrint(const Widget& w) {
    std::cout << w.secret_;  // OK: friend
}
```

Typical uses: stream operators (`operator<<`), or tests that need to poke internals.

---

## 7. Struct vs class for encapsulation

- **class**: default **private** — good when you have invariants and want to hide data.
- **struct**: default **public** — good for plain data aggregates with no invariants.

Use **class** when you want encapsulation; use **struct** when you want “just data.” See [Class](class.md).

---

## 8. Quick reference

| Idea | Meaning |
|------|--------|
| Encapsulation | Data + behaviour in one type; hide implementation behind public API |
| private | Only this class (and friends) |
| protected | This class and derived classes |
| public | Any code |
| Invariant | Condition the class always maintains; enforce via private data + member functions |
| Getters/setters | Controlled read/write; use when you need validation or abstraction |

---

## See also

- [Class](class.md) – members, access, static
- [Inheritance](inheritance.md) – protected and derived classes
- [Polymorphism](polymorphism.md) – public interfaces and virtual functions
