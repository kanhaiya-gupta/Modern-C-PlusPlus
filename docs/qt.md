# Qt

**Qt** is a cross-platform C++ framework for GUI applications, networking, I/O, and more. It extends C++ with its own object model (**QObject**), **signals and slots** for communication, and many GUI and utility classes. This document gives a short overview of Qt-specific concepts and how they relate to standard C++. For full Qt docs see [qt.io](https://doc.qt.io/).

---

## 1. What Qt adds to C++

- **QObject and the meta-object system** — Base class for objects that support signals, slots, properties, and introspection. The **moc** (Meta-Object Compiler) generates extra code from your headers.
- **Signals and slots** — Decoupled communication between objects: one object **emits** a signal; zero or more **slots** (functions) are called. No direct coupling between sender and receiver.
- **Widgets and GUI** — **QWidget**, **QMainWindow**, layouts, and a large set of controls for desktop UIs.
- **Qt containers and types** — **QString**, **QVector**, **QMap**, etc., that work well with Qt APIs and across the framework. You can mix them with **std::** types where it makes sense.
- **Build system** — Qt projects typically use **qmake** or **CMake** with Qt modules; **moc**, **uic**, and **rcc** run on your sources and resources.

Qt is a **framework**: it expects you to use its base classes and build system; then you get signals/slots, internationalization, and a consistent API across platforms.

---

## 2. QObject and signals/slots

Classes that use signals or slots must **inherit QObject** and list them in a **Q_OBJECT**-enabled section. The **moc** parses the header and generates the glue code.

```cpp
#include <QObject>

class Counter : public QObject {
    Q_OBJECT
public:
    explicit Counter(QObject* parent = nullptr) : QObject(parent) {}
    void setValue(int value);

signals:
    void valueChanged(int newValue);

public slots:
    void increment();

private:
    int value_ = 0;
};
```

- **signals:** Declare events the object can emit; you don’t implement them (moc does).
- **slots:** Normal member functions that can be connected to signals. Mark with **slots** (or **public slots**, etc.) for clarity.
- **Connect:** **QObject::connect(sender, &Sender::signal, receiver, &Receiver::slot)** so that when **sender** emits **signal**, **receiver->slot(...)** is called.

This is **event-driven** and **decoupled**: the sender doesn’t hold a list of callbacks; Qt’s runtime dispatches to all connected slots.

---

## 3. Qt types and standard C++

- **QString** — Unicode string; use **.toStdString()** when you need **std::string**; construct **QString** from **std::string** or **const char*** when calling Qt APIs.
- **QVector**, **QList**, **QMap**, **QHash** — Qt containers. Prefer **std::** containers in new code unless you’re passing data into Qt APIs that expect Qt types.
- **Smart pointers** — Prefer **std::unique_ptr** / **std::shared_ptr** for ownership. Qt’s **parent–child** ownership (QObject tree) is another model: deleting a parent deletes its children. Mix with care: don’t double-own.

You can use standard C++ (including [Smart pointers](smart-pointers.md), [RAII](raii.md)) inside your Qt project; use Qt types where the API or the framework requires them.

---

## 4. Parent–child ownership (QObject)

**QObject** can have a **parent**. When the parent is destroyed, Qt deletes all its children. So you often create widgets with a parent and **don’t** store them in smart pointers—ownership is by the parent.

```cpp
QWidget* window = new QWidget;
QPushButton* button = new QPushButton("Click", window);  // parent = window
// When window is deleted, button is deleted too. No need for delete button;
```

This is different from **std::unique_ptr** ownership; both are valid. Don’t give the same object a Qt parent and a **unique_ptr** owner.

---

## 5. Build and tooling

- **qmake** — Qt’s own build generator (**.pro** files).
- **CMake** — Use **find_package(Qt6 ...)** (or Qt5) and **target_link_libraries(... Qt::Widgets)** etc.; enable **AUTOMOC**, **AUTOUIC**, **AUTORCC** so **moc**/uic/rcc run automatically.
- **moc** — Must run on headers that contain **Q_OBJECT**, signals, or slots; the build system usually handles this.

You need the Qt libraries and the meta-object compiler in your build environment; the exact setup depends on your OS and how you installed Qt.

---

## 6. Quick reference

| Concept | Notes |
|--------|--------|
| QObject | Base for classes with signals, slots, parent–child |
| Signals / slots | Declare in class; connect with **QObject::connect** |
| Parent–child | Parent owns children; no **delete** on children when using parents |
| QString / Qt containers | Use where Qt API expects them; convert to/from **std::** as needed |
| Build | qmake or CMake; **moc** for Q_OBJECT/signals/slots |

---

## See also

- [Class](class.md) – C++ classes and inheritance (Qt classes build on this)
- [Smart pointers](smart-pointers.md) – ownership in standard C++
- [RAII](raii.md) – resource management; Qt parent–child is an alternative ownership model
- [Qt documentation](https://doc.qt.io/) – official reference and guides
