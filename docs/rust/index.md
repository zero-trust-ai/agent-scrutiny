# Rust SDK

The Rust SDK (`agent-scrutiny-rust`) is the **production-grade implementation** of Agent Scrutiny. It implements the same [Plugin Specification](../plugins/plugin-specification.md) and is governed by the same [Threat Model](../threat-model.md) as the Python SDK — but it is optimized for throughput, latency, and memory efficiency.

---

## When to Use Rust vs. Python

| Use Case | Recommended SDK |
|---|---|
| Learning Agent Scrutiny | Python |
| Prototyping security policies | Python |
| Contributing to the project | Python (reference implementation) |
| Production deployment at scale | **Rust** |
| High-throughput agent workloads (1000+ eval/sec) | **Rust** |
| Embedding in a larger Rust application | **Rust** |
| Edge or resource-constrained deployment | **Rust** |

---

## Current Status

The Rust SDK is in **Stage 0** — planning and design. The repository structure and build configuration will be established in parallel with the Python SDK's Stage 1 work. The Rust implementation follows the Python reference but does not need to ship simultaneously at every stage.

---

## Performance Targets

| Metric | Target |
|---|---|
| Single-interaction evaluation latency | < 1ms (without plugin I/O) |
| Throughput | 10,000+ evaluations/second (single core) |
| Memory per Scrutinizer instance | < 10 MB baseline |
| Plugin evaluation overhead | < 0.1ms per plugin (without external calls) |

---

## Design Philosophy

- **Zero-cost abstractions.** The plugin trait and evaluation pipeline are designed so that the compiler can inline and optimize the hot path with no runtime overhead.
- **No runtime dependency on Python.** The Rust SDK is fully self-contained. It does not call into the Python SDK or require a Python interpreter.
- **Same contracts, different implementation.** The plugin interface in Rust is a trait that mirrors the Python abstract base class. A plugin author who understands one can write the other.
- **Structured logging from day one.** All security events are emitted as structured traces via the `tracing` crate, compatible with OpenTelemetry collectors.

---

## Planned Crate Structure

```
agent-scrutiny-rust/
├── Cargo.toml                          # Workspace manifest
├── crates/
│   ├── scrutiny-core/                  # Scrutinizer engine + evaluation loop
│   ├── scrutiny-detectors/             # Core threat detectors
│   ├── scrutiny-plugins/               # Plugin trait + manager
│   ├── scrutiny-mcp/                   # MCP security layer
│   ├── scrutiny-rag/                   # RAG policy engine bindings
│   └── scrutiny-cli/                   # Command-line interface
├── plugins/                            # Official Rust plugins
│   └── smart-contract/
└── examples/                           # Usage examples
```

The workspace layout allows each crate to be versioned and published independently. Users can depend on only the crates they need.
