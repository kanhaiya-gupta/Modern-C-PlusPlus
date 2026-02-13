# Data Types

C++ has **fundamental (built-in) types**, **compound types** (pointers, arrays, references, classes), and **type aliases**. This document covers the built-in types, type modifiers, literals, and a brief note on type conversion. For pointers and references see [Pointers & references](pointers-and-references.md); for classes see [Class](class.md).

---

## 1. Fundamental types

### 1.1 Integer types

| Type | Typical size | Notes |
|------|--------------|--------|
| **bool** | 1 byte | true / false |
| **char** | 1 byte | Character; signed or unsigned (implementation-defined) |
| **signed char** / **unsigned char** | 1 byte | Explicit sign |
| **short** / **short int** | ≥ 2 bytes | At least 16 bits |
| **int** | ≥ 2 bytes, often 4 | “Natural” size for the machine |
| **long** | ≥ 4 bytes | |
| **long long** | ≥ 8 bytes (C++11) | At least 64 bits |
| **unsigned** variants | Same size | No sign bit; wrap-around arithmetic |

Use **int** for general integers; **unsigned** for counts, sizes, or bit masks when you need the range. Prefer **std::size_t** for sizes and counts in standard APIs.

```cpp
int n = -42;
unsigned int u = 42u;
long long big = 1'000'000'000LL;
```

### 1.2 Floating-point types

| Type | Typical size | Precision |
|------|--------------|-----------|
| **float** | 4 bytes | ~7 decimal digits |
| **double** | 8 bytes | ~15 decimal digits |
| **long double** | ≥ double | Implementation-defined |

Use **double** by default for real numbers unless you have a reason for **float** (e.g. storage, SIMD).

```cpp
float f = 3.14f;
double d = 3.14159;
long double ld = 3.14159265358979L;
```

### 1.3 void

**void** means “no type.” Used as:

- Function return type when nothing is returned.
- Parameter list: **void f(void)** or **void f()** (no parameters).
- **void*** — pointer to unspecified type (use sparingly; prefer templates or typed pointers).

---

## 2. Type modifiers

- **signed** / **unsigned** — for integers; **unsigned** gives non-negative range and wrap-around.
- **short** / **long** / **long long** — size of integer (see above).
- **const** — read-only; see [Const correctness](const-correctness.md).
- **volatile** — hint that the value may change outside the program (e.g. hardware register); rarely needed in normal code.

```cpp
unsigned int count;
long double precise;
const int maxSize = 100;
```

---

## 3. Standard type aliases (common)

Defined in **&lt;cstddef&gt;**, **&lt;cstdint&gt;**, etc.:

| Alias | Typical meaning | Use for |
|-------|------------------|--------|
| **std::size_t** | Unsigned type for sizes | Array sizes, **sizeof**, container **size()** |
| **std::ptrdiff_t** | Signed difference of two pointers | Iterator difference, **std::distance** |
| **std::int8_t**, **std::int16_t**, **std::int32_t**, **std::int64_t** | Fixed-width signed (if available) | When you need exact width |
| **std::uint8_t**, … | Fixed-width unsigned | Bytes, exact width |
| **std::nullptr_t** | Type of **nullptr** | Overloading on “null pointer” |

```cpp
#include <cstddef>
#include <cstdint>

std::size_t len = 10;
std::uint32_t id = 0x12345678;
```

---

## 4. Literals

### 4.1 Integer literals

- **Decimal**: `42`, `0`, `123`.
- **Octal**: prefix **0** — `052`.
- **Hexadecimal**: prefix **0x** or **0X** — `0x2A`.
- **Binary** (C++14): prefix **0b** or **0B** — `0b101010`.
- **Suffix**: **u** (unsigned), **l** / **L** (long), **ll** / **LL** (long long), **ul**, **ull`, etc. — `42u`, `1000LL`.
- **Digit separator** (C++14): **'** — `1'000'000`.

### 4.2 Floating-point literals

- **Default**: `3.14` is **double**.
- **Suffix**: **f** / **F** (float), **l** / **L** (long double) — `3.14f`, `3.14L`.
- **Exponent**: **e** or **E** — `1.5e10`, `2.5E-3`.

### 4.3 Character and string literals

- **Character**: `'a'`, `'\n'`, `'\0'`, `'\x41'` (hex), **char** or **wchar_t** (e.g. `L'a'`).
- **String**: `"hello"` — type **const char[]** (null-terminated); **u8"..."** (UTF-8), **L"..."** (wide), **u"..."**, **U"..."** (C++11).
- **Raw string** (C++11): `R"(...)"` — no escape inside; useful for regex, paths.

```cpp
char c = 'A';
const char* s = "hello";
std::string str = "world";
const char* path = R"(C:\Users\file.txt)";
```

### 4.4 Other literals

- **true** / **false** — **bool**.
- **nullptr** (C++11) — null pointer constant; type **std::nullptr_t**.

---

## 5. Type conversion (brief)

### 5.1 Implicit conversion

The compiler converts between types when allowed: e.g. **int** → **double**, **int** → **unsigned**, **array** → **pointer** (decay). Be aware of **narrowing** (e.g. double to int drops the fractional part; large unsigned to signed can wrap).

### 5.2 Explicit casts

- **static_cast&lt;T&gt;(expr)** — usual conversions (numeric, base→derived, void*→T*). Prefer this when you need a cast.
- **dynamic_cast&lt;T&gt;(expr)** — for polymorphic types; run-time check; returns null or throws for pointers/references.
- **const_cast&lt;T&gt;(expr)** — add or remove const/volatile; use only when you know the object is not really const.
- **reinterpret_cast&lt;T&gt;(expr)** — low-level reinterpretation of bits; implementation-defined; use with care.

```cpp
double d = 3.14;
int n = static_cast<int>(d);  // 3

Base* b = getBase();
Derived* d = dynamic_cast<Derived*>(b);  // null if not actually Derived
```

Avoid C-style cast **(\*)(expr)** in C++; use the C++ casts above so intent is clear. For full detail on when and how to use each cast, see [Casting](casting.md).

---

## 6. sizeof and alignment

- **sizeof(T)** or **sizeof expr** — size in bytes of type or expression result. Result type is **std::size_t**.
- **alignof(T)** (C++11) — alignment requirement of the type.

Sizes are implementation-defined (e.g. **int** is often 4 bytes; **long** can be 4 or 8). Use **sizeof** when you need byte size or allocation; prefer standard types (**size_t**, **int32_t**, etc.) when you need portability.

---

## 7. Quick reference

| Topic | Summary |
|-------|---------|
| Integers | bool, char, short, int, long, long long; signed/unsigned |
| Floating | float, double, long double |
| void | No type; used for “no return” and void* |
| Literals | Suffixes: u, l, ll, f, L; 0x, 0b; "string", 'c', nullptr |
| Conversion | Prefer static_cast; use dynamic_cast for polymorphism |
| Sizes | sizeof, alignof; std::size_t for sizes |

---

## See also

- [Type deduction](type-deduction.md) – auto and decltype
- [Pointers & references](pointers-and-references.md) – pointer and reference types
- [Class](class.md) – user-defined types
- [Const correctness](const-correctness.md) – const and type qualifiers
- [Templates](templates.md) – generic code over types
