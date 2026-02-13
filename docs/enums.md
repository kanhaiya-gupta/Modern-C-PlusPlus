# Enums

**Enumerations** define a set of named constants. C++ has **unscoped enums** (C-style) and **scoped enums** (**enum class**, C++11). Scoped enums are preferred: they don’t leak names into the surrounding scope and don’t implicitly convert to integers. This document covers both forms, underlying type, and typical use.

---

## When to use enums

Enums work best when you have a **small, fixed set of mutually exclusive options**—things that can only be one value at a time.

**Switch / mode (e.g. ON/OFF, or a few modes):**

```cpp
enum class Power { Off, On };
enum class Mode { Idle, Low, Medium, High };
```

Use an enum instead of a bare **bool** when you have more than two states (e.g. Low/Medium/High) or when **On**/ **Off** are clearer than **true**/ **false**.

**State (e.g. traffic signals, connection status):**

```cpp
enum class TrafficLight { Red, Yellow, Green };
enum class ConnectionState { Disconnected, Connecting, Connected, Failed };
```

Here the value represents “current state”; you typically use it in **switch** or **if** to decide what to do next. Enums make the possible states explicit and give them readable names instead of magic numbers (0, 1, 2).

**In short:** use enums for **states** (traffic light, connection, parser state) and for **modes/options** (ON/OFF, Low/Medium/High, or a small set of choices). They keep code clear and prevent invalid values.

---

## 1. Scoped enums (enum class, C++11)

A **scoped enumeration** is declared with **enum class** (or **enum struct**; same meaning). The enumerator names are in the enum’s scope and must be qualified when used. They do **not** implicitly convert to or from **int**.

```cpp
enum class Color { Red, Green, Blue };

Color c = Color::Red;
// int i = c;        // Error: no implicit conversion to int
int i = static_cast<int>(Color::Red);  // OK: explicit conversion

// Color x = 0;      // Error: no implicit conversion from int
Color x = static_cast<Color>(0);      // OK: explicit
```

Use **enum class** by default: no name collisions (e.g. `Color::Red` vs `State::Red`), and explicit conversions avoid bugs.

---

## 2. Unscoped enums (C-style)

An **unscoped enumeration** is declared with **enum** (no **class**). The enumerator names are in the **surrounding scope** and implicitly convert to integral types.

```cpp
enum Status { Ok, Error, Pending };  // Ok, Error, Pending are in surrounding scope

Status s = Ok;
int i = Ok;       // OK: implicit conversion (i is 0)
Status t = static_cast<Status>(1);  // OK: explicit conversion from int
```

Problems: enumerators can clash with other names in the same scope; implicit conversion to int can hide mistakes. Prefer **enum class** in new code.

---

## 3. Underlying type

Each enumeration has an **underlying type** (an integral type used to represent the values). For **enum class**, the default is **int**. You can set it explicitly with **: type** after the enum name.

```cpp
enum class Small : unsigned char { A, B, C };  // 1 byte per value
enum class Big : long long { Low = 0, High = 1LL << 60 };
```

For **unscoped enums**, the underlying type is implementation-defined (often **int**) unless you specify it. Specifying the underlying type allows **forward declaration** of the enum.

---

## 4. Explicit enumerator values

You can assign explicit values to enumerators. Unassigned enumerators get the previous value + 1.

```cpp
enum class HttpCode {
    Ok = 200,
    Created = 201,
    BadRequest = 400,
    NotFound = 404,
    ServerError = 500
};

enum class State { Idle, Running, Done };  // 0, 1, 2
enum class Flags { A = 1, B = 2, C = 4 };
```

Use explicit values when you need to match an external protocol or bit flags.

---

## 4.1 Enumerators are constants

The names **A**, **B**, **C** (or **Red**, **Green**, **Blue**, etc.) are **constants**: each has a fixed value that does not change. You can choose any valid identifier as the name; it still represents a constant value.

```cpp
enum class Option { OptionA, OptionB, OptionC };  // same as A, B, C with values 0, 1, 2
enum class Level { Low = 10, Medium = 50, High = 100 };  // names and values are fixed
```

