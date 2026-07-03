# Agent Scrutiny

> **Every agent, under scrutiny.** — Zero-trust security for AI agents.

Agent Scrutiny is an open, educational framework for building, evaluating, and securing AI agents. It applies **zero-trust principles** — never trust, always verify — to the emerging world of interconnected, autonomous agentic systems.

---

## Why This Exists

As AI systems evolve from isolated tools into networked agents that communicate, delegate, and act autonomously, the attack surface grows dramatically. Traditional perimeter security doesn't apply. A compromised agent can propagate harm across an entire agent network. Developers need security tooling built for this reality from the ground up.

Agent Scrutiny fills that gap with a layered, plugin-extensible security evaluation engine and the documentation to understand every decision it makes.

---

## Three Repositories, One Project

| Repository | Role |
|---|---|
| **agent-scrutiny** | Project hub — you are here. Owns all shared docs, specs, and architectural decisions. |
| **agent-scrutiny-python** | Reference implementation. Educational, modular, built for learning. |
| **agent-scrutiny-rust** | Production implementation. Performance-optimized for high-throughput agent workloads. |

Both SDKs implement the same [Plugin Specification](plugins/plugin-specification.md) and are governed by the same [Threat Model](threat-model.md).

---

## Where to Start

- **New to the project?** → [Getting Started](getting-started.md)
- **Want to understand the security model?** → [Zero-Trust Principles](zero-trust-principles.md) then [Threat Model](threat-model.md)
- **Ready to build?** → [Python Installation](python/installation.md) or [Rust Installation](rust/installation.md)
- **Want to write a plugin?** → [Plugin Specification](plugins/plugin-specification.md)
- **Curious about a specific threat?** → [Concepts](concepts/index.md)

---

## Current Status

**Stage 1 is complete in the Python SDK.** The Scrutinizer evaluation pipeline, the built-in detectors (prompt injection, input validation, data exfiltration), the policy engine, and the plugin system are all implemented and tested — and the documentation here describes that shipped surface. The Rust SDK remains in earlier stages. **Stage 2** — MCP security and the full plugin ecosystem — is the next focus. See the [Roadmap](roadmap.md) for the full staged plan.