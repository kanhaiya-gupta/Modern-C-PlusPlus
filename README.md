# Modern C++ Documentation

A topic-by-topic reference for **Modern C++**, with one markdown file per subject. The docs cover fundamentals, OOP, memory and ownership, concurrency, generic programming, the type system, the standard library, and practical project layout—all with examples.

---

## Contents

All documentation lives in the **[`docs/`](docs/)** directory. Topics are grouped below.

### Basics

| Topic | File | Description |
|-------|------|-------------|
| Data Types | [data-types.md](docs/data-types.md) | Fundamental types, literals, type conversion, `sizeof` |
| Enums | [enums.md](docs/enums.md) | enum class (scoped), unscoped enum, underlying type, conversion |
| Functions | [functions.md](docs/functions.md) | Parameters, return types, overloading, `std::function`, smart pointers |
| Namespaces | [namespaces.md](docs/namespaces.md) | Namespace definition, `using`, anonymous namespace, ADL |

### OOP & fundamentals

| Topic | File | Description |
|-------|------|-------------|
| Class | [class.md](docs/class.md) | Members, access, `this`, static members, nested types |
| Structure (struct) | [structure.md](docs/structure.md) | struct vs class, aggregate init, designated initializers (C++20) |
| Constructors & Destructors | [constructors-and-destructors.md](docs/constructors-and-destructors.md) | Default, copy, move, RAII, rule of five |
| Operator Overloading | [operator-overloading.md](docs/operator-overloading.md) | `operator+`, `operator[]`, `operator<<`, spaceship (C++20) |
| Encapsulation | [encapsulation.md](docs/encapsulation.md) | public/private/protected, invariants, getters/setters |
| Inheritance | [inheritance.md](docs/inheritance.md) | Base and derived, virtual destructor, override, slicing |
| Polymorphism | [polymorphism.md](docs/polymorphism.md) | Virtual functions, abstract classes, override, final |
| Compile-time & Runtime Polymorphism | [compile-time-and-runtime-polymorphism.md](docs/compile-time-and-runtime-polymorphism.md) | Virtual vs templates/overloading, when to use which |

### Memory & ownership

| Topic | File | Description |
|-------|------|-------------|
| Pointers & References | [pointers-and-references.md](docs/pointers-and-references.md) | References, pointers, arrays, const, rvalue refs (brief) |
| Smart Pointers | [smart-pointers.md](docs/smart-pointers.md) | `unique_ptr`, `shared_ptr`, `weak_ptr`, `make_unique`, `make_shared` |
| RAII | [raii.md](docs/raii.md) | Acquire in ctor, release in dtor, resource management |
| Move Semantics | [move-semantics.md](docs/move-semantics.md) | Rvalue references, move ctor/assign, `std::move`, `std::forward` |

### Concurrency & async

| Topic | File | Description |
|-------|------|-------------|
| Threading | [threading.md](docs/threading.md) | `std::thread`, mutexes, `lock_guard`, condition variables, `atomic` |
| Coroutines | [coroutines.md](docs/coroutines.md) | `co_await`, `co_yield`, `co_return`, generators (C++20) |

### Functional style

| Topic | File | Description |
|-------|------|-------------|
| Lambdas | [lambdas.md](docs/lambdas.md) | Capture, `mutable`, generic lambdas, `[*this]` |

### Ranges & lazy evaluation

| Topic | File | Description |
|-------|------|-------------|
| Ranges & Views | [ranges-and-views.md](docs/ranges-and-views.md) | Range algorithms, views, pipelines (C++20) |
| Lazy Evaluation | [lazy-evaluation.md](docs/lazy-evaluation.md) | Lazy views, generators, when to use lazy |
| Analysis Pipelines | [analysis-pipelines.md](docs/analysis-pipelines.md) | Design of analysis pipelines, large data, streaming, chunking; cases (log processing, ETL, aggregation, etc.) |

### Generic programming

