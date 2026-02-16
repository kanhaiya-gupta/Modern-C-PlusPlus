#!/usr/bin/env bash
# Creates placeholder markdown files for Modern C++ documentation.
# Run with: bash create-cpp-docs.sh

DOCS_DIR="${1:-docs}"

mkdir -p "$DOCS_DIR"

create_placeholder() {
  local file="$1"
  local title="$2"
  if [[ ! -f "$file" ]]; then
    printf '# %s\n\n> Placeholder. Content coming soon.\n' "$title" > "$file"
    echo "Created: $file"
  else
    echo "Exists: $file (skipped)"
  fi
}

# Basics
create_placeholder "$DOCS_DIR/data-types.md" "Data Types"
create_placeholder "$DOCS_DIR/enums.md" "Enums"
create_placeholder "$DOCS_DIR/functions.md" "Functions"
create_placeholder "$DOCS_DIR/namespaces.md" "Namespaces"

# OOP & fundamentals
create_placeholder "$DOCS_DIR/class.md" "Class"
create_placeholder "$DOCS_DIR/structure.md" "Structure (struct)"
create_placeholder "$DOCS_DIR/constructors-and-destructors.md" "Constructors & Destructors"
create_placeholder "$DOCS_DIR/operator-overloading.md" "Operator Overloading"
create_placeholder "$DOCS_DIR/encapsulation.md" "Encapsulation"
create_placeholder "$DOCS_DIR/inheritance.md" "Inheritance"
create_placeholder "$DOCS_DIR/polymorphism.md" "Polymorphism"
create_placeholder "$DOCS_DIR/compile-time-and-runtime-polymorphism.md" "Compile-time & Runtime Polymorphism"

# Memory & ownership
create_placeholder "$DOCS_DIR/pointers-and-references.md" "Pointers & References"
create_placeholder "$DOCS_DIR/smart-pointers.md" "Smart Pointers"
create_placeholder "$DOCS_DIR/raii.md" "RAII"
create_placeholder "$DOCS_DIR/move-semantics.md" "Move Semantics"

# Concurrency & async
create_placeholder "$DOCS_DIR/threading.md" "Threading"
create_placeholder "$DOCS_DIR/coroutines.md" "Coroutines"

# Functional style
create_placeholder "$DOCS_DIR/lambdas.md" "Lambdas"

# Ranges & lazy evaluation
create_placeholder "$DOCS_DIR/ranges-and-views.md" "Ranges & Views"
create_placeholder "$DOCS_DIR/lazy-evaluation.md" "Lazy Evaluation"

# Generic programming
create_placeholder "$DOCS_DIR/templates.md" "Templates"
create_placeholder "$DOCS_DIR/concepts.md" "Concepts"

# Type system & compile-time
create_placeholder "$DOCS_DIR/type-deduction.md" "Type Deduction (auto, decltype)"
create_placeholder "$DOCS_DIR/constexpr.md" "constexpr"
create_placeholder "$DOCS_DIR/static.md" "Static"
create_placeholder "$DOCS_DIR/casting.md" "Casting"

# Correctness & robustness
create_placeholder "$DOCS_DIR/const-correctness.md" "const Correctness"
create_placeholder "$DOCS_DIR/exception-handling.md" "Exception Handling"
create_placeholder "$DOCS_DIR/defensive-programming.md" "Defensive Programming"

# Standard library
create_placeholder "$DOCS_DIR/iterators.md" "Iterators"
create_placeholder "$DOCS_DIR/containers.md" "Containers"
create_placeholder "$DOCS_DIR/vector-reference.md" "Vector Reference"
create_placeholder "$DOCS_DIR/stl-containers.md" "STL Containers"

# Practice
create_placeholder "$DOCS_DIR/programming_in_cplusplus.md" "Programming in C++"
create_placeholder "$DOCS_DIR/practice-questions.md" "Practice Questions (Coding Interviews)"

# Libraries & frameworks
create_placeholder "$DOCS_DIR/qt.md" "Qt"
create_placeholder "$DOCS_DIR/qml.md" "QML"

echo ""
echo "Done. Placeholder files are in: $DOCS_DIR/"
