# Architecture

> **Status:** Stage 0 — Design phase. Components marked with *(Stage N)* are implemented in that stage.

This document is the single source of truth for Agent Scrutiny's system architecture. Both the Python and Rust SDKs implement this design.

---

## Guiding Principles

Every architectural decision traces back to one of these:

1. **Verify every interaction** — no implicit trust between any two components.
2. **Assume breach** — design so the system stays secure when individual components are compromised.
3. **Least privilege** — each component gets only the access it needs.
4. **Continuous monitoring** — real-time observation of all agent activity.
5. **Context-aware security** — policies are applied dynamically based on what's actually happening.
6. **Modular by design** — security capabilities are isolated, composable units (plugins).

---

## High-Level Component Map

```
┌──────────────────────────────────────────────────────────────┐
│                        Agent Interaction                        │
│          (user → agent, agent → agent, agent → API)            │
└────────────────────────────┬─────────────────────────────────┘
                             │
                             ▼
┌──────────────────────────────────────────────────────────────┐
│                   Scrutinizer Evaluation Layer                  │
│                                                                │
│   ┌────────────────┐                                           │
│   │ Input          │  *(Stage 1)*  Sanitize & validate         │
│   │ Validation     │               all incoming data.          │
│   └───────┬────────┘                                           │
│           ▼                                                    │
│   ┌────────────────┐                                           │
│   │ Core Threat    │  *(Stage 1)*  Pattern-based detection     │
│   │ Detection      │               (prompt injection, etc.).   │
│   └───────┬────────┘                                           │
│           ▼                                                    │
│   ┌────────────────────────────────────┐                       │
│   │ Plugin Evaluation Pipeline         │  *(Stage 1–2)*        │
│   │  ┌─────────┐ ┌─────────┐ ┌──────┐ │  Each plugin runs     │
│   │  │Plugin A │ │Plugin B │ │ ...  │ │  in its own isolated  │
│   │  └─────────┘ └─────────┘ └──────┘ │  security boundary.   │
│   └───────┬────────────────────────────┘                       │
│           ▼                                                    │
│   ┌────────────────┐                                           │
│   │ Policy         │  *(Stage 1–3)*  Enforce rules. In Stage   │
│   │ Enforcement    │               3, policies are retrieved   │
│   └───────┬────────┘               dynamically via RAG.       │
│           ▼                                                    │
│   ┌────────────────┐                                           │
│   │ Security       │  Aggregates all signals into a single     │
│   │ Verdict        │  verdict with an explanation.             │
│   └────────────────┘                                           │
│                                                                │
│   ┌─────────────────────────────────┐                          │
│   │ Monitoring & Audit              │  *(Stage 1+)*            │
│   │ Structured logs · Alerts · Trail│  Runs in parallel;       │
│   └─────────────────────────────────┘  never bypassed.         │
└──────────────────────────────────────────────────────────────┘
```

---

## Component Detail

### Scrutinizer Core *(Stage 1)*

The central orchestrator. It receives an agent interaction (input, output, context), routes it through the evaluation pipeline, and returns a `SecurityVerdict`. It never executes agent logic itself — it only *observes and judges*.

### Detection Layer *(Stage 1)*

A set of specialized detectors, each targeting a specific threat class:

| Detector | Threat | Stage |
|---|---|---|
| `PromptInjectionDetector` | Instruction hijacking in inputs | 1 |
| `InputValidator` | Malformed or out-of-spec data | 1 |
| `DataExfiltrationDetector` | Sensitive data leaking in outputs | 1 |
| `BehaviorAnomalyDetector` | Deviation from expected agent patterns | 4 |

Domain-specific detection is handled by **plugins**, not by adding more detectors to this layer.

### Plugin System *(Stage 1–2)*

Plugins are the primary extension mechanism. The plugin interface is a formal contract — see [Plugin Specification](plugins/plugin-specification.md). Every plugin follows the same lifecycle:

