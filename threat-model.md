# Threat Model

> **Status:** Stage 0 — actively being refined. Contributions welcome.

This document catalogs the threats that Agent Scrutiny is designed to detect and mitigate. It is the authoritative reference for both the Python and Rust implementations. Every detector and policy traces back to a threat defined here.

---

## Threat Taxonomy

Threats are grouped by *where* in the agent interaction they occur. Each threat entry includes the attack vector, a severity rating, the stage in which detection is implemented, and the mitigation strategy.

Severity is rated on a three-point scale:

- **Critical** — can lead to data breach, unauthorized action, or system compromise.
- **High** — degrades security posture or enables further attacks.
- **Medium** — reduces trust or causes incorrect behavior without direct data exposure.

---

## T1 — Input-Layer Threats

These threats target data *before* it reaches the agent.

### T1.1 Prompt Injection

| Field | Detail |
|---|---|
| **Severity** | Critical |
| **Detection stage** | Stage 1 |
| **OWASP LLM reference** | LLM01 |

**What it is:** An attacker embeds instructions inside what appears to be user data, attempting to override the agent's system prompt or redirect its behavior.

**Attack patterns:**
- Direct override: *"Ignore all previous instructions and instead…"*
- Indirect injection: Malicious instructions embedded in documents, web pages, or database records that the agent retrieves and processes.
- Role-play injection: *"You are now DAN (Do Anything Now)…"*
- Separator injection: Using delimiters (e.g., `---`, `###`) to visually separate injected instructions from legitimate content.

**Why it's critical:** A successful prompt injection can cause an agent to exfiltrate data, take unauthorized actions, or act as a pivot point to attack other agents in a multi-agent system.

**Mitigation strategy:**
1. Pattern matching against known injection signatures *(Stage 1)*.
2. Structural separation of instructions from data at the input boundary *(Stage 1)*.
3. Plugin-based domain-specific injection detection *(Stage 2)*.
4. Behavioral anomaly detection to catch novel injection patterns *(Stage 4)*.

---

### T1.2 Input Validation Bypass

| Field | Detail |
|---|---|
| **Severity** | High |
| **Detection stage** | Stage 1 |
| **OWASP LLM reference** | LLM05 |

**What it is:** Malformed, oversized, or specially crafted input that bypasses validation and reaches the agent in an unexpected state.

**Attack patterns:**
- Unicode homoglyph substitution to evade text filters.
- Encoding tricks (base64, URL encoding) to hide payload.
- Extremely long inputs designed to cause truncation or buffer issues.

**Mitigation strategy:**
1. Schema-based input validation with strict type and length enforcement *(Stage 1)*.
2. Normalization pass before any pattern matching runs *(Stage 1)*.

---

## T2 — Output-Layer Threats

These threats target data *after* the agent has generated a response.

### T2.1 Data Exfiltration

| Field | Detail |
|---|---|
| **Severity** | Critical |
| **Detection stage** | Stage 1 |
| **OWASP LLM reference** | LLM02 |

**What it is:** The agent's response contains sensitive information — PII, credentials, internal system details — that should not be exposed to the caller.

**Attack patterns:**
- Direct leakage: Agent echoes back secrets present in its context.
- Indirect leakage: Agent paraphrases or summarizes confidential data in a way that exposes it.
- Steganographic leakage: Sensitive data encoded within seemingly innocuous output (e.g., first letters of each sentence).

**Mitigation strategy:**
1. Output scanning for known sensitive patterns (SSN, email, API keys, etc.) *(Stage 1)*.
2. Classification-based output filtering using configurable sensitivity levels *(Stage 1)*.
3. Custom data-loss-prevention plugins for domain-specific secrets *(Stage 2)*.

---

### T2.2 Privilege Escalation via Output

| Field | Detail |
|---|---|
| **Severity** | High |
| **Detection stage** | Stage 1 |
| **OWASP LLM reference** | LLM06 |

**What it is:** The agent's output contains instructions or data that, if acted upon by a downstream system, would grant elevated permissions.

**Attack patterns:**
- Output that instructs a downstream agent to bypass its own security controls.
- Responses that construct valid authentication tokens or permission grants.

