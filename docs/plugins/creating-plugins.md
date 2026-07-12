# Creating a Plugin

This page is a quick reference for the plugin creation workflow. For a full step-by-step tutorial with code, see [Tutorial: Plugin Development](plugin-development.md).

The plugin system — the `Plugin` base class, the manager, and constructor-based
registration — is implemented and usable **today** (Stage 1). The registry,
manifest enforcement (`plugin.yaml`), plugin template generator, and conformance
test suite arrive in **Stage 2**; those steps are marked below.

---

## The Short Version

1. **Read** the [Plugin Specification](../python/tutorials/) — understand the contract before you write code.
2. **Discuss** your idea — open a discussion in the [agent-scrutiny hub](https://github.com/zero-trust-ai/agent-scrutiny/discussions) with the `plugin-proposal` label. This lets the community give feedback early.
3. **Implement** — subclass `Plugin`, declare the three identity properties (`name`, `version`, `description`), and implement the async `evaluate(interaction, context)` coroutine. Return a `PluginVerdict` via the `self.allow()` / `self.warn()` / `self.block()` helpers. Choose your category (threat detector, context analyzer, protocol handler, or policy engine).
4. **Test** — write pytest tests covering the happy path, each detection rule, and edge cases (empty input, missing context). The formal conformance test suite lands in Stage 2.
5. **Register** — pass your plugin to `Scrutinizer(plugins=[...])` and provide any configuration through `initialize(plugin_configs={...})`.
6. **Document & submit** *(manifest is Stage 2)* — write a README explaining what your plugin catches and how to configure it; add a `plugin.yaml` manifest once the registry ships. Open a pull request.

---

## What implementing looks like

```python
from agent_scrutiny import Plugin, PluginVerdict


class MyDetector(Plugin):
    @property
    def name(self) -> str: return "my-detector"

    @property
    def version(self) -> str: return "1.0.0"

    @property
    def description(self) -> str: return "Detects the thing I care about."

    async def evaluate(self, interaction, context) -> PluginVerdict:
        if "bad" in interaction.agent_input:
            return self.block(
                explanation="Disallowed token found.",
                threats=["my_detector.bad_token"],
                confidence=0.9,
            )
        return self.allow()
```

`evaluate()` is **async**, receives an `AgentInteraction` and an
`EvaluationContext`, and returns a three-valued verdict (`allow` / `warn` /
`block`) — not a binary pass/fail. The framework fills in `plugin_name`,
`plugin_version`, and timing for you.

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

- [ ] Subclass implements the three identity properties and the async `evaluate()`
- [ ] `evaluate()` never crashes — foreseeable errors are caught and returned as a `block` verdict (the framework also fails closed on any uncaught exception)
- [ ] `evaluate()` returns a valid `PluginVerdict` for empty and malformed inputs
- [ ] `required_context()` accurately lists the `metadata` keys the plugin needs
- [ ] Unit tests cover: safe interaction, each detection rule, missing context, empty input
- [ ] README documents: purpose, configuration options, example scenarios, known limitations
- [ ] *(Stage 2)* `plugin.yaml` manifest is present and valid
- [ ] *(Stage 2)* Passes the conformance test suite

---

## Plugin Development Resources

| Resource | What it covers |
|---|---|
| [Plugin Specification](plugin-specification.md) | The formal contract — read this first |
| [Tutorial: Plugin Development](plugin-development.md) | Full Python walkthrough with code |
| [Official Plugins](official/index.md) | See how the project's own plugins are structured |
| [Architecture — Plugin System](../architecture.md) | How plugins fit into the evaluation pipeline |
| [Contributing — Plugin Section](../../contributing.md) | Submission process and review expectations |
