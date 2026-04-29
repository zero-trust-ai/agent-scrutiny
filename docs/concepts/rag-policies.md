# RAG-Powered Policies

> **Threat Model Reference:** Addresses policy staleness across all threat categories · **Detection Stage:** 3

Static security rules become obsolete. New attack patterns emerge daily. Compliance requirements change. A security system that requires a code deployment every time a policy changes will always lag behind the threat landscape.

Stage 3 of Agent Scrutiny solves this by replacing the static policy engine with a RAG-powered policy engine — one that retrieves, interprets, and applies the most current security rules at evaluation time.

---

## The Problem With Static Policies

In Stage 1, security policies are defined in configuration files:

```yaml
policies:
  - name: block-ssn-exposure
    pattern: '\b\d{3}-\d{2}-\d{4}\b'
    action: block
    severity: critical

  - name: block-email-exposure
    pattern: '\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b'
    action: block
    severity: high
```

This works for known, stable patterns. But consider what happens when:

- A new regulatory requirement mandates blocking a data type that wasn't previously sensitive.
- A new attack pattern emerges that doesn't match any existing rule.
- Different customers need different policy sets based on their industry or jurisdiction.

With static policies, every change requires editing config, testing, and redeploying. In a fast-moving threat environment, this is too slow.

---

## How RAG Changes This

Retrieval-Augmented Generation (RAG) pairs a knowledge base with a retrieval engine. When the policy engine needs to make a decision, it:

1. **Retrieves** the most relevant policies from the knowledge base based on the current interaction context.
2. **Interprets** those policies in light of the specific situation.
3. **Applies** them and generates an explanation of why.

The knowledge base is just a collection of documents — policy descriptions, threat intelligence reports, compliance requirements. Updating a policy is as simple as editing or adding a document. No code changes. No redeployment.

```
                    ┌─────────────────────┐
                    │   Interaction        │
                    │   Context            │
                    └──────────┬──────────┘
                               │ "What policies apply here?"
                               ▼
                    ┌─────────────────────┐
                    │   Retrieval Engine   │  Semantic search over
                    │                     │  the policy knowledge base
                    └──────────┬──────────┘
                               │ Returns top-N relevant policies
                               ▼
                    ┌─────────────────────┐
                    │   Policy Interpreter │  Applies retrieved policies
                    │                     │  to the specific context
                    └──────────┬──────────┘
                               │
                               ▼
                    ┌─────────────────────┐
                    │   Verdict +          │  Includes explanation:
                    │   Explanation        │  which policies fired and why
                    └─────────────────────┘
```

---

## The Policy Knowledge Base

The knowledge base is organized into three categories:

### Threat Policies
Rules that define what to block and why. Each policy document includes:
- What the policy protects against (linked to a threat in the threat model)
- The detection criteria
- The action to take (block, warn, log-only)
- Severity classification

### Compliance Requirements
Regulatory and standards-based rules. For example:
- HIPAA: block transmission of PHI without proper authorization
- PCI-DSS: block display of full card numbers in agent output
- GDPR: block processing of personal data without documented consent

### Best Practices
Recommended security behaviors that aren't hard blocks but inform risk scoring. For example:
- Prefer shorter agent responses when the question doesn't require detail (reduces exfiltration surface)
- Flag interactions where an agent accesses data outside its typical scope

---

## Why This Matters for Explainability

One of the core principles of Agent Scrutiny is [Explainable Security](../zero-trust-principles.md#8-explainable-security). RAG makes this significantly better.

With static rules, an explanation might be: *"Blocked because pattern X matched."* Useful, but not deeply informative.

With RAG, the explanation can be: *"Blocked by policy 'HIPAA-PHI-Output-Guard' (last updated 2025-03-15). This policy requires that Protected Health Information not appear in agent output unless the interaction is within an authorized clinical workflow. The current interaction context does not include clinical workflow authorization."*

That explanation is actionable. A developer knows exactly which policy fired, when it was last updated, and what context would make the interaction legitimate.

---

## Updating Policies

An administrator updates policies by editing documents in the knowledge base — no engineering work required:

```
# Before: policy doesn't cover voice recordings
# After: add a new policy document

File: policies/hipaa-voice-recordings.md

---
title: HIPAA Voice Recording Protection
threat: data-exfiltration
severity: critical
updated: 2025-06-01
---

Agent output must not include transcriptions or summaries of protected 
health information captured via voice recording unless the interaction 
is tagged with authorization scope "clinical-voice".
```

The next evaluation that involves a potentially relevant context will retrieve this policy automatically.

---

## Limitations and Guardrails

RAG is powerful but not infallible. Agent Scrutiny applies several safeguards:

- **Policy versioning:** Every policy document has a version and timestamp. The system logs which version of which policy was applied to each decision, creating an auditable trail.
- **Retrieval confidence thresholds:** If the retrieval engine is not confident that any policy applies, the system falls back to the static core rules rather than guessing.
- **Human-in-the-loop for policy creation:** New policies go through a review workflow before entering the knowledge base. This prevents accidental or malicious policy injection.
- **Separation of policy content from policy logic:** The knowledge base contains *what* to enforce. The policy interpreter contains *how* to enforce it. These are separate components with separate security boundaries.