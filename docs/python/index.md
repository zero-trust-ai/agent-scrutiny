# Python SDK

The Python SDK (`agent-scrutiny-python`) is the **reference implementation** of Agent Scrutiny. It is designed for clarity, modularity, and learnability — making it the right starting point for anyone building with or contributing to Agent Scrutiny.

---

## Current Status

The Python SDK is in **Stage 0**. The package structure is in place and the placeholder test suite passes. The Scrutinizer core, detectors, and plugin system will be implemented starting in Stage 1.

What you can do right now:

- Install the package and run the existing tests.
- Read the planned API in `examples/basic_usage.py`.
- Study the [Architecture](../architecture.md) and [Plugin Specification](../plugins/plugin-specification.md) to prepare contributions.

---

## How It Relates to the Hub

The Python SDK does **not** own any shared documentation. All architecture decisions, threat definitions, and the plugin specification live in this hub repository (`agent-scrutiny`). The Python SDK implements those specs.

If you find a discrepancy between the Python SDK's behavior and what this documentation describes, the documentation is authoritative. Open an issue against the hub.

---

## SDK Structure

```
agent-scrutiny-python/
├── src/agent_scrutiny/
│   ├── __init__.py              # Package entry point
│   ├── core.py                  # Scrutinizer class                  (Stage 1)
│   ├── detectors/               # Threat detectors                   (Stage 1)
│   ├── policies/                # Policy engine                      (Stage 1)
│   ├── monitors/                # Behavioral monitoring              (Stage 1)
│   ├── plugins/                 # Plugin system                      (Stage 1–2)
│   │   ├── base.py              # Plugin interface
│   │   ├── manager.py           # Plugin lifecycle
│   │   ├── registry.py          # Plugin discovery                   (Stage 2)
│   │   └── official/            # Bundled official plugins           (Stage 2)
│   ├── mcp/                     # MCP security layer                 (Stage 2)
│   ├── rag/                     # RAG policy engine                  (Stage 3)
│   ├── multi_agent/             # Multi-agent security               (Stage 4)
│   └── utils/                   # Shared utilities
├── tests/                       # pytest test suite
└── examples/                    # Working code examples
```

---

## Key Design Decisions

**Pydantic for all data models.** Every request, response, verdict, and configuration object is a Pydantic model. This gives us runtime validation, automatic serialization, and clear API contracts with no extra work.

**structlog for logging.** All security events are logged as structured JSON. This makes the logs consumable by downstream SIEM and monitoring tools without post-processing.

**asyncio-native.** The evaluation pipeline is designed to run asynchronously. Plugin evaluations can run in parallel where they don't depend on each other, keeping latency low even with many plugins active.

**No LLM dependency in the core.** The Scrutinizer itself does not call any language model. It is a deterministic evaluation engine. LLM-based analysis is available through plugins (Stage 2+) and the RAG policy engine (Stage 3), but the core pipeline has zero inference cost.