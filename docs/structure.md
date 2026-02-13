# Structure (struct)

A **struct** in C++ is a user-defined type that groups data (and optionally member functions), with **public** access by default. It is the same as a **class** except for that default; it is often used for plain data aggregates. This document covers struct syntax, aggregate initialization, designated initializers, and when to use struct vs class. For members, constructors, and inheritance see [Class](class.md) and [Constructors & destructors](constructors-and-destructors.md).

---

## When to use structs

Structs work best when you need to **group related data** into one object with **no (or simple) behaviour**—no invariants to enforce, no hidden state. The data is the point; you read and write members directly or through simple helpers.

**Plain data / record (e.g. a point, a person, one row of data):**

```cpp
struct Point { double x, y; };
struct Person { std::string name; int age; };
struct Record { int id; std::string key; double value; };
```

Use a struct when the type is “just a bundle of fields” and any combination of values is valid. You can initialize with **{ }** and pass or return the whole thing by value or const reference.

**Returning the results of a function (multiple values):**

A very common use of a struct is to **return more than one value** from a function. Instead of output parameters or a **std::pair**, you return a small struct with named members—clear to read and easy to extend.

```cpp
struct Result { bool success; std::string message; };
Result parse(const std::string& input);
// Result r = parse("...");  then use r.success and r.message

struct Bounds { int min; int max; };
Bounds findMinMax(const std::vector<int>& v);
// Bounds b = findMinMax(v);  then use b.min and b.max
```

So yes: **returning the results of a function** is one of the main uses of a struct—when the result is naturally several values (success + message, min + max, etc.).

**Options / configuration (e.g. settings for a function or a module):**

```cpp
struct Config {
    int timeout = 30;
    std::string host = "localhost";
    bool verbose = false;
};
void connect(const Config& cfg);
```

Callers can use **designated initializers** (C++20) to set only the fields they care about: **Config c = { .timeout = 5, .verbose = true };**. See section 5 below.

**C interop / fixed layout:**

When you talk to C code or care about memory layout (e.g. file format, network packet), a **plain struct** with only data members and no virtuals keeps layout predictable. Often you keep it as an aggregate (no user-defined constructors) so **{ }** initialization matches C.

**Struct vs class (in short):**

| Use | Typical choice |
|-----|----------------|
| “Just data”; any values OK; init with **{ }** | **struct** |
| Invariants (e.g. “balance never negative”); hide implementation | **class** |
| C interop; options bundle; return multiple values | **struct** |

So: use a **struct** when you are grouping data or options and don’t need encapsulation; use a **class** when you have rules to enforce and want to hide internals. See [Encapsulation](encapsulation.md) and section 7 below for more.

---

## 1. What is a struct?

A **struct** is defined with the keyword **struct** and a body of members. Default access is **public** (unlike **class**, which defaults to **private**).

```cpp
struct Point {
    double x;
    double y;
};

Point p;
p.x = 1.0;
p.y = 2.0;
```

You can add **public**, **private**, and **protected** sections, member functions, constructors, and inheritance to a struct exactly as with a class. The only difference is the default for members before the first access specifier. See [Class](class.md).

---

## 2. Public, private, and protected in a struct

A struct can use the same **access specifiers** as a class. Before any specifier, members are **public** (in a class they would be private). After a specifier, the listed members follow that access until the next specifier.

### 2.1 Example: public and private

```cpp
struct Account {
    // public by default (struct)
    std::string owner() const { return owner_; }
    double balance() const { return balance_; }
    void deposit(double amount) {
        if (amount > 0) balance_ += amount;
    }

private:
    std::string owner_;
    double balance_ = 0.0;
};

Account a;
a.owner();        // OK: public
a.deposit(100.0); // OK: public
// a.balance_ = 0;  // Error: balance_ is private
```

Private members are only accessible from member functions (and friends) of the same struct. Public members form the interface.

### 2.2 Example: explicit public section

You can write **public:** explicitly to make the default obvious or to switch back after private/protected.

```cpp
struct Widget {
public:
    int id() const { return id_; }
    void setId(int id) { id_ = id; }
private:
    int id_ = 0;
};

Widget w;
w.id();     // OK
w.setId(1); // OK
// w.id_ = 1;  // Error: private
```

### 2.3 Example: protected (for inheritance)

**protected** members are accessible in this struct and in **derived** structs (or classes); they are not accessible from unrelated code.

