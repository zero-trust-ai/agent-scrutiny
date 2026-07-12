# Agent Scrutiny

**Every agent, under scrutiny.**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Status: Early Development](https://img.shields.io/badge/Status-Early%20Development-orange.svg)]()
[![Stage: 2 - MCP Security](https://img.shields.io/badge/Stage-2%20Foundation-yellow.svg)]()
[![Docs](https://img.shields.io/badge/Docs-agent--scrutiny.github.io-blue.svg)](https://agent-scrutiny.github.io)

---

## What Is This Repository?

This is the **project hub** for Agent Scrutiny. It owns all shared documentation, the plugin specification, the threat model, and the architectural decisions that govern both implementation repositories:

| Repository | Purpose |
| --- | --- |
| **agent-scrutiny** *(this repo)* | Project hub — docs, specs, roadmap, shared contracts |
| [agent-scrutiny-python](https://github.com/zero-trust-ai/agent-scrutiny-python) | Python SDK — reference implementation |
| [agent-scrutiny-rust](https://github.com/zero-trust-ai/agent-scrutiny-rust) | Rust SDK — production-grade implementation |

---

## Mission

To democratize AI security by creating an open, educational framework that enables developers to build, evaluate, and secure specialized AI agents from the ground up — applying zero-trust principles to ensure safe collaboration in the emerging agentic AI ecosystem.

---

## Documentation

All documentation is authored here in `docs/` and published as a static site via [Zensical](https://zensical.org). The Python and Rust repositories reference this hub for any shared specification or concept.

### Build & Preview Docs Locally

```bash
pip install zensical
zensical serve          # live-reload preview at localhost:8000
zensical build          # output to site/
```

### Doc Structure at a Glance


```
docs/
├── index.md                    # Site landing page
├── getting-started.md          # Onboarding for all three repos
├── architecture.md             # System architecture (shared)
├── threat-model.md             # Threat landscape (shared)
├── zero-trust-principles.md    # Security principles (shared)
├── roadmap.md                  # Staged development plan
├── contributing.md             # How to contribute across all repos
│
├── concepts/                   # Educational deep-dives
│   ├── prompt-injection.md
│   ├── mcp-security.md
│   ├── rag-policies.md
│   └── multi-agent-security.md
│
├── python/                     # Python SDK documentation
│   ├── installation.md
│   ├── api-reference.md
│   └── tutorials/
│       ├── basic-usage.md
│       └── plugin-development.md
│
├── rust/                       # Rust SDK documentation
│   ├── installation.md
│   └── api-reference.md
│
└── plugins/                    # Plugin ecosystem
    ├── plugin-specification.md # Canonical plugin contract
    ├── creating-plugins.md
    └── official/               # Official plugin registry
```

---

## Staged Approach

| Stage | Focus | Status |
|---|---|---|
| 0 | Foundation — threat modeling, architecture, plugin spec | **Complete** |
| 1 | Scrutinizer Core — detectors, policies, plugin foundation | **Complete** |
| 2 | MCP Security & full plugin system | **Current** |
| 3 | RAG-powered dynamic policies | Planned |
| 4 | Multi-agent security & behavioral analysis | Planned |
| 5 | Production hardening | Planned |

See [docs/roadmap.md](docs/roadmap.md) for full detail.

---

## Contributing

Contributions are welcome across all three repositories. Whether you're improving docs here, building the Python SDK, implementing the Rust SDK, or creating a plugin — start with [docs/contributing.md](docs/contributing.md).

---

## License

Code in this repository is licensed under the MIT License (see LICENSE).
Documentation, diagrams, and written content in docs/ are licensed under CC BY 4.0 .

---

*Every agent, under scrutiny.*
