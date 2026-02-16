# Design of Analysis Pipelines

This document covers **how to design analysis pipelines** and **how to handle large data** in C++. It describes pipeline structure, patterns for streaming and partitioning, and several **concrete cases** (log processing, batch aggregation, ETL, and others) with implementation sketches. The ideas use [Ranges & Views](ranges-and-views.md), [Lazy Evaluation](lazy-evaluation.md), and [Coroutines](coroutines.md) where they fit.

---

## 1. What is an analysis pipeline?

An **analysis pipeline** is a sequence of stages: **source** → **transform(s)** → **sink**. Data flows through; each stage does one job (read, filter, aggregate, write). Design goals:

- **Composability**: stages are independent and reusable.
- **Streaming**: process in chunks or records so the full dataset need not fit in memory.
- **Testability**: test each stage on small or synthetic data.

In C++, pipelines can be built with **ranges/views** (lazy, in-memory), **coroutine generators** (lazy, pull-based), or **explicit iterators/chunks** over files or partitions.

---

## 2. Analysis of large data

When data is large, design so that:

- **Data is not all in memory**: read and process in **chunks** or **records**; write or aggregate incrementally.
- **Work is partitionable**: split by key, file, or time range so stages can run in parallel over partitions.
- **I/O is explicit**: abstract **sources** (file, stream, DB) and **sinks** so you can swap formats and add compression or push-down later.

### 2.1 Streaming by default

Prefer **pull-based** flow: the consumer asks for the next record or chunk. That gives natural backpressure and avoids unbounded buffers. Use:

- **Views** over a range (one element at a time when you iterate).
- **Generators** (`co_yield` one record or chunk per step).
- **Iterators** over a file or partition that read on demand.

Avoid APIs that force “load entire dataset” unless the problem truly needs it.

### 2.2 Chunking and partitioning

- **Chunk**: a fixed-size batch of records (e.g. 10 000 rows). Process one chunk at a time; release memory before the next. Use `std::views::chunk` (C++23) or a custom range that yields chunks.
- **Partition**: a subset of data by key (e.g. by user id, date, file). Each partition can be processed independently and in parallel. The pipeline runs once per partition or merges partition results in a reduce step.

### 2.3 Memory and resource control

- Make **chunk size** (or batch size) configurable so users can tune memory vs throughput.
- Prefer **move** when passing chunks between stages to avoid copies.
- Use **allocators** or buffer pools for hot paths if allocation overhead matters.

---

## 3. Pipeline building blocks

| Block | Role | Example |
|-------|------|--------|
| **Source** | Produces records or chunks | Read from file, iterate DB, generator that yields rows |
| **Transform** | Map, filter, project columns | `views::transform`, `views::filter`, custom functor |
| **Aggregate** | Reduce per key or globally | Running sum, group-by in a map, merge sorted streams |
| **Sink** | Consumes the stream | Write to file, insert into DB, return final container |

Stages can be **lazy** (views, generators) until a sink pulls data, or **eager** (process one chunk at a time and pass it on). For large data, keep the pipeline lazy or chunk-based so only a bounded amount of data is live.

---

## 4. Case 1: Log line processing (filter + transform)

**Goal:** Read a large log file, keep only lines containing `"ERROR"`, and write the result (e.g. timestamps) to another file. Data may not fit in memory.

**Design:** Source yields lines (or chunks of lines); one transform stage filters; another extracts the field; sink writes. Use a generator or iterator that reads the file in a streaming way.

**Sketch (conceptual):**

```cpp
// Conceptual: source yields lines one by one (e.g. from a generator or ifstream iterator).
// Stage 1: filter
auto error_lines = lines | std::views::filter([](const std::string& s) {
    return s.find("ERROR") != std::string::npos;
});
// Stage 2: transform (e.g. extract timestamp)
auto timestamps = error_lines | std::views::transform(extract_timestamp);
// Sink: write to file (iterate timestamps and write each)
for (const auto& ts : timestamps)
    out_file << ts << '\n';
```

