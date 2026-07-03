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

# 3. Install the package with dev dependencies, in editable mode
pip install -e ".[dev]"

# 4. Verify — run the test suite
pytest
```

> **Note:** Stage 1 is implemented in the Python SDK — the Scrutinizer pipeline, the built-in detectors (prompt injection, input validation, data exfiltration), the policy engine, and the plugin system are all available and tested. See the [Python SDK overview](python/index.md) for the current surface, or jump straight into [Basic Usage](python/tutorials/basic-usage.md).

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