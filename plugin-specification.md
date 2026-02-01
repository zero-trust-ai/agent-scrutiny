# Plugin Specification

> **Version:** 1.0-draft · **Status:** Stage 0 — under review. Feedback welcome.

This document defines the contract that every Agent Scrutiny plugin must implement. It is **language-agnostic** — the Python and Rust SDKs each provide their own implementation of this contract (abstract base class in Python, trait in Rust), but the semantics are identical.

Any plugin that correctly implements this specification will work with both SDKs.

---

## Interface Methods

A conforming plugin implements exactly these methods:

### `name() → string`

Returns the plugin's unique identifier. Must be globally unique within any Scrutinizer instance.

**Convention:** kebab-case. Example: `financial-transfer-guard`, `smart-contract-security`.

**Constraints:** Only lowercase letters, digits, and hyphens. No spaces. Max 64 characters.

### `version() → string`

Returns the plugin's version as a semantic version string (per [semver.org](https://semver.org/)).

Example: `"1.2.3"`, `"0.1.0-alpha.1"`

### `description() → string`

A single sentence describing what the plugin does. This is what appears in the plugin registry and in Scrutinizer logs.

Max 200 characters.

### `required_context() → list<string>`

Returns the list of context keys this plugin needs in order to function. The Scrutinizer will log a warning (but not fail) if an evaluation is called without these keys in the context.

Return an empty list if the plugin does not require any specific context.

Example: `["interaction_type", "chain"]` — the plugin needs to know the interaction type and the blockchain being used.

### `initialize(config) → void` *(optional)*

Called once when the plugin is loaded. Receives the plugin's configuration as a dictionary/map. Use this to set up resources: open database connections, load models, parse configuration, etc.

If initialization fails, it must raise/return an error. The Scrutinizer will not use a plugin that fails initialization.

**This method is optional.** If your plugin needs no setup, you do not need to implement it.

### `evaluate(agent_input, agent_output, context) → PluginVerdict` *(required)*

The core detection logic. Called once per agent interaction.

**Parameters:**

| Parameter | Type | Description |
|---|---|---|
| `agent_input` | `string` | The input message or data sent to the agent |
| `agent_output` | `string` | The agent's response |
| `context` | `map<string, any>` | Metadata about the interaction (agent ID, user ID, interaction type, etc.) |

**Return value:** A `PluginVerdict` (see below).

**Performance requirement:** This method is on the hot path. It is called for every interaction. Implementations must be fast. If your plugin needs to call an external service (database, API, model inference), consider whether that latency is acceptable or whether you should cache or batch.

### `shutdown() → void` *(optional)*

Called when the plugin is being unloaded or the Scrutinizer is shutting down. Clean up any resources opened in `initialize()`.

**This method is optional.** If your plugin has no resources to clean up, you do not need to implement it.

---

## PluginVerdict

The return type of `evaluate()`. Every plugin returns exactly one of these.

| Field | Type | Required | Description |
|---|---|---|---|
| `is_safe` | `boolean` | Yes | `true` if the interaction passes this plugin's checks. `false` if a threat is detected. |
| `reason` | `string` | Yes | Human-readable explanation. If `is_safe` is `true`, this can be brief (e.g., `"No issues detected."`). If `is_safe` is `false`, this must explain what was detected and why. |
| `risk_score` | `float` | No | Confidence score, 0.0 to 1.0. Defaults to 0.0 if `is_safe` is `true`, or 0.5 if `is_safe` is `false` and no score is provided. |

---

## Plugin Manifest (`plugin.yaml`)

Every plugin ships with a `plugin.yaml` that describes it for the registry and for automated tooling.

```yaml
# plugin.yaml — required fields marked with (*)

name: financial-transfer-guard              # * Must match name() return value
version: 0.1.0                              # * Must match version() return value
category: threat_detector                   # * One of: threat_detector, context_analyzer,
                                            #   protocol_handler, policy_engine
description: >                              # * Must match description() return value
  Detects unauthorized fund transfer requests
  based on configurable limits and whitelists.

author: "Jane Smith"                        # * Plugin author
license: MIT                                # * License identifier

# What context keys does the plugin need?
requires_context:
  - interaction_type

# Document all configuration options
configuration:
  value_limits:
    type: object
    description: "Per-currency transfer limits."
    default: { eth: 1.0, usdc: 10000.0 }
  address_whitelist:
    type: array
    description: "Approved addresses. Null means all addresses allowed."
    default: null

# Compatibility
compatibility:
  agent_scrutiny_min: "0.2.0"    # Minimum Scrutinizer version
  python_min: "3.9"              # If Python plugin
  rust_edition: "2021"           # If Rust plugin
```

---

## Conformance Requirements

A plugin is considered conformant if it:

1. Implements all required methods (`name`, `version`, `description`, `evaluate`).
2. Returns valid `PluginVerdict` objects from `evaluate()` in all cases — including empty inputs, malformed data, and missing context keys.
3. Does not panic/crash on any input. Errors must be caught and returned as `is_safe: false` with an explanatory reason.
4. Ships a valid `plugin.yaml` manifest.
5. Passes the conformance test suite (available in Stage 2).

---

## Isolation Guarantees

The Scrutinizer enforces these guarantees for every plugin:

- A plugin **cannot** access another plugin's internal state.
- A plugin **cannot** modify the Scrutinizer's core configuration.
- A plugin **crash does not** prevent other plugins or the core pipeline from running. The crashed plugin's verdict is treated as `is_safe: false` with an error reason.
- A plugin **cannot** access the agent's system prompt or internal state directly. It only sees what is passed to `evaluate()`.

---

## Versioning and Compatibility

Plugin versions follow semver. The `compatibility.agent_scrutiny_min` field in `plugin.yaml` declares the minimum Scrutinizer version the plugin requires. The Scrutinizer will refuse to load a plugin that declares a minimum version higher than the running Scrutinizer.

Breaking changes to the plugin interface will bump the specification version (currently `1.0-draft`). The specification version is independent of the Scrutinizer version.
