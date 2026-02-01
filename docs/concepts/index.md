# Concepts

This section provides educational deep-dives into the specific threat domains and security patterns that Agent Scrutiny addresses. Each page explains *what* a threat is, *why* it matters for AI agents specifically, and *how* the Scrutinizer detects or mitigates it.

These pages are written for developers who want to understand the security reasoning — not just use the tool.

---

## Topics

- **[Prompt Injection](prompt-injection.md)** — How attackers hijack agent behavior through crafted inputs, and why this is the most critical threat in agentic AI today.
- **[MCP Security](mcp-security.md)** — Why agent-to-agent communication needs its own security layer, and how the Model Context Protocol creates unique attack surfaces.
- **[RAG-Powered Policies](rag-policies.md)** — How retrieval-augmented generation can make security policies dynamic, updatable, and context-aware without code changes.
- **[Multi-Agent Security](multi-agent-security.md)** — Why security reasoning must span agent boundaries, and how behavioral analysis catches threats that per-agent checks miss.
