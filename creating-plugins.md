# Creating a Plugin

This page is a quick reference for the plugin creation workflow. For a full step-by-step tutorial with code, see [Tutorial: Plugin Development](../python/tutorials/plugin-development.md).

---

## The Short Version

1. **Read** the [Plugin Specification](plugin-specification.md) — understand the contract before you write code.
2. **Discuss** your idea — open a discussion in the [agent-scrutiny hub](https://github.com/zero-trust-ai/agent-scrutiny/discussions) with the `plugin-proposal` label. This lets the community give feedback early.
3. **Implement** — write your plugin following the interface contract. Choose your category (threat detector, context analyzer, protocol handler, or policy engine).
4. **Test** — write tests covering happy path, edge cases, and error handling. Run the conformance test suite (Stage 2+).
5. **Document** — create a `plugin.yaml` manifest and a README explaining what your plugin does, how to configure it, and what it catches.
6. **Submit** — open a pull request.

---

## Choosing a Category

| If your plugin… | Choose… |
|---|---|
| Detects a specific type of threat | **Threat Detector** |
| Classifies or understands a specialized domain | **Context Analyzer** |
| Secures a specific communication protocol | **Protocol Handler** |
| Enforces a specific set of rules or regulations | **Policy Engine** |

---

## Quick Checklist

Before submitting:

- [ ] Plugin implements all required interface methods
- [ ] `evaluate()` never panics/crashes — all errors are caught
- [ ] `evaluate()` returns a valid `PluginVerdict` for empty and malformed inputs
- [ ] `plugin.yaml` manifest is present and valid
- [ ] `required_context()` accurately lists what the plugin needs
- [ ] Unit tests cover: safe interaction, each detection rule, missing context, empty input
- [ ] README documents: purpose, configuration options, example scenarios, known limitations
- [ ] Passes the conformance test suite

---

## Plugin Development Resources

| Resource | What it covers |
|---|---|
| [Plugin Specification](plugin-specification.md) | The formal contract — read this first |
| [Tutorial: Plugin Development](../python/tutorials/plugin-development.md) | Full Python walkthrough with code |
| [Official Plugins](official/index.md) | See how the project's own plugins are structured |
| [Architecture — Plugin System](../architecture.md) | How plugins fit into the evaluation pipeline |
| [Contributing — Plugin Section](../contributing.md) | Submission process and review expectations |
