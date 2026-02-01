# Plugin Ecosystem

Plugins are the primary way to extend Agent Scrutiny with domain-specific security analysis. The core Scrutinizer handles general threats (prompt injection, data exfiltration). Plugins handle everything else — smart contract security, healthcare compliance, financial transaction monitoring, and more.

---

## Why Plugins?

A security tool for AI agents cannot ship with domain expertise for every possible use case. Healthcare, finance, legal, smart contracts, IoT — each domain has its own threat landscape, its own regulatory requirements, and its own definition of "sensitive data."

Plugins let the community build and share that expertise. Each plugin is:

- **Isolated:** A buggy plugin cannot crash the Scrutinizer or affect other plugins.
- **Composable:** Multiple plugins run in the same evaluation pipeline. Their verdicts are aggregated.
- **Independently versioned:** Plugins ship on their own release cadence.
- **Language-agnostic in design:** The plugin specification defines a contract. Python and Rust implementations are independent.

---

## Plugin Categories

| Category | Purpose | Examples |
|---|---|---|
| **Threat Detectors** | Identify domain-specific threats | Smart contract reentrancy, SQL injection in agent-generated queries |
| **Context Analyzers** | Understand specialized scenarios | Financial transaction classification, medical record parsing |
| **Protocol Handlers** | Secure non-MCP communication channels | WebSocket security, gRPC security |
| **Policy Engines** | Enforce custom rules | HIPAA compliance, PCI-DSS checks, GDPR data handling |

---

## Plugin Lifecycle

Every plugin goes through the same lifecycle, managed by the Scrutinizer:

```
┌──────────┐     ┌────────────┐     ┌──────────┐     ┌──────────┐
│ Discover │ ──▶ │ Initialize │ ──▶ │ Evaluate │ ──▶ │ Shutdown │
└──────────┘     └────────────┘     └──────────┘     └──────────┘
   (find the        (load config,     (called once     (cleanup
    plugin)          set up resources) per interaction) resources)
```

- **Discover:** The plugin manager finds plugins — either explicitly loaded by the developer, or discovered via the plugin registry (Stage 2).
- **Initialize:** The plugin receives its configuration and sets up any resources it needs (database connections, model downloads, etc.). This happens once.
- **Evaluate:** The plugin's core logic runs. This is called for every agent interaction that the Scrutinizer processes. It must be fast.
- **Shutdown:** Called when the Scrutinizer is shutting down or the plugin is being unloaded. Resources are cleaned up.

---

## How Plugins Fit Into the Evaluation Pipeline

```
Input Validation  →  Core Detection  →  ┌─ Plugin A ─┐  →  Policy Enforcement
                                         ├─ Plugin B ─┤
                                         └─ Plugin C ─┘
                                         (run in parallel)
```

Plugin evaluations run *after* core detection and *before* policy enforcement. They run in parallel with each other (where possible) to minimize latency.

Each plugin returns a `PluginVerdict`. The Scrutinizer aggregates all plugin verdicts into the final `SecurityVerdict`. If *any* plugin flags a threat, the interaction is blocked (in strict mode).

---

## What's Available Now vs. Coming

| Feature | Stage |
|---|---|
| Plugin base class (interface definition) | 1 |
| Plugin manager (lifecycle orchestration) | 1 |
| Plugin registry (automatic discovery) | 2 |
| Plugin manifest specification (`plugin.yaml`) | 2 |
| First official plugin (smart-contract-security) | 2 |
| Plugin template generator | 2 |
| Plugin conformance test suite | 2 |
| Plugin chaining (output of one feeds into next) | 4 |

---

## Getting Started

- Want to **understand** the plugin contract? → [Plugin Specification](plugin-specification.md)
- Want to **build** a plugin? → [Creating a Plugin](creating-plugins.md)
- Want to **see** how official plugins are structured? → [Official Plugins](official/index.md)
