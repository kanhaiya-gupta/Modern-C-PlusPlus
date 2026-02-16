# QML

**QML** (Qt Modeling Language) is Qt’s declarative language for building fluid UIs. You describe the interface in **.qml** files (syntax similar to JSON/JavaScript), and Qt Quick renders it. QML is often used with **C++** for logic and performance-critical code, and with **Qt** for the application shell. This document gives a short overview of QML and how it connects to C++ and Qt. For full docs see [Qt QML](https://doc.qt.io/qt-6/qtqml-index.html) and [Qt Quick](https://doc.qt.io/qt-6/qtquick-index.html).

---

## 1. What is QML?

- **Declarative** — You describe *what* the UI looks like and how it reacts (properties, bindings, handlers), not step-by-step imperative code.
- **Qt Quick** — The runtime that loads QML, renders the scene graph, and handles input. You use **QQuickView** or **QML** engine from C++ to show QML.
- **JavaScript-like** — Expressions, property bindings, and signal handlers in QML can use a JavaScript-like syntax. Full JavaScript is available for scripted logic inside QML.
- **Integration with C++** — You expose C++ **QObject**-derived types to QML as **QML types** so QML can call slots, read properties, and connect to signals. You can also call into QML from C++.

QML is typically used for **touch-friendly**, **animated** UIs (mobile, embedded, desktop); **Qt Widgets** remains an option for traditional desktop UIs. See [Qt](qt.md).

---

## 2. Basic QML syntax

A **.qml** file defines a **type** (often a visual item). You use **id** to refer to an item, **properties** for data, and **signal handlers** for input.

```qml
import QtQuick
import QtQuick.Controls

Rectangle {
    id: root
    width: 200
    height: 100
    color: "steelblue"

    Text {
        anchors.centerIn: parent
        text: "Hello QML"
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.color = "coral"
    }
}
```

- **Rectangle**, **Text**, **MouseArea** — Built-in Qt Quick types.
- **id** — Name for this instance (e.g. **root**); used in bindings and handlers.
- **Properties** — **width**, **height**, **color**, **text**; can be bound to expressions so they update automatically.
- **onClicked** — Signal handler; runs when the **MouseArea** is clicked.

---

## 3. Properties and bindings

Properties can be **bound** to expressions. When dependencies change, the property updates automatically (reactive).

```qml
Rectangle {
    width: 100
    height: width * 2   // binding: height follows width
    color: pressed ? "red" : "gray"
}
```

You can define **custom properties** with **property *type* *name***. **var** holds any type; for C++ integration you often use **real**, **int**, **string**, or a **QObject**-derived type registered with the QML engine.

---

## 4. Signals and slots (in QML)

QML types can have **signals** (like C++ Qt signals). You **emit** them and connect to **handlers** (on*SignalName*) or use **Connections** or **connect** in script.

```qml
// In a custom type or item
signal buttonClicked(string label)

MouseArea {
    onClicked: buttonClicked("Submit")
}
```

Handlers in a parent or another item: **onButtonClicked: { ... }**. This mirrors the Qt C++ signals/slots model. See [Qt](qt.md).

---

## 5. Exposing C++ to QML

To use C++ logic and data in QML:

- **Register a type** — **qmlRegisterType&lt;MyClass&gt;(...)** or **setContextProperty** so QML can create or access the C++ object.
- **QObject-derived class** — Expose **properties** (Q_PROPERTY), **public slots**, and **signals**. QML can read/write properties, call slots, and connect to signals.
- **Engine and root context** — **QQmlApplicationEngine** (or **QQuickView**) loads the main .qml; the **root context** can expose a C++ object as a **context property** so the QML root can reference it.

```cpp
// C++: register type or set context property
engine.rootContext()->setContextProperty("backend", myBackend);
```

```qml
// QML: use it
Text { text: backend.status }
Button { onClicked: backend.doWork() }
```

---

## 6. Loading QML from C++

Use **QQmlApplicationEngine** to load a main QML file as the UI; or **QQuickView** if you need a **QWindow**. The engine loads **.qml** files, resolves imports, and creates the object tree. You typically set a **QUrl** to the main .qml (e.g. from the resource system or a path).

```cpp
QQmlApplicationEngine engine;
engine.load(QUrl(QStringLiteral("qrc:/main.qml")));
```

Resources (**qrc**) are the usual way to ship QML and assets with the app.

---

## 7. Quick reference

| Topic | Notes |
|-------|--------|
| QML | Declarative UI language; .qml files; Qt Quick runtime |
| Properties / bindings | Reactive updates when dependencies change |
| Signals / handlers | on*SignalName*; signal/handler model like Qt C++ |
| C++ ↔ QML | Register types or set context property; QObject props/slots/signals |
| Load QML | QQmlApplicationEngine or QQuickView; often from qrc |

---

## See also

- [Qt](qt.md) – QObject, signals/slots, parent–child, Qt types
- [Qt QML](https://doc.qt.io/qt-6/qtqml-index.html) – QML language and engine
- [Qt Quick](https://doc.qt.io/qt-6/qtquick-index.html) – Qt Quick types and scene graph