For true streaming from disk, the “lines” range must be lazy (e.g. a custom range that reads line-by-line from `std::ifstream`), so that only one or a few lines are in memory at a time. See [Lazy Evaluation](lazy-evaluation.md).

---

## 5. Case 2: Batch aggregation (group-by sum)

**Goal:** Large stream of records `(key, value)`. Compute sum of `value` per `key`. Keys don’t fit in memory is not assumed; if they do, a single map is enough.

**Design:** One pass: for each record, add `value` to `agg[key]`. Use `std::unordered_map` or `std::map` for the aggregate. If the stream is too large to hold in memory, the “stream” is already chunked (e.g. from a file); we process chunk by chunk and merge aggregates (e.g. merge two maps by adding values for the same key).

**Sketch:**

```cpp
#include <unordered_map>
#include <vector>

using Record = std::pair<std::string, int>;

std::unordered_map<std::string, int> aggregate_by_key(
    std::ranges::input_range auto&& records) {
    std::unordered_map<std::string, int> sum_by_key;
    for (const auto& [key, value] : records)
        sum_by_key[key] += value;
    return sum_by_key;
}

// Merge two aggregates (for chunked processing)
void merge_aggregates(std::unordered_map<std::string, int>& target,
                      const std::unordered_map<std::string, int>& other) {
    for (const auto& [key, val] : other)
        target[key] += val;
}
```

If data comes in chunks (e.g. from a generator or multiple files), run `aggregate_by_key` on each chunk, then merge with `merge_aggregates` so only the (smaller) aggregate maps are kept in memory.

---

## 6. Case 3: ETL (extract – transform – load)

**Goal:** Read from a CSV (or binary), transform (clean, normalize, project columns), load into a database or another file. Data is large.

**Design:**  
- **Extract**: lazy source that yields rows (or chunks of rows).  
- **Transform**: pipeline of views or steps (filter invalid, map to target schema).  
- **Load**: sink that batches inserts (e.g. insert 1000 rows at a time) to limit memory and round-trips.

**Sketch:**

```cpp
// Extract: yield rows (e.g. from a generator reading CSV)
// Transform: filter + map to target type
auto valid_rows = raw_rows
    | std::views::filter([](const Row& r) { return r.valid(); })
    | std::views::transform([](const Row& r) { return to_target_schema(r); });

// Load: batch into DB (pseudo)
std::vector<TargetRow> batch;
const size_t batch_size = 1000;
for (auto&& row : valid_rows) {
    batch.push_back(std::move(row));
    if (batch.size() >= batch_size) {
        db_insert(batch);
        batch.clear();
    }
}
if (!batch.empty()) db_insert(batch);
```

The source can be a coroutine that `co_yield`s rows from a file so that only a bounded number of rows are in memory.

---

## 7. Case 4: In-memory analytics with views (small or medium data)

**Goal:** Filter, transform, and take the first N results from a vector (or any range). Data fits in memory; we want a clear, lazy pipeline.

**Design:** Use [Ranges & Views](ranges-and-views.md): filter → transform → take. No intermediate containers; elements are computed on demand.

```cpp
#include <ranges>
#include <vector>

std::vector<int> data = { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 };

auto result = data
    | std::views::filter([](int x) { return x % 2 == 0; })
    | std::views::transform([](int x) { return x * x; })
    | std::views::take(3);

for (int x : result)
    std::cout << x << ' ';  // 4 16 36
```

This is the same pipeline pattern; only the source is an in-memory range. For large data, replace `data` with a lazy source (generator or file iterator).

---

## 8. Case 5: Chunked processing with views (C++23)

**Goal:** Process a large range in fixed-size chunks (e.g. for batch writes or parallel work). Each chunk is processed then discarded.

**Design:** Use `std::views::chunk(n)` to get contiguous subranges. Process each chunk (e.g. aggregate, write, or send to a thread pool). Only one chunk is “active” at a time if you iterate sequentially.