```cpp
struct Base {
    int getPublic() const { return pub_; }
protected:
    int getProtected() const { return prot_; }
    int prot_ = 0;
private:
    int pub_ = 0;
};

struct Derived : Base {
    void use() {
        getPublic();    // OK: public in Base
        getProtected(); // OK: we are derived
        prot_;          // OK: we are derived
        // pub_;        // Error: private in Base
    }
};

Base b;
b.getPublic();    // OK
// b.getProtected();  // Error: protected
// b.prot_;            // Error: protected
```

So in a struct you can use **public**, **private**, and **protected** the same way as in a class; only the default before the first specifier is different. See [Encapsulation](encapsulation.md) and [Inheritance](inheritance.md).

---

## 3. Struct for data aggregates (plain data)

A **struct** is often used as a **data aggregate**: a type whose members are just data, with no invariants or complex behaviour. That fits:

- Configuration or options (e.g. a bundle of parameters).
- Return values with multiple fields (e.g. a result plus a status).
- C compatibility (struct layout and initialization).

Convention: use **struct** when the type is “just data” or a simple record; use **class** when you have invariants and encapsulation. See [Encapsulation](encapsulation.md).

---

## 4. Aggregate initialization

An **aggregate** is an array or a type with no user-declared constructors, no private/protected non-static data members, no base classes, and no virtual functions (simplified). Structs that are aggregates can be initialized with **brace-initialization** (list of values in order).

```cpp
struct Point {
    double x, y;
};

Point p1 = {1.0, 2.0};
Point p2{3.0, 4.0};   // direct initialization
Point p3 = {};        // zero-initialize: 0.0, 0.0
```

- Members are initialized in **declaration order**.
- Missing trailing members are **value-initialized** (zero for scalars).
- Excess initializers are an error.

If you add a user-declared constructor, the type is no longer an aggregate and you use that constructor instead of aggregate init (unless you also provide an initializer-list constructor or default member initializers).

---

## 5. Designated initializers (C++20)

You can initialize by **member name** so order and “skip” are explicit. Unmentioned members are value-initialized.

```cpp
struct Config {
    int timeout = 30;
    std::string host = "localhost";
    bool verbose = false;
};

Config c1 = { .timeout = 5, .host = "server" };  // verbose is false
Config c2 = { .verbose = true };                 // timeout 30, host "localhost"
```

Designations must appear in **declaration order**; you cannot reorder or mix designated and non-designated initializers in the same list in a way that breaks order.

---

## 6. Default member initializers

You can give members a default value in the struct definition. Aggregate init then only needs to set the ones you want to override.

```cpp
struct Options {
    int threads = 4;
    bool debug = false;
};

Options o1;           // threads 4, debug false
Options o2 = {8};     // threads 8, debug false
Options o3 = {8, true};
```

---

## 7. Struct vs class — when to use which

| Use | Typical choice |
|-----|-----------------|
| Plain data; no invariants; aggregate init | **struct** |
| Data + behaviour; invariants; encapsulation | **class** |
| C interop; layout matters | **struct** (often keep as aggregate) |
| Polymorphism, virtual functions | **class** (or struct; same capability) |

The language treats them the same except for default access. The convention above keeps code intent clear: struct = “data bag,” class = “type with behaviour and hidden state.”

---

## 8. Nested and anonymous structs

You can define a struct inside another struct (or class) for scoping.

```cpp
struct Outer {
    struct Inner {
        int value;
    };
    Inner i;
};
Outer::Inner x;
```

**Anonymous structs** (no name after **struct**) are not standard C++; in C you might see them for “flat” members. In C++ use a named nested struct or a namespace if you need grouping.

---

## 9. Size and layout

**sizeof(struct)** is the size of all non-static data members (plus padding for alignment). Empty structs have **sizeof** at least 1. Layout is implementation-defined; for C compatibility or low-level use, **standard-layout** types have predictable layout. A struct is standard-layout if it has no virtuals, no mixed access among members in the same section, and other conditions (see the standard). See [Data types](data-types.md) for **sizeof** and **alignof**.

---

## 10. Quick reference

| Topic | Summary |
|-------|---------|
| struct vs class | Same except default access: struct = public |
| public / private / protected | Same as class; use access specifiers to hide data or allow derived access |
| Aggregate init | Brace list in member order; { }, { a }, { a, b } |
| Designated init (C++20) | { .member = value }; unmentioned members value-initialized |
| Default member init | In-class = value; then aggregate init overrides as needed |
| When to use struct | Data aggregates, options, C interop, “plain data” |

---

## See also

- [Class](class.md) – members, access, static; class and struct are the same type of thing
- [Constructors & destructors](constructors-and-destructors.md) – if you add constructors, aggregate rules change
- [Encapsulation](encapsulation.md) – when to hide data (class) vs keep it simple (struct)
- [Data types](data-types.md) – sizeof, alignof, fundamental types
