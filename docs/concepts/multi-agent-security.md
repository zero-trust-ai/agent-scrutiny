# Multi-Agent Security

> **Threat Model Reference:** [T4.1](../threat-model.md#t41-behavioral-drift), [T4.2](../threat-model.md#t42-coordinated-multi-agent-attack) · **Detection Stage:** 4

A single agent can be secured by watching its inputs and outputs. But when you have dozens or hundreds of agents working together, threats emerge at the *system* level that no per-agent check can catch. Stage 4 extends Agent Scrutiny to reason across agent boundaries.

---

## Why Per-Agent Security Is Not Enough

Consider this scenario. An attacker wants to exfiltrate a customer's full transaction history. The data is spread across three agents:

- **Agent A** (order history) has access to order IDs and dates.
- **Agent B** (payment records) has access to payment amounts and methods.
- **Agent C** (shipping) has access to delivery addresses.

No single agent has the full picture. If each agent only ever returns a small, innocuous piece of information, no per-agent output filter will flag it. Each individual response looks perfectly normal.

But an attacker who can query all three agents in a coordinated pattern — correlating the pieces across queries — assembles the complete record. The threat exists at the *system* level, not the *agent* level.

This is why multi-agent security must reason across boundaries.

---

## Behavioral Profiling

The foundation of multi-agent security is understanding what "normal" looks like for each agent over time.

### What Gets Profiled

For each agent, the Scrutinizer tracks:

- **Access patterns:** Which data sources does this agent typically query? How often?
- **Response characteristics:** What does this agent's output typically look like? Length, information density, data types.
- **Interaction timing:** When does this agent typically receive requests? From whom?
- **Delegation behavior:** Does this agent delegate tasks? To which agents? How often?

### How Profiles Are Built

Profiles are built incrementally from observed interactions. Early in an agent's lifecycle, the profile is sparse and the system is more permissive (but more closely monitored). As the profile fills in, anomalies become detectable with higher confidence.

```
Interaction 1:    Agent queries customer_db for order history    → recorded
Interaction 2:    Agent returns order summary                    → recorded
Interaction 3:    Agent queries customer_db for order history    → matches profile ✓
...
Interaction 47:   Agent queries payment_db for the first time    → ANOMALY ⚠️
                  (payment_db not in this agent's access profile)
```

---

## Anomaly Detection

Anomaly detection compares current behavior against the established profile and flags deviations that exceed configurable thresholds.

### Types of Anomalies

| Anomaly | What it looks like | Why it matters |
|---|---|---|
| **Access drift** | Agent queries a data source it has never accessed before | May indicate compromise or privilege escalation |
| **Volume spike** | Agent makes 10x its normal number of requests in a short window | May indicate automated exfiltration |
| **Output change** | Agent's responses suddenly contain a new data type | May indicate the agent has been redirected |
| **Timing anomaly** | Agent receives requests outside its normal operating hours | May indicate an attacker using the agent during off-hours |
| **Delegation anomaly** | Agent delegates to an agent it has never delegated to before | May indicate unauthorized task routing |

### Confidence and Thresholds

Not every anomaly is an attack. An agent might legitimately access a new data source for the first time during a new feature rollout. The system uses confidence scoring:

- **Low confidence anomaly:** Logged and monitored, but not blocked. The system watches for corroborating signals.
- **High confidence anomaly:** Blocked and alerted. The interaction is held for review.
- **Critical anomaly:** The agent is automatically isolated (no further interactions processed) pending investigation.

Thresholds are configurable per agent and per anomaly type.

---

## Coordinated Attack Detection

This is where multi-agent security becomes genuinely novel. The Scrutinizer maintains a *cross-agent* view that looks for patterns spanning multiple agents.

### Pattern Correlation

The system periodically analyzes interactions across all agents, looking for clusters of activity that, taken together, suggest coordination:

- Multiple agents queried in rapid succession with related parameters
- A sequence of agents that, combined, cover a complete dataset
- Delegation chains that form paths between agents with complementary data access

### Reputation Scoring

Each agent has a reputation score that reflects its historical trustworthiness. The score degrades when:

- The agent participates in a flagged anomaly (even if it's not the originator)
- The agent is part of a correlated pattern that looks suspicious
- The agent's behavior diverges from its profile

Reputation scores feed back into the authorization model. An agent with a degraded reputation faces tighter scrutiny — lower thresholds for anomaly detection, more restrictive delegation permissions.

### Isolation Protocol

When the system identifies a high-confidence coordinated attack:

1. All agents involved are flagged.
2. The suspected "entry point" agent (the one that received the initial suspicious request) is isolated immediately.
3. Other involved agents have their delegation permissions revoked pending review.
4. A security event is logged with the full correlation chain.
5. An alert is sent to the security operations team.

---

## Plugin Chaining (Stage 4)

Stage 4 also introduces **plugin chaining** — the ability to compose multiple plugins into a single evaluation pipeline where the output of one plugin feeds into the next.

This is important for multi-agent security because coordinated attack detection requires *context* that earlier plugins may have gathered. For example:

1. A **data classification plugin** runs first and tags the interaction with sensitivity labels.
2. A **volume analysis plugin** runs next and uses those labels to determine whether the volume of requests for that sensitivity level is anomalous.
3. A **correlation plugin** runs last and uses both the labels and the volume signal to check for cross-agent patterns.

Without chaining, each plugin would need to independently gather all the context it needs. Chaining makes this compositional and efficient.

---

## What This Looks Like in Practice

```
T+0ms:    Agent-A receives request to look up customer orders
T+1ms:    Scrutinizer checks Agent-A's profile → normal ✓
T+2ms:    Agent-A returns order data → output filter passes ✓

T+50ms:   Agent-B receives request to look up payment for same customer
T+51ms:   Scrutinizer checks Agent-B's profile → normal ✓
T+52ms:   Cross-agent correlator notices: same customer, 
          two agents, 50ms apart → LOW CONFIDENCE ANOMALY ⚠️
          (logged, not blocked yet)

T+100ms:  Agent-C receives request for shipping address, same customer
T+101ms:  Cross-agent correlator: three agents, same customer, 
          100ms span, data types collectively cover full customer record
          → HIGH CONFIDENCE COORDINATED PATTERN 🚨
          All three agents flagged. Agent-A (entry point) isolated.
          Security alert generated.
```

The individual interactions each looked normal. The threat was only visible at the system level.