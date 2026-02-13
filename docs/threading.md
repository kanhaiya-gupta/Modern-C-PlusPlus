# Threading

C++ provides **multithreading** in the standard library via `<thread>`, `<mutex>`, `<condition_variable>`, and related headers. You create threads, protect shared data with mutexes, and coordinate with condition variables or atomics. This document covers the basics: std::thread, mutexes, lock guards, and simple synchronization patterns.

---

## 1. std::thread

**std::thread** runs a callable (function, lambda, function object) in a new thread. The thread starts when the thread object is created.

```cpp
#include <thread>
#include <iostream>

void work() {
    std::cout << "Hello from thread\n";
}

int main() {
    std::thread t(work);
    t.join();  // wait for t to finish
}
```

- **join()**: block until the thread finishes; must call **join()** or **detach()** before the thread object is destroyed.
- **detach()**: let the thread run independently; you can no longer join it. Use only when the thread does not depend on the current scope.
- **joinable()**: true if the thread has not been joined or detached.

---

## 2. Passing arguments

Arguments are passed to the thread function by value (copied or moved) unless you use **std::ref** or **std::cref** to pass by reference.

```cpp
void f(int x, const std::string& s);
std::thread t(f, 42, "hello");  // copies 42 and "hello"

int n = 10;
std::thread t2(f, std::ref(n), "hi");  // t2's function sees reference to n
```

Be careful with references: the referred object must outlive the thread.

---

## 3. Mutexes — protecting shared data

A **mutex** (mutual exclusion) ensures only one thread at a time can execute a critical section. Lock before accessing shared data; unlock when done.

```cpp
#include <mutex>

std::mutex mtx;
int shared = 0;

void increment() {
    mtx.lock();
    ++shared;
    mtx.unlock();
}
```

Prefer **RAII** so you never forget to unlock: use **std::lock_guard** or **std::scoped_lock** (C++17).

---

## 4. std::lock_guard and std::scoped_lock

**std::lock_guard** locks a mutex in the constructor and unlocks it in the destructor. If you leave the scope (normally or by exception), the mutex is unlocked. See [RAII](raii.md).

```cpp
void safeIncrement() {
    std::lock_guard<std::mutex> lock(mtx);
    ++shared;
}  // unlock here
```

**std::scoped_lock** (C++17): same idea; can lock multiple mutexes at once without deadlock (uses deadlock-avoidance ordering).

```cpp
std::scoped_lock lock(mtx1, mtx2);
```

Never lock manually in application code when a guard will do.

---

## 5. std::unique_lock

**std::unique_lock** is more flexible than lock_guard: you can defer locking, unlock early, try_lock, and use it with **std::condition_variable** (which requires unique_lock).

```cpp
std::unique_lock<std::mutex> lock(mtx);
// ... use shared data ...
lock.unlock();  // optional: release early
// ...
lock.lock();    // relock if needed
```

Use when you need to pass the lock to a condition variable or need manual unlock/relock.

---

## 6. Condition variables

**std::condition_variable** lets one or more threads wait until another thread notifies them (e.g. “data is ready”). Always use with a mutex and a predicate to avoid spurious wakeups.

```cpp
#include <condition_variable>
#include <queue>

std::mutex mtx;
std::condition_variable cv;
std::queue<int> queue;
bool done = false;

void producer() {
    {
        std::lock_guard<std::mutex> lock(mtx);
        queue.push(42);
    }
    cv.notify_one();
}

void consumer() {
    std::unique_lock<std::mutex> lock(mtx);
    cv.wait(lock, [] { return !queue.empty() || done; });
    if (!queue.empty()) {
        int x = queue.front();
        queue.pop();
        // use x
    }
}
```

- **wait(lock, predicate)**: atomically unlocks, waits until notified, then re-locks and checks predicate; if false, waits again. Use a lambda that returns true when the condition is satisfied.
- **notify_one()** / **notify_all()**: wake one or all waiters.

---

## 7. std::atomic

For simple shared variables (e.g. counters, flags), **std::atomic&lt;T&gt;** avoids a mutex: operations are indivisible. Use for lock-free shared state when a single variable is enough.

```cpp
#include <atomic>
std::atomic<int> counter{0};
counter.fetch_add(1);
++counter;  // also atomic
```

Not all types are supported; integers and pointers are. For more complex shared state, use a mutex.

---

## 8. Guidelines

- Prefer **lock_guard** or **scoped_lock** over manual lock/unlock.
- Keep critical sections short; don’t do I/O or heavy work while holding a lock.
- Avoid deadlock: lock in a consistent order, or use **scoped_lock** for multiple mutexes.
- Use **condition_variable** with a **predicate** in wait() to handle spurious wakeups.
- Prefer **std::async** or higher-level libraries when you want “run this and get a result” rather than managing threads by hand.

---

## 9. Quick reference

| Item | Purpose |
|------|---------|
| std::thread | Create and run a thread; join() or detach() |
| std::mutex | Protect shared data; lock/unlock |
| std::lock_guard | RAII lock; single mutex |
| std::scoped_lock | RAII lock; one or more mutexes (C++17) |
| std::unique_lock | Flexible lock; required for condition_variable |
| std::condition_variable | Wait / notify between threads |
| std::atomic | Lock-free atomic variable |

---

## See also

- [RAII](raii.md) – lock_guard and scoped_lock
- [Lambdas](lambdas.md) – passing lambdas to threads
- [Coroutines](coroutines.md) – cooperative concurrency (C++20)
