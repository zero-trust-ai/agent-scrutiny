# Architecture

> **Status:** Stage 1 implemented (Python SDK). This document is the single
> source of truth for Agent Scrutiny's system architecture; both the Python and
> Rust SDKs implement this design. Components are marked **implemented** or with
> the stage in which they land.

---

## Guiding Principles

Every architectural decision traces back to one of these:

1. **Verify every interaction** — no implicit trust between any two components.
2. **Assume breach** — stay secure when individual components are compromised.
3. **Least privilege** — each component gets only the access it needs.
4. **Continuous monitoring** — real-time observation of all agent activity.
5. **Context-aware security** — policies applied dynamically to what's happening.
6. **Modular by design** — security capabilities are isolated, composable plugins.

---

## High-Level Component Map

This is the *structural* view — what the pieces are. The order in which an
interaction flows through them is described in [The Evaluation Pipeline](#the-evaluation-pipeline).

```
┌──────────────────────────────────────────────────────────────┐
│                       Agent Interaction                       │
│          (user → agent, agent → agent, agent → API)           │
└────────────────────────────┬─────────────────────────────────┘
                             │
                             ▼
┌──────────────────────────────────────────────────────────────┐
│                     Scrutinizer  (core.py)                    │
│                                                               │
│   ┌───────────────────────────────────────────────────────┐  │
│   │ Plugin Layer                                           │  │
│   │   built-in detectors           third-party plugins     │  │
│   │   ┌──────────────────┐         ┌──────────┐            │  │
│   │   │ PromptInjection  │         │ Plugin A │            │  │
│   │   │ InputValidator   │  …      │ Plugin B │   …        │  │
│   │   │ DataExfiltration │         │ Plugin C │            │  │
│   │   └──────────────────┘         └──────────┘            │  │
│   │   all evaluate in parallel; each is an isolated        │  │
│   │   security boundary                                    │  │
│   └───────────────────────────────────────────────────────┘  │
│                             │                                 │
│                             ▼                                 │
│   ┌───────────────┐   ┌───────────────┐   ┌───────────────┐   │
│   │ Aggregation   │ → │ Policy Engine │ → │ Mode          │   │
│   │ most-severe   │   │ (transform)   │   │ strict/perm/  │   │
│   │ wins          │   │               │   │ monitor       │   │
│   └───────────────┘   └───────────────┘   └───────────────┘   │
└────────────────────────────┬─────────────────────────────────┘
                             │
                             ▼
                      Security Verdict
              (allow / warn / block, + explanation)

   Monitoring & Audit runs alongside every stage and is never bypassed.
```

---

## Component Detail

### Scrutinizer Core — *implemented (Stage 1)*

The central orchestrator (`core.py`). It receives an agent interaction (input,
optional output, context), routes it through the evaluation pipeline, and returns
a `SecurityVerdict`. It never executes agent logic itself — it only *observes and
judges*. It holds no per-interaction state, so one instance serves many
interactions.

### Detection Layer — *implemented (Stage 1)*

A set of built-in detectors. Each one **is a plugin** — it implements the same
contract and runs through the same pipeline as any third-party plugin. There is
no privileged detection path that runs "before" plugins.

| Detector | Threat | Status |
|---|---|---|
| `PromptInjectionDetector` | Instruction hijacking in inputs | Implemented (Stage 1) |
| `InputValidator` | Malformed / out-of-spec data (size, null bytes, control-char density) | Implemented (Stage 1) |
| `DataExfiltrationDetector` | Sensitive data leaking in outputs | Implemented (Stage 1) |
| `BehaviorAnomalyDetector` | Deviation from expected agent patterns | Planned (Stage 4) |

Domain-specific detection is handled by **plugins**, not by adding more detectors
to this layer.

### Plugin System — *implemented (Stage 1)*

Plugins are the primary extension mechanism. The interface is a formal contract —
see the [Plugin Specification](plugins/plugin-specification.md). The base class
(`plugins/base.py`) and manager (`plugins/manager.py`) ship in Stage 1; the
registry and official-plugin bundle land in Stage 2. Every plugin follows the same
lifecycle:

```
Discover  →  Initialize  →  Evaluate (per interaction)  →  Shutdown
```

Plugins are **isolated security boundaries** — a crashing or misbehaving plugin
cannot bring down the Scrutinizer or affect other plugins. The manager runs them
**fail-closed**: an error becomes a `block` verdict rather than a crash.

### Policy Engine — *implemented (Stage 1)*

Transforms the aggregated verdict according to operator-configured rules
(`policies/`). Policies apply **sequentially**, in order, and each may downgrade,
upgrade, or annotate the decision. In Stage 1 policies are static configuration;
in Stage 3 a RAG layer will retrieve and apply them dynamically without code
changes. Like the plugin manager, the policy engine **fails closed**.

### Mode — *implemented (Stage 1)*

The final pipeline stage; controls how the Scrutinizer *acts* on the decision.

| Mode | Behavior |
|---|---|
| `STRICT` | Production default. The post-policy decision stands. |
| `PERMISSIVE` | Same as `STRICT` in Stage 1; will be refined to block only on critical severity once severity is carried on verdicts. |
| `MONITOR` | Shadow mode. Final decision forced to `allow`, but threats, plugin verdicts, and policy annotations are retained for audit. |

### MCP Security Layer — *planned (Stage 2)*

Secures Model Context Protocol communications: parse/validate MCP messages, verify
agent identity and authorization, enforce trust boundaries, and detect MCP-specific
attacks (message tampering, unauthorized delegation).

### Multi-Agent Orchestration — *planned (Stage 4)*

Extends the Scrutinizer to reason across agents: per-agent behavior profiling over
time, cross-boundary anomaly detection, reputation/trust decay, and coordinated-
attack detection.

---

## The Evaluation Pipeline

Every interaction passes through four ordered phases. The detectors are plugins,
so they participate in phase 1 — they are **not** separate pre-plugin stages.

```
                         Agent Interaction
                                │
                                ▼
   1. Plugin Evaluation            (parallel)
      Every registered plugin — built-in detectors and third-party
      plugins alike — evaluates concurrently and returns a
      PluginVerdict (allow / warn / block).
                                │
                                ▼
   2. Raw Aggregation              ("most severe wins")
      block if any plugin blocked; else warn if any warned; else
      allow. Confidence = max among the plugins that voted for the
      winning decision. Threats merged, de-duplicated, first-seen
      order preserved.
                                │
                                ▼
   3. Policy Transformation        (sequential, in order)
      Each policy may downgrade, upgrade, or annotate the verdict.
      Policies see the true detector state — mode is NOT applied yet.
                                │
                                ▼
   4. Mode Application             (final)
      STRICT / PERMISSIVE pass the decision through. MONITOR forces
      the final decision to ALLOW while preserving all evidence.
                                │
                                ▼
                        Security Verdict
              (allow / warn / block, + explanation)
```

**Why policies run before mode:** because mode is applied last, policies always
reason over the real detector state rather than a mode-masked version. A policy
that upgrades `warn` to `block` on a regulated threat still runs its logic under
`MONITOR`; mode then suppresses the *final* decision to `allow`, but the intended
decision and its rationale are preserved in the verdict for audit.

**Edge case:** with no plugins registered, aggregation returns an unconditional
`allow` at confidence 1.0 — there is nothing to judge the interaction against.

The verdict always carries a human-readable `explanation` — this is the
**Explainable Security** principle in action.

---

## Decision Vocabulary

The pipeline is three-valued, not binary:

| Decision | Meaning |
|---|---|
| `allow` | No actionable threat. |
| `warn` | Proceed but flag — suspicious, not conclusive. Not "safe." |
| `block` | Stop the interaction. |

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

## Technology Stack

### Shared (both SDKs)

| Concern | Choice | Rationale |
|---|---|---|
| Plugin contract | Formal interface spec | Language-agnostic; both SDKs implement it |
| Config format | YAML | Human-readable, widely understood |
| Logging format | Structured JSON | Machine-parseable for downstream SIEM integration |

### Python SDK — *implemented*

| Concern | Choice |
|---|---|
| Language | Python 3.9+ |
| Data validation | Pydantic v2 |
| Logging | structlog |
| Cryptography | `cryptography` (for the Stage 2 MCP layer) |
| Config | PyYAML |
| Async | asyncio |

### Rust SDK — *planned*

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
| 0 | Design only. |
| **1** | **Core pipeline built. Detectors, plugin base + manager, policy engine, and mode land. (Complete in Python.)** |
| 2 | Plugin registry, discovery, and first official plugin. MCP layer added. |
| 3 | Policy engine gains a RAG retrieval backend. |
| 4 | Multi-agent orchestration layer added. Plugin chaining introduced. |
| 5 | Production hardening: deployment templates, audit compliance, performance tuning. |