```cpp
#include <ranges>
#include <vector>

void process_chunk(std::ranges::range auto&& chunk) {
    // e.g. aggregate, write to file, or dispatch to executor
}

std::vector<int> big_data = { /* ... */ };
const size_t chunk_size = 10000;

for (auto&& chunk : big_data | std::views::chunk(chunk_size))
    process_chunk(chunk);
```

If `big_data` itself is too large to hold, the source of the pipeline should be a generator or file-backed range that yields chunks; the same chunk-processing loop applies.

---

## 9. Case 6: Two-stage pipeline with generator (conceptual)

**Goal:** Simulate a pipeline where the source is a coroutine that yields records and the rest is done with views or a simple loop. Illustrates composition of a generator with downstream stages.

**Design:** Generator yields one record at a time; downstream filters/transforms with views; sink consumes. See [Coroutines](coroutines.md).

```cpp
// Conceptual: generator yields integers from somewhere (e.g. parsed from I/O).
// generator<int> read_records() {
//     for (;;) {
//         int x = read_one();  // from file, network, etc.
//         co_yield x;
//     }
// }

// Pipeline: generator -> filter -> take -> sink
// auto stream = read_records() | std::views::filter(is_valid) | std::views::take(1000);
// for (int x : stream) { process(x); }
```

In practice, you need a generator type that models a range (e.g. C++23 `std::generator`) or a custom iterator that pulls from the coroutine. The important point is the **design**: source yields lazily, rest is composed with views or a loop.

---

## 10. Case 7: Computer vision (frame pipeline)

**Goal:** Process video (camera or file): acquire frames, preprocess, run detection/segmentation/classification, then visualize or store results. Frames are the natural “chunk”; the pipeline is **source (frames) → transform(s) → sink**.

**Design:**  
- **Source**: produces one frame at a time (camera, video file, or directory of images). In C++ this is often a loop that reads from a **cv::VideoCapture** (OpenCV) or similar; each iteration yields one **cv::Mat** (or a custom frame type).  
- **Transform**: resize, normalize, color conversion, then model inference (e.g. object detection, segmentation). Stages can be separate (preprocess → infer → postprocess).  
- **Sink**: display (e.g. **cv::imshow**), write to video file, or push detections to another system.  

Frames are “large data” in the sense that you usually don’t load the whole video into memory; you stream frame-by-frame. Batch inference (process N frames together) is a chunked variant: source yields batches, transform runs the model on each batch, sink consumes results.

**Sketch (conceptual, OpenCV-style):**

```cpp
// Conceptual: source yields frames; pipeline runs per frame or per batch.
// #include <opencv2/core.hpp>
// #include <opencv2/videoio.hpp>

// Source: capture or video file
// cv::VideoCapture cap(0);  // or cap.open("video.mp4");
// cv::Mat frame;
// while (cap.read(frame)) {
//     // Transform: preprocess (resize, normalize, to blob)
//     cv::Mat blob = preprocess(frame);
//     // Transform: inference (e.g. DNN, custom model)
//     auto detections = run_detector(blob);
//     // Sink: draw and show, or write
//     draw_and_show(frame, detections);
// }
```

**Pipeline fit:**  
- **Streaming**: one frame (or a small batch) at a time; no need to hold the entire video.  
- **Stages**: capture → preprocess → infer → postprocess → output; each stage can be a function or a small module.  
- **C++**: Use **cv::Mat** or a thin wrapper; avoid unnecessary copies (pass by reference, move when handing off). For throughput, overlap I/O and compute (e.g. double-buffer or a producer–consumer queue). Libraries like **OpenCV** provide the source/sink and primitives; your pipeline composes them.

Computer vision in C++ is thus another **case** of the same analysis-pipeline design: a clear source of “records” (frames), composable transforms, and a sink, with streaming (frame-by-frame or batch-by-batch) so it scales to long videos or live streams.

---

