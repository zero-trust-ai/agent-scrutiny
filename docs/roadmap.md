# Roadmap

> *Timeline is aspirational. It shifts based on community involvement and feedback.*

Agent Scrutiny follows a staged development methodology. Each stage introduces new security concepts and builds on the previous one. This page is the authoritative roadmap for all three repositories.

---

## Timeline Overview

| Stage | Focus | Target | Status |
|---|---|---|---|
| **0** | Foundation — threat modeling, architecture, plugin spec | Q1 2025 | **Complete** |
| **1** | Scrutinizer Core — detectors, policies, plugin foundation | Q1–Q2 2025 | Planned |
| **2** | MCP Security & full plugin ecosystem | Q2 2025 | Planned |
| **3** | RAG-powered dynamic policies | Q2–Q3 2025 | Planned |
| **4** | Multi-agent security & behavioral analysis | Q3 2025 | Planned |
| **5** | Production hardening & enterprise deployment | Q4 2025 | Planned |

---

## Stage 0 — Foundation

**Goal:** Establish shared documentation, threat model, architecture, and plugin specification before writing implementation code.

### Deliverables

- [x] Repository structure (hub, python, rust)
- [x] Mission statement and core principles
- [x] Plugin architecture design and specification
- [ ] Threat model (in progress — see [Threat Model](threat-model.md))
- [ ] System architecture documentation (in progress — see [Architecture](architecture.md))
- [ ] Zero-trust principles for AI (in progress — see [Zero-Trust Principles](zero-trust-principles.md))
- [ ] Community guidelines and contribution docs

### Success Criteria

- Complete threat model covering all four threat layers (input, output, communication, behavioral).
- Architecture document that both Python and Rust teams can implement from.
- Plugin specification that is language-agnostic and implementable independently.
- Community feedback incorporated.

---

## Stage 1 — Scrutinizer Core

**Goal:** Build the core evaluation pipeline with prompt injection detection, input/output validation, and basic policy enforcement.

### What lands in each SDK

| Component | Python | Rust |
|---|---|---|
| Scrutinizer class & evaluation loop | ✓ | ✓ |
| Prompt injection detector | ✓ | ✓ |
| Input validator | ✓ | ✓ |
| Output filter (data exfiltration) | ✓ | ✓ |
| Policy engine (static rules) | ✓ | ✓ |
| Plugin base class + manager | ✓ | ✓ |
| Structured logging & alerting | ✓ | ✓ |

### Success Criteria

- Detect common prompt injection patterns with a documented false-positive rate.
- Plugin base class is stable and ready for Stage 2 expansion.
- 80%+ test coverage in both SDKs.
- Working examples and tutorials published.

---

## Stage 2 — MCP Security & Plugins

**Goal:** Secure Model Context Protocol communications and launch the full plugin ecosystem.

### MCP Security Components

- Protocol parser and message validator
- Agent identity and authorization
- Trust boundary enforcement
- Message integrity verification (cryptographic)
- MCP-specific threat detection

### Plugin System Components

- Full lifecycle: discover → initialize → evaluate → shutdown
- Plugin registry and discovery mechanism
- Plugin manifest specification (`plugin.yaml`)
- First official plugin: **smart-contract-security**
- Plugin template generator
- Plugin conformance test suite

### Plugin Categories

| Category | Purpose | Example |
|---|---|---|
| Threat Detectors | Domain-specific threat analysis | Smart contract reentrancy |
| Context Analyzers | Understand specialized scenarios | Financial transaction classification |
| Protocol Handlers | Secure non-MCP communication | WebSocket security |
| Policy Engines | Custom rule enforcement | HIPAA compliance checks |

### Success Criteria

- MCP message integrity validated end-to-end.
- Plugin system operational with first official plugin shipped.
- Plugin developer documentation complete with tutorials.
- Performance overhead under 10% compared to unmonitored agent calls.

---

## Stage 3 — RAG Integration

**Goal:** Make security policies dynamic and updatable without code changes, using retrieval-augmented generation.

### Components

- Security policy knowledge base (vector store)
- Dynamic threat intelligence retrieval
- Policy versioning and update workflow
- Context-aware policy application
- Explainable policy decisions ("this policy fired because…")

### Success Criteria

- Policies can be updated by editing documents in the knowledge base — no redeployment.
- Policy decisions include human-readable explanations citing the source policy.
- Integration with at least one vector database (ChromaDB target).

---

## Stage 4 — Multi-Agent Security

**Goal:** Extend the Scrutinizer to reason across agent boundaries and detect threats that only emerge at the system level.

### Components

- Per-agent behavior profiling
- Cross-agent anomaly detection
- Agent reputation scoring
- Coordinated attack detection
- Security orchestration (isolate suspect agents in real time)
- Plugin chaining (compose multiple plugins into a single evaluation pipeline)

### Success Criteria

- Detect abnormal behavior in an agent within N interactions of drift onset.
- Identify coordinated attacks spanning 3+ agents.
- Scale to 100+ concurrent agents without degradation.

---

## Stage 5 — Production Hardening

**Goal:** Make Agent Scrutiny enterprise-ready.

### Components

- Performance optimization and benchmarking
- Docker and Kubernetes deployment templates
- Prometheus + Grafana monitoring dashboards
- Compliance and audit logging (SOC 2 aligned)
- CLI management tools
- Commercial plugin infrastructure

### Success Criteria

- Evaluation latency under 5% overhead at 1,000+ evaluations/second.
- Support for 1,000+ concurrent agents.
- Complete audit trail suitable for compliance review.
- Deployment automation from `docker compose` through production Kubernetes.

---

## Post-Stage 5 — Future Considerations

These are on the radar but not yet scoped:

- Hardware Security Module (HSM) integration for key management
- Federated learning security
- Blockchain-based immutable audit trails
- Quantum-resistant cryptography
- Plugin marketplace with community contribution workflows
- Vertical-specific plugin suites (healthcare, finance, government)