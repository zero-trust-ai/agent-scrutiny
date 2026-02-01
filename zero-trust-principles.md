# Zero-Trust Principles for AI Agents

> **Status:** Stage 0 — Foundation

Traditional zero-trust was designed for networks. AI agents break several of its assumptions. This document explains which traditional principles carry over directly, which need adaptation, and which are entirely new to the AI context.

---

## The Core Idea

Zero-trust boils down to one sentence: **never trust, always verify.** There is no "inside" the network that is inherently safe. Every request is treated as if it originates from an untrusted source until proven otherwise.

For AI agents, this principle is even more important. An agent can be compromised through its inputs (prompt injection), through its training (poisoning), through its environment (retrieval of malicious content), or through its communication channels (MCP tampering). The Scrutinizer enforces zero-trust at every one of these boundaries.

---

## Traditional Principles, Adapted for AI

### 1. Never Trust, Always Verify

**In networks:** Don't trust based on network location or prior authentication.

**For AI agents:** Don't trust any input, output, or inter-agent message — regardless of where it came from or whether it was previously verified.

This means:
- Every agent request is verified, even if it comes from another agent within the same system.
- Every agent response is validated before it's delivered to a user or passed to another agent.
- Authentication is checked on *every* action, not just at session start.

### 2. Assume Breach

**In networks:** Assume attackers are already inside the perimeter.

**For AI agents:** Assume that at least one agent in your system is compromised right now.

Design consequences:
- Agents are isolated. A compromised agent cannot access another agent's internal state.
- The blast radius of any single agent failure is bounded.
- Monitoring is always on — there is no "trusted" state where monitoring can be relaxed.

### 3. Least Privilege

**In networks:** Grant the minimum access needed to perform the task.

**For AI agents:** Give each agent only the tools, data, and permissions it needs for its specific role.

Design consequences:
- A customer-service agent should not have access to the billing database.
- Permissions are scoped to the current task, not granted broadly for the agent's lifetime.
- Capabilities can be revoked instantly without redeploying the agent.

### 4. Verify Explicitly

**In networks:** Use all available context — identity, location, device health — to make access decisions.

**For AI agents:** Use *who* is asking, *what* they're asking for, *when*, *where* in the workflow, *why* (stated purpose), and the agent's *behavioral history* to make security decisions.

This is what makes Agent Scrutiny's security context-aware rather than rule-based. A request to retrieve customer data might be perfectly legitimate from a support agent during a support session, and deeply suspicious from the same agent at 3 AM with no active session.

### 5. Continuous Monitoring

**In networks:** Monitor traffic continuously.

**For AI agents:** Monitor every agent interaction, in real time, forever.

This includes:
- Logging all inputs and outputs with full context.
- Tracking behavioral patterns over time to detect drift.
- Alerting on anomalies as they happen, not in the next audit cycle.
- Maintaining an unalterable audit trail.

---

## AI-Specific Principles

These principles have no direct equivalent in traditional zero-trust. They emerge from the unique properties of AI systems.

### 6. Separate Instructions from Data

**Why it matters:** Prompt injection attacks exist because LLMs cannot reliably distinguish between instructions they should follow and data they should merely process. If user-supplied data can contain executable instructions, and the agent treats them as authoritative, the entire security model collapses.

**How we enforce it:** The Scrutinizer's input validation layer ensures that data entering the agent is structurally separated from system instructions. It flags any data that contains instruction-like patterns before the agent ever sees it.

### 7. Context-Aware Security

**Why it matters:** Static rules produce too many false positives and miss sophisticated attacks that only become visible in context. The word "password" appearing in an agent's output is fine if the user asked "what is a password?" and dangerous if no such question was asked.

**How we enforce it:** Every security decision the Scrutinizer makes considers the full interaction context — the original request, the agent's role, the data classification, the user's authorization level, and the behavioral history. Policies are applied dynamically, not as simple pattern matches.

### 8. Explainable Security

**Why it matters:** If the Scrutinizer blocks an interaction and nobody understands why, developers can't fix legitimate issues, users can't rephrase their requests, and auditors can't verify compliance.

**How we enforce it:** Every `SecurityVerdict` includes a human-readable explanation: what was flagged, why it was flagged, what evidence was used, and what the user or developer should do next.

### 9. Defense in Depth

**Why it matters:** No single security control is perfect. Pattern matching misses novel attacks. Behavioral analysis has blind spots in early interactions. Plugins may have bugs.

**How we enforce it:** The evaluation pipeline layers multiple independent controls. An interaction must pass *all* layers to be allowed. Each layer catches what the others miss.

The layers, in order:

1. Input validation and sanitization
2. Core threat detection (pattern matching)
3. Plugin evaluation (domain-specific analysis)
4. Policy enforcement (rule-based gates)
5. Output filtering (sensitive data removal)
6. Continuous monitoring and audit logging

### 10. Adaptive Security

**Why it matters:** Attackers evolve. A prompt injection pattern that works today will be in every defender's rulebook tomorrow, so attackers will invent new patterns. Static defenses become obsolete.

**How we enforce it:**
- Detection patterns are updated regularly *(Stage 1+)*.
- In Stage 3, the policy engine pulls updated rules from a RAG knowledge base — no code deployment required.
- In Stage 4, behavioral analysis learns from observed attacks.
- The plugin system lets the community add detection for emerging threat domains without waiting for a core release.

---

## Measuring Zero-Trust Maturity

Not every deployment will implement all ten principles immediately. Here is a maturity model to guide adoption:

| Level | Name | What's in place |
|---|---|---|
| 1 | Initial | Ad-hoc security. No systematic verification. |
| 2 | Developing | Input validation and basic threat detection active. Some logging. |
| 3 | Defined | All core principles documented and consistently enforced. Full audit trail. |
| 4 | Managed | Metrics-driven. Security decisions are tracked and reviewed. Plugins active. |
| 5 | Optimizing | Adaptive security. Behavioral analysis running. Threat intelligence integrated. |

Agent Scrutiny Stage 1 targets Level 2–3. Full Level 5 is achievable by Stage 4.

---

## Common Mistakes

**Trusting internal agents.** An agent running inside your infrastructure is not inherently trustworthy. It can be compromised through its inputs just as easily as an external-facing agent.

**Relaxing monitoring for "known" agents.** Zero-trust means continuous monitoring with no exceptions. An agent that has been well-behaved for months can still be compromised today.

**Treating security as a deployment-time concern.** Security must be baked into the evaluation pipeline from the first interaction. You can't bolt it on later without blind spots.

**Assuming complexity is security.** A complicated pipeline is not a secure one. Each security control should be simple enough to understand, test, and audit individually.