```
Discover  →  Initialize  →  Evaluate (per interaction)  →  Shutdown
```

Plugins are **isolated security boundaries**. A crashing or misbehaving plugin cannot bring down the Scrutinizer or affect other plugins.

### Policy Engine *(Stage 1–3)*

Manages the rules that govern what is and isn't allowed. In Stage 1, policies are static configuration. In Stage 3, a RAG layer retrieves and applies policies dynamically from a knowledge base, allowing updates without code changes.

### MCP Security Layer *(Stage 2)*

Secures communications that use the Model Context Protocol. Responsibilities:

- Parse and validate MCP messages
- Verify agent identity and authorization
- Enforce trust boundaries between agents
- Detect MCP-specific attack patterns (e.g., message tampering, unauthorized delegation)

### Multi-Agent Orchestration *(Stage 4)*

Extends the Scrutinizer to reason across multiple agents simultaneously:

- Behavior profiling per agent over time
- Anomaly detection that spans agent boundaries
- Reputation scoring and trust decay
- Coordinated attack detection

---

## Trust Zones

All components operate within one of three trust zones:

| Zone | Description | Examples |
|---|---|---|
| **Untrusted** | External inputs, unknown agents, unverified messages | User input, external API responses |
| **Evaluation** | Scrutinizer internals — not trusted by definition, but isolated | Detectors, plugins, policy engine |
| **Trusted** | Output of the Scrutinizer after a positive verdict | Verified agent responses ready for delivery |

Nothing moves from Untrusted to Trusted without passing through Evaluation.

---

## Data Flow — Single Interaction

```
Agent Input
    │
    ▼
Input Validation ─── (fail) ──→ Verdict: BLOCKED
    │
    ▼ (pass)
Core Threat Detection ─── (threat found) ──→ Verdict: BLOCKED
    │
    ▼ (clean)
Plugin Evaluation Pipeline ─── (any plugin flags) ──→ Verdict: BLOCKED
    │
    ▼ (all clear)
Policy Enforcement ─── (policy violation) ──→ Verdict: BLOCKED
    │
    ▼ (compliant)
Verdict: SAFE  ←──────────────────────────────────────────
```

At every stage, the Monitoring & Audit layer records what happened and why. The verdict always includes an explanation — this is the **Explainable Security** principle in action.

---

## Technology Stack

### Shared (both SDKs)

| Concern | Choice | Rationale |
|---|---|---|
| Plugin contract | Formal interface spec | Language-agnostic; both SDKs implement it |
| Config format | YAML | Human-readable, widely understood |
| Logging format | Structured JSON | Machine-parseable for downstream SIEM integration |

### Python SDK

| Concern | Choice |
|---|---|
| Language | Python 3.9+ |
| Data validation | Pydantic v2 |
| Logging | structlog |
| Cryptography | `cryptography` library |
| Config | PyYAML |
| Async | asyncio |

### Rust SDK

| Concern | Choice |
|---|---|
| Language | Rust (edition 2021+) |
| Data validation | serde + custom validation |
| Logging | tracing |
| Cryptography | `ring` |
| Config | serde_yaml |
| Async | tokio |

### Future (Stage 3+)

| Concern | Candidates |
|---|---|
| Vector DB (RAG) | ChromaDB, Pinecone, pgvector |
| Embeddings | Sentence Transformers, OpenAI embeddings |
| Deployment | Docker, Kubernetes, Terraform |
| Observability | Prometheus + Grafana |

---

## Evolution by Stage

| Stage | What changes architecturally |
|---|---|
| 0 | This document. Design only. |
| 1 | Core pipeline is built. Plugin base class + manager land. |
| 2 | Plugin registry, discovery, and first official plugin. MCP layer added. |
| 3 | Policy engine gains a RAG retrieval backend. |
| 4 | Multi-agent orchestration layer added. Plugin chaining introduced. |
| 5 | Production hardening: deployment templates, audit compliance, performance tuning. |
