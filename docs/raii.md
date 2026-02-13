# RAII

**RAII** (Resource Acquisition Is Initialization) means: acquire a resource in a constructor and release it in the destructor. The object’s lifetime controls the resource’s lifetime, so you get automatic, exception-safe cleanup. This document covers the idea, how to apply it, and how it underlies smart pointers and standard types.

---

## 1. The idea

- **Acquire** when the object is **created** (in the constructor).
- **Release** when the object is **destroyed** (in the destructor).
- No separate “release” call in normal code; scope and destruction handle it.

That gives:

- **No leaks**: if you don’t leak the object, you don’t leak the resource.
- **Exception safety**: if an exception is thrown, stack unwinding runs destructors of local objects, so their resources are still released.
- **Single place for cleanup**: the destructor, instead of many paths (early return, every branch, etc.).

---

## 2. Basic pattern

```cpp
class FileHandle {
    FILE* file_ = nullptr;
public:
    explicit FileHandle(const char* path) {
        file_ = fopen(path, "r");
        if (!file_) throw std::runtime_error("cannot open file");
    }
    ~FileHandle() {
        if (file_) fclose(file_);
    }
    // Disable copy; enable move if desired
    FileHandle(const FileHandle&) = delete;
    FileHandle& operator=(const FileHandle&) = delete;
};

void use() {
    FileHandle f("data.txt");
    // use f...
}  // f's destructor runs here; file is closed
```

If `use()` throws after `f` is created, the destructor still runs and closes the file. No manual `fclose` in every path.

---

## 3. What counts as a “resource”

- **Memory**: raw `new`/`delete`, or (prefer) [smart pointers](smart-pointers.md) that use RAII.
- **File handles**: `fopen`/`fclose`, or `std::fstream`.
- **Locks**: acquire in ctor, release in dtor — e.g. `std::lock_guard`, `std::unique_lock`.
- **Sockets, handles, connections**: wrap in a class whose ctor acquires and dtor releases.
- **Reference counts, state**: “acquire” = increment or set state; “release” = decrement or reset.

Anything that must be paired (open/close, lock/unlock, allocate/free) fits RAII.

---

## 4. Scope and lifetime

The resource lives as long as the RAII object. Typical cases:

- **Block scope**: object is a local variable → destroyed at the end of the block (normal exit or exception).
- **Class member**: object is a member → destroyed when the containing object is destroyed (destructor order).
- **Dynamic**: object is owned by a smart pointer → destroyed when the last owner is destroyed.

So: “no leak” as long as the RAII object itself is not leaked (e.g. don’t put the only pointer in a global that never releases).

---

## 5. Copy and move

An RAII object often **owns** a resource. Then:

- **Copy**: either disable it (`= delete`), or implement deep copy (two independent resources).
- **Move**: transfer ownership: move constructor/assignment take the resource from the source and leave the source empty (or in a valid “moved-from” state). Then the moved-from object’s destructor has nothing to release.

```cpp
class FileHandle {
    FILE* file_ = nullptr;
public:
    FileHandle(FileHandle&& other) noexcept
        : file_(other.file_) {
        other.file_ = nullptr;
    }
    FileHandle& operator=(FileHandle&& other) noexcept {
        if (this != &other) {
            if (file_) fclose(file_);
            file_ = other.file_;
            other.file_ = nullptr;
        }
        return *this;
    }
    // ...
};
```

See [Move semantics](move-semantics.md).

---

## 6. Standard library examples

- **std::unique_ptr<T>**, **std::shared_ptr<T>**: manage dynamic memory; destructor deletes the object (or decrements ref count). See [Smart pointers](smart-pointers.md).
- **std::fstream**, **std::ifstream**, **std::ofstream**: open in constructor, close in destructor.
- **std::lock_guard<std::mutex>**: locks in constructor, unlocks in destructor. See [Threading](threading.md).
- **std::vector**, **std::string**: own their buffer; destructor frees it.

You use RAII whenever you use these types; you don’t manually release.

---

## 7. Guidelines

- **Prefer existing RAII types**: smart pointers, streams, lock guards, containers. Don’t hand-roll if the standard (or a library) already provides.
- **One resource per RAII object**: keeps ownership clear and destructor simple.
- **Don’t let exceptions escape the destructor**: destructors are often called during stack unwinding; if they throw, the program can terminate. Swallow, log, or use a known “terminate” policy.
- **Make ownership explicit**: if the object owns a raw handle, document it and disable or define copy/move so ownership is clear.

---

## 8. Quick reference

| Principle | Meaning |
|-----------|--------|
| Acquire in ctor | Resource is obtained when the object is created |
| Release in dtor | Resource is freed when the object is destroyed |
| No manual release | Rely on scope and destructors |
| Copy/move | Disable copy or define; implement move to transfer ownership |

---

## See also

- [Constructors & destructors](constructors-and-destructors.md) – how ctors and dtors work
- [Smart pointers](smart-pointers.md) – RAII for dynamic memory
- [Move semantics](move-semantics.md) – transferring ownership
- [Exception handling](exception-handling.md) – why RAII matters when exceptions are thrown
- [Threading](threading.md) – `std::lock_guard` and related RAII locks