## 11. Case 8: Plugins for host applications (Think-Cell–style)

**Goal:** Build a plugin or add-in for a host application (e.g. PowerPoint, Excel, a design tool): read data or events from the host, run your own logic (charts, tables, layout, analysis), and write results back into the document or UI. The host is both **source** (data/selection/events) and **sink** (updated slides, cells, shapes).

**Design:**  
- **Source**: the host exposes data and events—selected cells, current slide, document model, or user actions. Your plugin subscribes or is called by the host; each “tick” (e.g. selection change, data change, menu click) is an input. You may get ranges of data (e.g. a table) that you treat as a small stream or a single chunk.  
- **Transform**: your C++ logic—aggregate, recompute chart data, run a layout algorithm, format tables, or run a small analysis. This is the pipeline’s core; it should be **host-agnostic** where possible (plain C++ and STL) so it’s testable and reusable.  
- **Sink**: push results back into the host—update chart series, insert or format shapes, write to cells, refresh a pane. The host API (COM, JavaScript bridge, or native SDK) is the sink interface.

**Think-Cell–style tasks:** Data-driven charts and tables in presentations or spreadsheets: “here is the data (source), compute series/labels/positioning (transform), draw/update the chart (sink).” The same pipeline applies to conditional formatting, smart tables, or layout helpers—read from host, transform, write back.

**Sketch (conceptual):**

```cpp
// Conceptual: host calls into plugin; plugin treats host as source + sink.

// 1) Source: get current data from host (e.g. selected range, document model)
//    HostData data = host_get_selection();  // or host_get_chart_data(), etc.

// 2) Transform: pure C++ / STL — compute what to show
//    std::vector<Series> series = compute_series(data.values);
//    auto layout   = compute_layout(series);
//    auto labels   = generate_labels(series);

// 3) Sink: push back to host (update chart, insert shapes, set cells)
//    host_update_chart(series);
//    host_apply_layout(layout);
//    host_set_labels(labels);
```

**Pipeline fit:**  
- **Clear boundaries**: source = host adapter (thin layer that maps host types to your internal types); transform = your logic; sink = host adapter that maps your types to host API calls.  
- **Testability**: run the transform stage on synthetic or saved host data without the host; only the adapters depend on the host.  
- **C++**: Keep the transform stage in standard C++ (containers, algorithms, ranges); use the host’s C++ API or COM/IDL only at source/sink boundaries. That keeps the “analysis pipeline” portable and easier to maintain.

Plugins for host applications are thus another **case**: the host is the source of data and events and the sink for results; your plugin is the pipeline in between, with a host-agnostic transform at the core.

### What you need to know for plugin development

| Area | What to know |
|------|----------------|
| **Host API** | How the host exposes data and commands: object model (e.g. Application → Workbook → Range), events (selection change, document open), and how to write back (set cells, insert shapes). Often COM/IDL (Windows) or a native C++ SDK; sometimes JavaScript/Add-in API. |
| **Lifecycle** | Load/unload: when the host loads your DLL/add-in, what it calls (e.g. `DllMain`, exported init, or manifest-based). Cleanup on unload (release references, stop threads, flush state). |
| **Threading** | Which host APIs must be called on the main/UI thread (most do). Offload heavy work to a worker; marshal results back to the main thread before calling the host. Avoid blocking the host’s message loop. |
| **ABI and binary compatibility** | Same compiler/toolchain and runtime as the host (or follow the host’s specified ABI). Avoid passing STL types across DLL boundaries unless the host explicitly supports it; use C-style or COM types at the boundary. |
| **Packaging and deployment** | How the host discovers and loads the plugin (registry, manifest, add-in directory, store). Signing, versioning, and install/update flow. |
| **Error handling** | How to report failures to the user without crashing the host. Catch exceptions at the boundary; use the host’s logging or message API if available. |
| **Testing** | Unit-test your transform logic with fake or recorded host data. Integration tests with the real host (automation or UI) for source/sink and lifecycle. |
| **Documentation** | Host’s plugin/API docs, supported platforms, and deprecation policy so you know what you can rely on across versions. |