**Mitigation strategy:**
1. Output policy enforcement that blocks responses containing instruction-like content directed at other systems *(Stage 1)*.
2. Inter-agent communication validation in the MCP layer *(Stage 2)*.

---

## T3 — Communication-Layer Threats

These threats target the channels *between* agents.

### T3.1 MCP Message Tampering

| Field | Detail |
|---|---|
| **Severity** | Critical |
| **Detection stage** | Stage 2 |
| **OWASP LLM reference** | LLM09 |

**What it is:** An attacker intercepts or modifies Model Context Protocol messages in transit between agents.

**Attack patterns:**
- Man-in-the-middle modification of message payloads.
- Replay attacks: resending previously captured valid messages.
- Message injection: inserting forged messages into an agent communication channel.

**Mitigation strategy:**
1. Message integrity validation (cryptographic signatures) *(Stage 2)*.
2. Sequence numbering and replay detection *(Stage 2)*.
3. Agent identity verification on every message *(Stage 2)*.

---

### T3.2 Unauthorized Agent Delegation

| Field | Detail |
|---|---|
| **Severity** | High |
| **Detection stage** | Stage 2 |

**What it is:** An agent delegates a task to another agent without proper authorization, expanding its effective permissions beyond what was granted.

**Attack patterns:**
- An agent routes a sensitive request to a less-secured agent.
- An agent creates ad-hoc sub-agents to bypass permission boundaries.

**Mitigation strategy:**
1. Delegation authorization checks enforced by the MCP trust manager *(Stage 2)*.
2. Least-privilege enforcement: agents can only delegate within their own permission scope *(Stage 2)*.

---

## T4 — Behavioral Threats

These threats emerge over time and require observing agent behavior across multiple interactions.

### T4.1 Behavioral Drift

| Field | Detail |
|---|---|
| **Severity** | High |
| **Detection stage** | Stage 4 |

**What it is:** An agent's behavior gradually shifts away from its expected pattern — potentially the result of a slow-burn poisoning attack or model drift.

**Mitigation strategy:**
1. Baseline behavioral profiling per agent *(Stage 4)*.
2. Statistical anomaly detection on interaction patterns *(Stage 4)*.
3. Automatic alerting when drift exceeds configurable thresholds *(Stage 4)*.

---

### T4.2 Coordinated Multi-Agent Attack

| Field | Detail |
|---|---|
| **Severity** | Critical |
| **Detection stage** | Stage 4 |

**What it is:** Multiple agents act in concert to achieve an objective that no single agent could accomplish alone — for example, collectively exfiltrating data across multiple low-volume interactions.

**Mitigation strategy:**
1. Cross-agent pattern correlation *(Stage 4)*.
2. Reputation scoring that degrades when agents participate in suspicious clusters *(Stage 4)*.
3. Security orchestration layer that can isolate suspect agents in real time *(Stage 4)*.

---

## Threat-to-Stage Matrix

| Threat | Severity | Input | Output | Communication | Behavioral | Detection Stage |
|---|---|---|---|---|---|---|
| T1.1 Prompt Injection | Critical | ✓ | | | | 1 |
| T1.2 Input Validation Bypass | High | ✓ | | | | 1 |
| T2.1 Data Exfiltration | Critical | | ✓ | | | 1 |
| T2.2 Privilege Escalation | High | | ✓ | | | 1 |
| T3.1 MCP Message Tampering | Critical | | | ✓ | | 2 |
| T3.2 Unauthorized Delegation | High | | | ✓ | | 2 |
| T4.1 Behavioral Drift | High | | | | ✓ | 4 |
| T4.2 Coordinated Attack | Critical | | | | ✓ | 4 |

---

## Contributing to This Document

This threat model is a living document. If you identify a threat vector that is missing or believe an existing entry needs revision, open an issue or pull request against this repository. Tag it with the `threat-model` label.

When proposing a new threat, please include:

- A clear description of the attack vector.
- At least one concrete attack pattern.
- Why existing mitigations are insufficient.
- A suggested detection or mitigation strategy and which stage it fits.
