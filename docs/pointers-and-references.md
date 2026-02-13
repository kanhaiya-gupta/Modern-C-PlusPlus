# Pointers & References

Pointers and references both refer to existing objects instead of copying them. References are aliases (same object, another name); pointers are values that hold addresses. This document covers syntax, semantics, and when to use each.

---

## 1. References

### 1.1 What is a reference?

A **reference** is an alias for an existing object. It is not a separate object and does not hold an address as a value—it *is* another name for the same object.

```cpp
int x = 42;
int& ref = x;   // ref is an alias for x

ref = 99;       // same as x = 99
// x is now 99
```

Rules:

- A reference must be initialized when declared (it cannot “point to nothing”).
- After initialization, it cannot be rebound to another object.
- There are no “reference arithmetic” or “null references” in valid code.

### 1.2 Lvalue reference (`T&`)

Binds to lvalues (objects that have identity and can be on the left of `=`).

```cpp
int a = 10;
int& r = a;     // OK: a is an lvalue
// int& r2 = 10;  // Error: 10 is an rvalue (literal)

r = 20;         // modifies a
```

Use for:

- Function parameters when the function may modify the argument (see [Functions](functions.md)).
- Return types when returning an existing object (and you are sure about lifetime).

### 1.3 Const reference (`const T&`)

Binds to lvalues and extends the lifetime of temporaries (rvalues) for the lifetime of the reference.

```cpp
int x = 5;
const int& cr1 = x;   // OK: bind to lvalue
const int& cr2 = 10;  // OK: temporary lives as long as cr2

// cr1 = 7;  // Error: cr1 is const
```

Use for:

- Read-only function parameters (no copy, no modification).
- Returning a const view of existing data when lifetime is safe.

### 1.4 Reference binding summary

| Reference type | Can bind to lvalue? | Can bind to rvalue? |
|----------------|---------------------|----------------------|
| `T&`           | Yes                 | No                   |
| `const T&`     | Yes                 | Yes (extends lifetime of temporary) |

---

## 2. Pointers

### 2.1 What is a pointer?

A **pointer** is an object whose value is the address of another object (or “null”). Unlike a reference, a pointer can be null, reassigned, and used in arithmetic.

```cpp
int x = 42;
int* p = &x;    // p holds the address of x
// *p is the object at that address (x)
```

- `&` in declarations: “pointer to” (e.g. `int* p`).
- `&` in expressions: “address-of” (e.g. `&x`).
- `*` in expressions: “dereference” (e.g. `*p` means the object p points to).

### 2.2 Declaration and initialization

```cpp
int  a = 10;
int* p = &a;    // p points to a

*p = 20;        // a is now 20
```

Always prefer **`nullptr`** for “no object” (C++11). Do not use `0` or `NULL` for pointers.

```cpp
int* p = nullptr;
if (p) {
    *p = 5;     // only if p is not null
}
```

### 2.3 Null check before use

Dereferencing a null pointer is undefined behaviour. Always check (or ensure by design that the pointer is non-null).

```cpp
void use(int* p) {
    if (p) {
        *p += 1;
    }
}

use(nullptr);   // safe: no dereference
use(&x);        // safe: p is valid
```

### 2.4 Pointer to pointer

A pointer can point to another pointer (useful in C-style APIs or when representing indirection).

```cpp
int x = 42;
int* p = &x;
int** pp = &p;

**pp = 99;      // same as *p = 99; same as x = 99
```

---

## 3. Pointers and arrays

### 3.1 Array decay

An array name, when used in most expressions, “decays” to a pointer to its first element. The size is lost.

```cpp
int arr[] = {10, 20, 30};
int* p = arr;   // same as int* p = &arr[0];

// p points to first element
*p;             // 10
*(p + 1);       // 20
p[1];           // same as *(p + 1)
```

### 3.2 Pointer arithmetic

Adding an integer to a pointer moves by that many elements (not bytes). Subtraction of two pointers (to elements of the same array) gives the distance in elements.

```cpp
int arr[] = {10, 20, 30, 40};
int* p = arr;

p + 0;          // &arr[0]
p + 2;          // &arr[2]
*(p + 2);       // 30

int* q = &arr[3];
q - p;          // 3 (number of elements between them)
```

Arithmetic is only defined within one array object (or one past the end). Going beyond that is undefined behaviour.

### 3.3 Arrays are not pointers

- **Array**: fixed-size aggregate of elements; `sizeof(arr)` is the size of the whole array.
- **Pointer**: holds one address; `sizeof(p)` is the size of the pointer.

