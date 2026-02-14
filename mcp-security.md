# MCP Security

> **Threat Model Reference:** [T3.1](../threat-model.md#t31-mcp-message-tampering), [T3.2](../threat-model.md#t32-unauthorized-agent-delegation) · **Detection Stage:** 2

When AI agents talk to each other, they need a secure channel. The Model Context Protocol (MCP) is becoming the standard for that communication. This page explains why MCP introduces unique security challenges and how Agent Scrutiny addresses them.

---

## What Is MCP?

MCP is a protocol that allows AI agents to communicate with tools, databases, and other agents in a standardized way. It defines a message format and a set of conventions for how agents request and receive information.

Think of it as the HTTP of agent-to-agent communication: a shared language that makes interoperability possible. But just as HTTP required HTTPS, TLS, and authentication layers to become secure, MCP requires its own security envelope.

---

## Why MCP Creates Security Challenges

### Trust Is Not Transitive

In a multi-agent system, Agent A might trust Agent B, and Agent B might trust Agent C. This does **not** mean Agent A should trust Agent C. Each agent-to-agent communication must be independently authorized.

Without enforcement, a compromised Agent B can relay requests to Agent C on behalf of Agent A, escalating privileges beyond what Agent A was ever granted.

### Messages Are Data — And Data Can Be Poisoned

An MCP message is just structured text. If an attacker can modify that text in transit — or inject an entirely fabricated message — the receiving agent has no way to distinguish it from a legitimate request.

This is the MCP equivalent of prompt injection, but at the communication layer rather than the input layer.

### Delegation Is Powerful — And Dangerous

MCP enables agents to delegate tasks to other agents. This is essential for building capable multi-agent systems. But delegation also means an agent can *expand its effective permissions* by routing work through a less-restricted agent.

If delegation is not explicitly authorized and bounded, it becomes an attack vector.

---

## The MCP Security Layer

Agent Scrutiny's MCP security layer (Stage 2) adds four capabilities on top of raw MCP communication:

### 1. Message Integrity Validation

Every MCP message is cryptographically signed by the sending agent. The receiving agent — via the Scrutinizer — verifies the signature before processing the message.

If the message has been tampered with in transit, the signature check fails and the message is dropped.

```
Agent A  ──signs──▶  [MCP Message + Signature]  ──▶  Scrutinizer  ──verifies──▶  Agent B
                                                        │
                                          signature invalid? → DROP
```

### 2. Agent Identity Verification

Before any message is processed, the Scrutinizer verifies that the sending agent is who it claims to be. Agent identity is established during registration and is bound to a cryptographic credential.

This prevents message spoofing — an attacker cannot fabricate a message that appears to come from a trusted agent.

### 3. Authorization Enforcement

The Scrutinizer maintains an authorization model that defines which agents are permitted to send which types of messages to which other agents. Every outgoing MCP message is checked against this model.

If Agent B tries to send a message type it is not authorized to send, or tries to reach an agent it has no relationship with, the Scrutinizer blocks it before it leaves the network.

### 4. Replay Detection

Captured legitimate messages can be replayed by an attacker to trigger the same action again. The MCP security layer tracks message sequence numbers and timestamps, and rejects any message that appears to be a replay of a previously processed message.

---

## Trust Boundaries in Practice

```
┌─────────────────────────────────────────────────────┐
│                  Agent Network                       │
│                                                     │
│  ┌─────────┐    authorized     ┌─────────┐          │
│  │ Agent A │ ──────────────▶   │ Agent B │          │
│  │         │                   │         │          │
│  └─────────┘                   └────┬────┘          │
│                                     │               │
│                        NOT authorized│               │
│                                     ▼               │
│                              ┌─────────┐            │
│                              │ Agent C │            │
│                              │         │            │
│                              └─────────┘            │
│                                                     │
│  Every arrow is validated by the Scrutinizer.       │
│  Agent B cannot reach Agent C without explicit      │
│  authorization — even if Agent A could.             │
└─────────────────────────────────────────────────────┘
```

Agent A's authorization does not flow through Agent B. Each agent's permissions are scoped to its own role. This is the [least privilege](../zero-trust-principles.md#3-least-privilege) principle applied to inter-agent communication.

---

## What This Looks Like in Code (Stage 2+)

```python
from agent_scrutiny.mcp import MCPScrutinizer

mcp = MCPScrutinizer()

# Validate an inbound MCP message before processing
message = {
    "from": "agent-customer-service",
    "to": "agent-billing",
    "action": "lookup_account",
    "payload": {"customer_id": "cust-4821"},
    "signature": "...",
    "sequence": 1042,
}

result = mcp.validate_message(message)

if result.is_valid:
    # Safe to process
    process(message)
else:
    # result.reason explains why: tampering, unauthorized, replay, etc.
    log_security_event(result)
```

---

## Relationship to Google's A2A Protocol

Google's Agent2Agent (A2A) protocol is an emerging standard for agent interoperability that shares similar goals with MCP. Agent Scrutiny's MCP security layer is designed to be protocol-agnostic at its core — the identity verification, authorization, and integrity validation concepts apply regardless of whether the underlying transport is MCP, A2A, or something else. Plugin handlers (Stage 2) can be written for any agent communication protocol.