| Topic | File | Description |
|-------|------|-------------|
| Templates | [templates.md](docs/templates.md) | Function and class templates, deduction, specialization, variadics |
| Concepts | [concepts.md](docs/concepts.md) | Constraints, `requires`, standard concepts (C++20) |

### Type system & compile-time

| Topic | File | Description |
|-------|------|-------------|
| Type Deduction | [type-deduction.md](docs/type-deduction.md) | `auto`, `decltype`, `decltype(auto)` |
| constexpr | [constexpr.md](docs/constexpr.md) | Compile-time evaluation, `consteval`, `constinit` (C++20) |
| Static | [static.md](docs/static.md) | Static storage, static locals, static linkage, static members |
| Casting | [casting.md](docs/casting.md) | `static_cast`, `dynamic_cast`, `const_cast`, `reinterpret_cast` |

### Correctness & robustness

| Topic | File | Description |
|-------|------|-------------|
| const Correctness | [const-correctness.md](docs/const-correctness.md) | const parameters, const members, mutable |
| Exception Handling | [exception-handling.md](docs/exception-handling.md) | throw, try/catch, noexcept, exception safety |
| Defensive Programming | [defensive-programming.md](docs/defensive-programming.md) | assertions, input validation, null/bounds checks, RAII |

### Standard library

| Topic | File | Description |
|-------|------|-------------|
| Iterators | [iterators.md](docs/iterators.md) | Iterator categories, begin/end, invalidation, sentinels |
| Containers | [containers.md](docs/containers.md) | Container categories, which to use when |
| Vector Reference | [vector-reference.md](docs/vector-reference.md) | All std::vector operations: construct, capacity, access, modifiers, iterators, algorithms |
| STL Containers | [stl-containers.md](docs/stl-containers.md) | vector, map, set, unordered_*, adapters, complexity |

### Practice

| Topic | File | Description |
|-------|------|-------------|
| Programming in C++ | [programming_in_cplusplus.md](docs/programming_in_cplusplus.md) | Header/cpp separation, static, const, lambdas, ranges, threading, templates, inheritance, polymorphism, smart pointers, move, exceptions—all with class-based examples |
| Practice Questions | [practice-questions.md](docs/practice-questions.md) | Coding interview practice: vectors, ranges, lambdas, lazy evaluation, map, unordered_map with solutions |
| C++ Cheat Sheet | [cpp-cheatsheet.md](docs/cpp-cheatsheet.md) | One concept + one example each (compile, STL, lambdas, pointers, classes, templates)—exam reference |

### Libraries & frameworks

| Topic | File | Description |
|-------|------|-------------|
| Qt | [qt.md](docs/qt.md) | Qt overview: QObject, signals/slots, parent–child ownership, Qt types vs std, build (moc, qmake, CMake) |
| QML | [qml.md](docs/qml.md) | QML overview: declarative UI, properties/bindings, signals/handlers, exposing C++ to QML, loading from C++ |

---

## Script: create placeholder docs

To (re)create placeholder markdown files for all topics (without overwriting existing content):

```bash
bash create-cpp-docs.sh
```

Optional: pass a directory name to create placeholders elsewhere (e.g. `bash create-cpp-docs.sh my_docs`). Default output directory is **`docs/`**.

---

## Suggested order for learning

1. **Basics:** Data types → Functions → Namespaces  
2. **OOP:** Class → Structure → Constructors & destructors → Encapsulation → Inheritance → Polymorphism  
3. **Memory:** Pointers & references → Smart pointers → RAII → Move semantics  
4. **Type system:** Type deduction → constexpr → Static → Casting → Const correctness  
5. **Generic:** Templates → Concepts  
6. **Library:** Containers → Iterators → Ranges & views → Lambdas  
7. **Concurrency:** Threading → Coroutines (optional)  
8. **Practice:** Programming in C++ (ties everything together)

---

## Requirements

- The docs assume **C++11** through **C++20** (and occasionally C++23) where noted.  
- No build system or compiler is required to read the markdown; code snippets are for reference and learning.