```cpp
int arr[4];
int* p = arr;

sizeof(arr);    // e.g. 4 * sizeof(int)
sizeof(p);      // size of a pointer (e.g. 8 on 64-bit)
```

---

## 4. References vs pointers

| Aspect            | Reference (`T&`)     | Pointer (`T*`)        |
|------------------|----------------------|------------------------|
| Can be null      | No                   | Yes (`nullptr`)        |
| Rebindable       | No                   | Yes                    |
| Syntax           | Alias, no `*` at use | Dereference with `*`   |
| Typical use      | Aliases, parameters  | Optional, arrays, C API |

When the object always exists and you don’t need “no object,” prefer a reference. When you need “optional” or indirection (e.g. arrays, trees), use a pointer or a smart pointer.

---

## 5. Function parameters: reference vs pointer

Use a **reference** when the argument is required and you don’t need to represent “absent”:

```cpp
void scale(int& x, int factor) {
    x *= factor;
}
```

Use a **pointer** when “no object” is a valid case:

```cpp
void maybeScale(int* x, int factor) {
    if (x) *x *= factor;
}

maybeScale(&a, 2);
maybeScale(nullptr, 2);  // no-op
```

In new code, **`std::optional<T>&`** or overloads can also express optional in/out parameters.

---

## 6. Return by reference vs by pointer

Return by **reference** when you always return an existing object and want callers to use it like a value:

```cpp
const std::string& getDefaultName() {
    static const std::string s = "default";
    return s;
}
```

Return by **pointer** when “no result” is possible (e.g. lookup):

```cpp
Node* find(Node* root, int key) {
    if (!root) return nullptr;
    if (root->id == key) return root;
    // ...
}
```

Never return a reference or pointer to a local variable; that causes undefined behaviour.

---

## 7. Common pitfalls

### 7.1 Dangling reference

Using a reference (or pointer) after the referred object is destroyed.

```cpp
const std::string& bad() {
    std::string s = "hello";
    return s;   // s is destroyed at return; undefined behaviour
}
```

Only return references to objects that outlive the function (e.g. static, caller-owned object, or member of a living object).

### 7.2 Null pointer dereference

Dereferencing `nullptr` (or an invalid pointer) is undefined behaviour.

```cpp
int* p = nullptr;
*p = 42;    // undefined behaviour
```

Check for null (or use types that cannot be null, e.g. references or smart pointers) before dereferencing.

### 7.3 Invalid pointer arithmetic

Arithmetic is only valid within one array (or one past the end). Otherwise behaviour is undefined.

```cpp
int x = 5, y = 10;
int* p = &x;
p + 1;      // undefined: not same array as &y
```

### 7.4 Modifying through const reference

You cannot modify the object through a `const T&`. The object might be a temporary; modifying it would be confusing and is forbidden.

```cpp
const int& r = 42;
// r = 1;   // Error
```

---

## 8. Pointers to const and const pointers

- **Pointer to const** (`const T*` or `T const*`): the pointed-to object is read-only.
- **Const pointer** (`T* const`): the pointer itself cannot be reassigned.
- **Const pointer to const** (`const T* const`): neither can change.

```cpp
int x = 1, y = 2;

const int* p1 = &x;    // can't change *p1; can set p1 = &y
// *p1 = 2;            // Error
p1 = &y;               // OK

int* const p2 = &x;    // can change *p2; can't set p2 = &y
*p2 = 2;               // OK
// p2 = &y;            // Error

const int* const p3 = &x;  // can't change *p3 or p3
```

---

## 9. Rvalue references (brief)

**Rvalue references** (`T&&`) are for move semantics and perfect forwarding. They bind to temporaries and “moved-from” values. Covered in [Move semantics](move-semantics.md).

---

## 10. Smart pointers

For dynamic allocation, prefer **smart pointers** (`std::unique_ptr`, `std::shared_ptr`) over raw pointers. They clarify ownership and reduce leaks and misuse. See [Smart pointers](smart-pointers.md).

---

## Quick reference

| Need                         | Use                    |
|-----------------------------|------------------------|
| Alias, never null           | `T&` or `const T&`     |
| Optional / nullable         | `T*` or smart pointer |
| Read-only parameter         | `const T&`             |
| Modify argument             | `T&`                   |
| Array / low-level iteration | `T*` or iterators      |
| Owned heap object           | `std::unique_ptr<T>`   |
| Shared ownership            | `std::shared_ptr<T>`   |

---

## See also

- [Functions](functions.md) – parameter passing (value, reference, const reference)
- [Smart pointers](smart-pointers.md) – `unique_ptr`, `shared_ptr`, `weak_ptr`
- [Move semantics](move-semantics.md) – rvalue references and moving