---

## 12. Case 9: Audio / signal processing

**Goal:** Process a stream of audio samples (live or file): read buffers, apply filters or effects, then play or write. Data is continuous; processing is in fixed-size buffers (chunks).

**Design:**  
- **Source**: yields buffers of samples (e.g. from file, microphone, or generator). Each buffer is a chunk (e.g. 1024 or 4096 samples).  
- **Transform**: apply gain, filter, FFT, resample, or other DSP; can be a chain (filter → effect → normalize).  
- **Sink**: send buffer to audio device or write to file. For real-time, sink must not block; use double-buffering or a lock-free queue so the source keeps producing.

**Pipeline fit:** Same pattern—source → transform → sink. Chunk = buffer; streaming by design. C++ is common for low-latency DSP; keep transform in plain C++ and put I/O (device, file) in source/sink adapters.

---

## 13. Case 10: Message / event streaming

**Goal:** Consume messages from a broker or queue (e.g. Kafka, RabbitMQ), transform or aggregate, then produce to another topic or write to a store. High throughput; messages are the natural “record.”

**Design:**  
- **Source**: consumer that yields messages (or batches). Often pull-based; backpressure is natural if you don’t poll faster than you process.  
- **Transform**: parse, filter, enrich, aggregate by key, or window (e.g. last 5 minutes). Can be stateless (per message) or stateful (windows, sessions).  
- **Sink**: produce to another topic, write to DB, or update a cache. Batching at the sink reduces round-trips.

**Pipeline fit:** Classic streaming pipeline. Partition by message key for parallelism. C++ used where latency and throughput matter; same idea as log processing but with explicit message boundaries and often exactly-once or at-least-once semantics.

---

## 14. Case 11: Compiler / tooling passes

**Goal:** A compiler or static analyzer: read source (or tokens, or AST), run a sequence of passes (parse, analyze, transform, optimize, codegen), emit object code or reports. Each pass is a stage; data is the program representation.

**Design:**  
- **Source**: file(s) or stream of tokens; or a single AST after parsing.  
- **Transform**: pipeline of passes—e.g. parse → name resolution → type check → optimize → codegen. Each pass reads the current IR and produces the next; can be lazy (pass N+1 pulls from pass N) or eager (materialize after each pass).  
- **Sink**: object file, assembly, or diagnostic report.

**Pipeline fit:** Source → transform₁ → … → transformₙ → sink. “Large data” can mean a large AST or many translation units; streaming or chunking by file/module keeps memory bounded. C++ compilers (e.g. Clang) use this pass-based design.

---

## 15. Case 12: Real-time metrics / time windows

**Goal:** Ingest a stream of events (logs, metrics, clicks), aggregate over sliding or tumbling time windows (e.g. count per minute, P99 latency), then update a dashboard or store. Results are produced continuously as windows close.

**Design:**  
- **Source**: event stream (from log tail, metrics agent, or message queue). Events have a timestamp.  
- **Transform**: assign event to window(s), update per-window state (count, sum, histogram); when a window closes, emit the aggregate. Stateful; one aggregate state per key and window.  
- **Sink**: push to dashboard, time-series DB, or alerting. Often batched (e.g. flush every second).

**Pipeline fit:** Source streams events; transform is stateful (windows); sink consumes aggregates. Chunking by time or by key keeps state and I/O bounded. Same pipeline idea as batch aggregation but with time as the partition dimension.

---

## 16. Case 13: Game loop / simulation

**Goal:** Each frame (tick): read entity/event state, run physics and AI, update rendering, then output the frame. A **tick-based pipeline**: source = current world state (or event queue), transform = physics → AI → render prep, sink = frame to display or to a replay buffer.

