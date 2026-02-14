# Contributing

Thank you for considering a contribution to Agent Scrutiny. This guide covers how to contribute across all three repositories.

---

## Where Does My Contribution Go?

| What you want to do | Which repository |
|---|---|
| Improve documentation or the threat model | **agent-scrutiny** (this hub) |
| Implement or fix Python SDK features | **agent-scrutiny-python** |
| Implement or fix Rust SDK features | **agent-scrutiny-rust** |
| Write a plugin | Start with a discussion here, then implement in the appropriate SDK repo |
| Report a security vulnerability | Email security@zero-trust.ai — do **not** open a public issue |

---

## Getting Started (Any Repo)

1. Fork the relevant repository on GitHub.
2. Clone your fork locally.
3. Create a branch: `feature/your-feature`, `fix/bug-description`, or `plugin/plugin-name`.
4. Make your changes.
5. Run the relevant test suite (see below).
6. Push and open a pull request against `main`.

---

## Contributing to Documentation (This Repo)

### Setup

```bash
git clone https://github.com/YOUR_USERNAME/agent-scrutiny.git
cd agent-scrutiny
pip install zensical
```

### Preview Locally

```bash
zensical serve          # live reload at localhost:8000
```

### Guidelines

- All documentation source lives in `docs/`.
- Use standard Markdown. Zensical supports admonitions, tabs, code fencing with syntax highlighting, and Mermaid diagrams.
- Front matter is not required — Zensical infers titles from the first `#` heading.
- Navigation is defined in `zensical.toml`. If you add a new page, update the `[[project.nav]]` section.
- Keep pages focused. If a topic grows beyond ~500 lines, consider splitting it.

### Admonition Example

```markdown
!!! note "Stage 2 Feature"
    This capability is not yet implemented. It is documented here for design clarity.

!!! warning
    Changing this behavior is a breaking change. Discuss in an issue first.
```

---

## Contributing Code (Python or Rust)

### Python

```bash
cd agent-scrutiny-python
python -m venv venv && source venv/bin/activate
pip install -r requirements.txt -r requirements-dev.txt
pip install -e .
pytest                  # all tests must pass
```

### Rust

```bash
cd agent-scrutiny-rust
cargo build
cargo test              # all tests must pass
```

### Code Standards

- **Python:** Follow PEP 8. Use type hints. Max line length 100. Use Google-style docstrings on all public functions.
- **Rust:** Follow standard `rustfmt` formatting. Document all public items with `///` doc comments.
- **Both:** Write tests for every new feature. Target 80%+ coverage.

### Commit Messages

Use conventional commits:

```
feat: add prompt injection detector
fix: handle empty input in validator
docs: clarify plugin lifecycle in architecture doc
plugin: add smart contract security plugin
test: add edge cases for delegation check
```

---

## Contributing Plugins

Plugins are one of the highest-impact contributions you can make. A well-written plugin adds an entire domain of security analysis to every user of Agent Scrutiny.

### Before You Build

1. Read the [Plugin Specification](plugins/plugin-specification.md) thoroughly.
2. Open a discussion in this repository describing your plugin idea. This lets maintainers and the community give feedback before you invest significant time.
3. Identify which [plugin category](plugins/index.md) your plugin falls into.

### Build Process

1. Start from the plugin template (available in Stage 2).
2. Implement the plugin interface contract exactly as specified.
3. Write tests that pass the conformance test suite.
4. Document your plugin: what it detects, how to configure it, and example scenarios.
5. Open a pull request.

### Plugin Contribution Checklist

- [ ] Plugin implements all required interface methods
- [ ] Passes the conformance test suite
- [ ] Has a `plugin.yaml` manifest
- [ ] README with: purpose, configuration options, example usage, known limitations
- [ ] Unit tests covering happy path and edge cases
- [ ] No external dependencies that are not in the approved dependency list

---

## Responsible Security Disclosure

If you find a security vulnerability in Agent Scrutiny:

1. **Do not** open a public issue.
2. Email **security@zero-trust.ai** with:
   - Description of the vulnerability
   - Steps to reproduce
   - Potential impact
   - Suggested fix (if you have one)
3. We aim to respond within 48 hours.
4. We will coordinate a disclosure timeline with you before anything is made public.

---

## Code of Conduct

This project values:

- Clear explanations over clever code.
- Learning over perfection.
- Collaboration over competition.
- Security for everyone, not just those with deep pockets.

Be respectful. Be constructive. If you see a problem, propose a solution.

---

## Recognition

All contributors are credited in release notes. Major contributions are highlighted on the project website and, with permission, on LinkedIn.

---

## Questions?

- General: [GitHub Discussions](https://github.com/zero-trust-ai/agent-scrutiny/discussions)
- Private matters: contact@zero-trust.ai