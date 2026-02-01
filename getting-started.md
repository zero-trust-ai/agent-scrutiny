# Getting Started

This guide orients you to the Agent Scrutiny project regardless of whether you plan to use the Python SDK, contribute to the Rust SDK, write a plugin, or improve documentation.

---

## What You're Looking At

Agent Scrutiny is split across three repositories on purpose:

- **agent-scrutiny** (this hub) owns everything that is *shared* — the threat model, the architecture, the plugin specification, and all documentation. If you have a question about *what* Agent Scrutiny does or *why*, the answer lives here.
- **agent-scrutiny-python** is where the reference implementation lives. If you want to *use* Agent Scrutiny today or learn how it works by reading and modifying code, start here.
- **agent-scrutiny-rust** is the production-grade implementation. It targets the same plugin specification and threat model but prioritizes throughput and latency.

---

## Option A — Just Want to Read the Docs

No installation needed. Browse this site. The recommended reading order for someone new to the project:

1. [Architecture](architecture.md) — the big picture of how components fit together.
2. [Threat Model](threat-model.md) — what we're defending against and why.
3. [Zero-Trust Principles](zero-trust-principles.md) — the security philosophy that drives every design decision.
4. [Roadmap](roadmap.md) — what's built, what's coming, and when.

---

## Option B — Set Up the Python SDK

The Python SDK is the fastest path to running code.

### Prerequisites

- Python 3.9 or later
- Git
- A GitHub account (if you plan to contribute)

### Installation

```bash
# 1. Clone the Python repository
git clone https://github.com/zero-trust-ai/agent-scrutiny-python.git
cd agent-scrutiny-python

# 2. Create and activate a virtual environment
python -m venv venv
source venv/bin/activate          # Windows: venv\Scripts\activate

# 3. Install production + dev dependencies
pip install -r requirements.txt
pip install -r requirements-dev.txt

# 4. Install the package in editable mode
pip install -e .

# 5. Verify — run the test suite
pytest
```

> **Note:** We are in Stage 0. The package installs and the placeholder tests pass, but the Scrutinizer core is not yet implemented. See the [Python SDK overview](python/index.md) for what's available now versus what's coming.

---

## Option C — Contribute to Documentation

Documentation lives in the `docs/` folder of this hub repository and is built with [Zensical](https://zensical.org).

```bash
# 1. Clone the hub repository
git clone https://github.com/zero-trust-ai/agent-scrutiny.git
cd agent-scrutiny

# 2. Install Zensical
pip install zensical

# 3. Preview the site with live reload
zensical serve                    # opens at localhost:8000

# 4. Edit any .md file in docs/, changes appear instantly in the browser
```

When you're ready to submit changes, open a pull request against `main`. The CI workflow will build the site automatically so reviewers can verify nothing is broken.

---

## Option D — Write a Plugin

Plugins are the primary extension point. They let you add domain-specific security analysis (smart contracts, healthcare compliance, financial transactions, and so on) without modifying the Scrutinizer core.

The full contract is in [Plugin Specification](plugins/plugin-specification.md). A step-by-step walkthrough is in [Creating a Plugin](plugins/creating-plugins.md). Plugin development becomes available in Stage 2, but you can read the spec and design your plugin now.

---

## Where to Get Help

| Need | Where to go |
|---|---|
| General questions | [GitHub Discussions](https://github.com/zero-trust-ai/agent-scrutiny/discussions) — Q&A category |
| Bug report | Open an issue in the relevant repository (hub, python, or rust) |
| Security vulnerability | Email security@zero-trust.ai — do **not** open a public issue |
| Feature idea | GitHub Discussions — Ideas category |
| Contact | contact@zero-trust.ai |

---

## Learning Resources

If you're new to AI security, these external resources provide useful context before diving into the project:

- [OWASP Top 10 for LLMs](https://owasp.org/www-project-top-10-for-large-language-model-applications/) — the industry-standard threat taxonomy.
- [NIST Zero Trust Architecture (SP 800-207)](https://www.nist.gov/publications/zero-trust-architecture) — the foundational zero-trust framework we extend for AI.
- [NIST AI Risk Management Framework](https://www.nist.gov/itl/ai-risk-management-framework) — structured approach to AI risk.