So you can use short names (A, B, C), longer names (OptionA, OptionB), or domain names (Red, Idle, NotFound)—they are all named constants. The **value** of each enumerator is fixed at compile time (either 0, 1, 2, … or the explicit value you assign).

---

## 4.2 Mapping enum values to string text (for display)

Often you need a **human-readable string** for an enum value (e.g. for logging or UI). You can map the enum to **const** string literals with a function or a lookup table.

**Using a switch:**

```cpp
enum class State { Idle, Running, Done };

const char* to_string(State s) {
    switch (s) {
        case State::Idle:   return "Idle";
        case State::Running: return "Running";
        case State::Done:   return "Done";
    }
    return "Unknown";
}
// std::cout << to_string(State::Running);  // "Running"
```

**Using an array (when values are 0, 1, 2, …):**

```cpp
enum class Color { Red, Green, Blue };

constexpr const char* color_names[] = { "Red", "Green", "Blue" };

const char* to_string(Color c) {
    return color_names[static_cast<int>(c)];
}
```

So: the enum gives you **constant names** in code (e.g. `State::Running`); you add a small layer (function or array) to turn those **constants into text** when you need to display them. See [Const correctness](const-correctness.md) for **const** and [Data types](data-types.md) for string literals.

---

## 5. Forward declaration

With a **fixed underlying type**, you can forward-declare an enum and define it later. Useful to reduce includes in headers.

```cpp
// api.h
enum class ErrorCode : int;  // forward declaration

void log(ErrorCode e);

// api.cpp
enum class ErrorCode : int {
    None = 0,
    IoError,
    InvalidArg
};
void log(ErrorCode e) { /* ... */ }
```

---

## 6. Enums in classes and namespaces

You can define enums inside a **class** or **namespace** to scope the names. With **enum class**, the enum name and enumerators are already scoped.

```cpp
class Parser {
public:
    enum class State { Idle, Reading, Done };
    State state() const { return state_; }
private:
    State state_ = State::Idle;
};

Parser p;
Parser::State s = Parser::State::Reading;
```

With an unscoped enum inside a class, the enumerators are in the class scope: `Parser::Idle` (if the enum were unscoped).

---

## 7. Switch and iteration

Use scoped enums in **switch**; list all enumerators or provide a **default** to avoid warnings.

```cpp
enum class Action { Start, Stop, Pause };

void handle(Action a) {
    switch (a) {
        case Action::Start:  /* ... */ break;
        case Action::Stop:   /* ... */ break;
        case Action::Pause:  /* ... */ break;
    }
}
```

C++ does not offer a built-in way to iterate over enumerators; use an array of values or a code generator if you need that.

---

## 8. Conversion: enum ↔ int

- **enum class** → int: **static_cast&lt;int&gt;(value)**.
- int → **enum class**: **static_cast&lt;EnumType&gt;(value)**. Ensure the integer is in range for the enum.
- **Unscoped enum**: implicit conversion to int; from int may require **static_cast** depending on the standard and compiler.

See [Casting](casting.md).

---

## 9. Quick reference

| Topic | Summary |
|-------|---------|
| enum class | Scoped; no implicit conversion; use **EnumName::Enumerator** |
| enum (unscoped) | Enumerators in surrounding scope; implicit conversion to int |
| Enumerators | Named constants; you choose names (A, B or OptionA, OptionB, etc.) and optional values |
| Enum → string | Use a **switch** or **array** to map enum value to **const char*** or **std::string** for display |
| Underlying type | Default **int** for enum class; set with **: type** |
| Explicit values | **Name = value**; next is previous + 1 if omitted |
| Forward declaration | Requires fixed underlying type: **enum class E : int;** |
| Conversion | **static_cast&lt;int&gt;(e)** or **static_cast&lt;E&gt;(i)** for enum class |

---

## See also

- [Data types](data-types.md) – integral types and type system
- [Class](class.md) – nested types and enum inside class
- [Casting](casting.md) – static_cast for enum ↔ int
