# API Reference — Python SDK

> **Status:** Stage 0 — This page documents the *planned* API. Classes and methods listed here will be implemented in the stages indicated.

---

## `agent_scrutiny` — Top-Level Package

### Current Exports

```python
from agent_scrutiny import __version__   # "0.1.0-dev"
```

### Stage 1 Exports

```python
from agent_scrutiny import Scrutinizer
from agent_scrutiny import SecurityVerdict
from agent_scrutiny import SecurityPolicy
```

---

## `Scrutinizer` *(Stage 1)*

The central security evaluation engine.

```python
class Scrutinizer:
    def __init__(
        self,
        policies: list[str | SecurityPolicy] = None,
        custom_policies: list[dict] = None,
        mode: Literal["strict", "permissive"] = "strict",
        log_level: str = "INFO",
        policy_engine: PolicyEngine | None = None,   # Stage 3: RAG engine
    ) -> None: ...

    def evaluate(
        self,
        agent_input: str,
        agent_output: str,
        context: dict[str, Any] | None = None,
    ) -> SecurityVerdict: ...

    def load_plugin(self, plugin: SecurityPlugin) -> None: ...

    def unload_plugin(self, plugin_name: str) -> None: ...

    def list_plugins(self) -> list[PluginInfo]: ...
```

#### Parameters — `__init__`

| Parameter | Type | Description |
|---|---|---|
| `policies` | `list` | Built-in policy names (e.g., `"prompt-injection"`) or `SecurityPolicy` objects |
| `custom_policies` | `list[dict]` | Inline policy definitions with pattern and threat mappings |
| `mode` | `str` | `"strict"` blocks on any threat signal; `"permissive"` logs but allows |
| `log_level` | `str` | Standard Python log levels |
| `policy_engine` | `PolicyEngine` | Stage 3: swap in a RAG-backed policy engine |

#### Parameters — `evaluate`

| Parameter | Type | Description |
|---|---|---|
| `agent_input` | `str` | The message or data sent to the agent |
| `agent_output` | `str` | The agent's response |
| `context` | `dict` | Metadata: `agent_id`, `user_id`, interaction type, etc. |

---

## `SecurityVerdict` *(Stage 1)*

The return type of `Scrutinizer.evaluate()`. Contains everything needed to act on and explain the security decision.

```python
class SecurityVerdict:
    is_safe: bool
    risk_score: float                    # 0.0 (no risk) to 1.0 (critical)
    threat_type: str | None              # e.g., "prompt_injection"
    threat_types: list[str]              # all detected threats
    threats_detected: int
    explanation: str                     # human-readable reasoning
    matched_patterns: list[str]          # which detection patterns fired
    violated_policies: list[str]         # which policies were violated
    plugin_details: dict[str, Any]       # per-plugin verdict details (Stage 2)
    recommendation: str | None           # what to do next
```

---

## `SecurityPlugin` *(Stage 1–2)*

The abstract base class that all plugins implement. See [Plugin Specification](../plugins/plugin-specification.md) for the full contract.

```python
class SecurityPlugin(ABC):
    @property
    @abstractmethod
    def name(self) -> str: ...

    @property
    @abstractmethod
    def version(self) -> str: ...

    @property
    @abstractmethod
    def description(self) -> str: ...

    def required_context(self) -> list[str]: ...

    def initialize(self, config: dict[str, Any]) -> None: ...

    @abstractmethod
    def evaluate(
        self,
        agent_input: str,
        agent_output: str,
        context: dict[str, Any],
    ) -> PluginVerdict: ...

    def shutdown(self) -> None: ...
```

---

## `MCPScrutinizer` *(Stage 2)*

Security layer for Model Context Protocol communications.

```python
class MCPScrutinizer:
    def __init__(self, trust_policy: TrustPolicy | None = None) -> None: ...

    def validate_message(self, message: dict[str, Any]) -> MCPValidationResult: ...

    def register_agent(self, agent_id: str, credentials: AgentCredentials) -> None: ...

    def authorize(self, sender: str, receiver: str, action: str) -> bool: ...
```

---

## `RAGPolicyEngine` *(Stage 3)*

Drop-in replacement for the static policy engine. Retrieves policies dynamically from a vector knowledge base.

```python
class RAGPolicyEngine:
    def __init__(
        self,
        vector_store: str = "chromadb",     # or "pinecone", "pgvector"
        update_interval: int = 3600,         # seconds between knowledge base checks
    ) -> None: ...

    def get_policies_for_context(self, context: dict[str, Any]) -> list[Policy]: ...

    def explain_decision(self, verdict: SecurityVerdict) -> str: ...
```

---

## Async Variants

All evaluation methods have async counterparts for use in asyncio applications:

```python
verdict = await scrutinizer.evaluate_async(
    agent_input="...",
    agent_output="...",
    context={...},
)
```

Async variants are available starting Stage 1.