**Design:**  
- **Source**: entity list, event queue, or delta since last tick. Yields “current state” or a stream of events to process this frame.  
- **Transform**: stages in order—e.g. input → physics → collision → AI → animation → render (build draw list). Each stage reads and writes shared or staged data; order matters for correctness.  
- **Sink**: submit frame to GPU, write to replay, or send to network. Often fixed rate (e.g. 60 Hz); sink must not block so the next tick starts on time.

**Pipeline fit:** Same source → transform → sink. “Chunk” = one frame’s worth of work. C++ is standard for games; pipeline is often explicit (update loop with clear phases). Parallelism within a stage (e.g. many entities) is common; keep stages composable so you can add or reorder systems.

---

## 17. Case 14: Image batch jobs

**Goal:** Process a folder (or list) of images: resize, convert format, add watermark or metadata, then write to an output folder. **Batch ETL for media**: no need to hold all images in memory; process one or a few at a time.

**Design:**  
- **Source**: enumerate files (directory walk, manifest, or list); yield one image path or load one image at a time. Can partition by subfolder or batch size for parallelism.  
- **Transform**: load image → resize/convert/watermark (e.g. with OpenCV, ImageMagick, or a graphics lib); output is a buffer or a new image in memory.  
- **Sink**: write to output path (same name in output dir, or new naming scheme). Optionally upload to storage or enqueue for next stage.

**Pipeline fit:** Source yields paths or images; transform is per-image; sink writes. Chunk = one image or a small batch of images to limit memory. Same pattern as ETL or log processing but with binary blobs and often CPU/GPU-heavy transform. Good candidate for parallel workers (each handles a subset of files).

---

## 18. Case 15: DB replication / CDC

**Goal:** Capture changes from a database (change data capture, CDC) and replicate or sync to another store (replica DB, cache, search index, or data lake). **Change stream** is the source; filter/transform then apply to sink.

**Design:**  
- **Source**: stream of change events (insert/update/delete), typically from a transaction log or CDC connector. Each event has table, key, old/new values, and often timestamp.  
- **Transform**: filter (e.g. only certain tables or columns), mask PII, reshape for target schema, or aggregate (e.g. dedupe by key within a window). Can be stateless or stateful.  
- **Sink**: apply changes to replica (apply event), update cache, index in search, or write to object storage. Ordering and exactly-once semantics matter; often key-based partitioning so per-key order is preserved.

**Pipeline fit:** Source = change stream; transform = filter/transform; sink = apply to target. “Large data” is the unbounded stream; process in batches or by partition for throughput. C++ used in high-throughput replication or custom CDC tools; same pipeline idea as message streaming with a DB-specific source and sink.

---

## 19. Summary

| Concern | Recommendation |
|--------|-----------------|
| **Large data** | Stream or chunk; avoid loading everything. |
| **Pipeline design** | Source → transform(s) → sink; keep stages composable. |
| **Memory** | Lazy views, generators, chunked iteration; configurable batch size. |
| **Parallelism** | Partition by key/file; process partitions independently; merge aggregates. |
| **C++ tools** | Ranges/views for lazy in-memory pipelines; coroutines for lazy I/O and generators; chunk views or custom ranges for batch processing. |

Different **cases** (log processing, group-by sum, ETL, in-memory analytics, chunked processing, generator-based pipeline, computer vision, plugins for host applications, audio/signal processing, message/event streaming, compiler/tooling passes, real-time metrics, game loop/simulation, image batch jobs, DB replication/CDC) are variations of the same pipeline idea: define a clear source, one or more transforms, and a sink; keep data flow streaming or chunk-based (or event-driven) so the design scales and stays testable.

---

## See also

- [Ranges & Views](ranges-and-views.md) – range algorithms and views
- [Lazy Evaluation](lazy-evaluation.md) – lazy views and generators
- [Coroutines](coroutines.md) – generators and async
- [Containers](containers.md), [STL Containers](stl-containers.md) – choice of containers for aggregates and buffers
- [Vector Reference](vector-reference.md) – chunk storage and multi-dimensional data
