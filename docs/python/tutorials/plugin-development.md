# Tutorial: Plugin Development

> **Stage:** 1 — The plugin system is implemented, so everything in this tutorial
> runs today. The plugin *registry*, `plugin.yaml` enforcement, and conformance
> test suite arrive in Stage 2; those steps are marked accordingly.

This tutorial builds a complete plugin from scratch: a **financial transfer
guard** that detects suspicious fund-transfer requests.

---

## What You'll Learn

- How to implement the `Plugin` interface.
- How to structure detection logic and return a three-valued verdict.
- How to write async tests for a plugin.
- How to register a plugin with the Scrutinizer and pass it configuration.

---

## Step 1 — Understand the Interface

Every plugin subclasses `Plugin`. Read the [Plugin Specification](../../plugins/plugin-specification.md)
for the full contract. The shape you implement:

```python
from abc import ABC, abstractmethod
from typing import Any

from agent_scrutiny.models import AgentInteraction, EvaluationContext, PluginVerdict


class Plugin(ABC):
    # ── Identity: three read-only properties (required) ──────────────
    @property
    @abstractmethod
    def name(self) -> str: ...

    @property
    @abstractmethod
    def version(self) -> str: ...

    @property
    @abstractmethod
    def description(self) -> str: ...

    # ── Core detection logic (required, async) ───────────────────────
    @abstractmethod
    async def evaluate(
        self,
        interaction: AgentInteraction,
        context: EvaluationContext,
    ) -> PluginVerdict: ...

    # ── Optional overrides ───────────────────────────────────────────
    def required_context(self) -> list[str]:
        return []

    async def initialize(self, config: dict[str, Any] | None = None) -> None:
        ...

    async def shutdown(self) -> None:
        ...
```

Three things to notice, because they differ from older drafts:

- `name`, `version`, `description` are **properties**, not methods.
- `evaluate()` is **async** and takes an `AgentInteraction` and an
  `EvaluationContext` — not two strings and a dict.
- The verdict is three-valued (`allow` / `warn` / `block`). You build it with the
  inherited `self.allow()`, `self.warn()`, and `self.block()` helpers, which
  fill in `plugin_name` and `plugin_version` for you.

---

## Step 2 — Design Your Plugin

Before writing code, decide:

1. **What threat does this plugin detect?** Be specific. "Unauthorized fund
   transfers exceeding configured limits" is concrete and testable.

2. **What context does it need?** `interaction_type` on `AgentInteraction` is a
   fixed protocol-level enum (`user_to_agent`, `agent_to_agent`, `agent_to_api`),
   so a *domain* classifier like "this is a financial transfer" belongs in
   `context.metadata`. Our plugin reads `metadata["interaction_class"]`, so we
   declare that key in `required_context()`.

3. **What are the detection rules?** In plain language:
   - Block any transfer whose amount exceeds the configured limit for that currency.
   - Block any transfer to an address not on the configured whitelist.
   - Block any transfer that appears in the agent's *output* without a matching
     request in the *input* (an unprompted transfer).

---

## Step 3 — Implement the Plugin

```python
# File: financial_transfer_guard/plugin.py

import re
from typing import Any

from agent_scrutiny import Plugin, PluginVerdict


class FinancialTransferGuard(Plugin):
    """Detects unauthorized or suspicious fund-transfer requests."""

    def __init__(self) -> None:
        self._limits: dict[str, float] = {}
        self._whitelist: list[str] | None = None

    # ── Identity ─────────────────────────────────────────────────────
    @property
    def name(self) -> str:
        return "financial-transfer-guard"

    @property
    def version(self) -> str:
        return "0.1.0"

    @property
    def description(self) -> str:
        return (
            "Detects unauthorized fund-transfer requests based on "
            "configurable limits and address whitelists."
        )

    # ── Context requirements ─────────────────────────────────────────
    def required_context(self) -> list[str]:
        # A metadata key, not the interaction_type enum.
        return ["interaction_class"]

    # ── Lifecycle ────────────────────────────────────────────────────
    async def initialize(self, config: dict[str, Any] | None = None) -> None:
        config = config or {}
        self._limits = config.get("value_limits", {"eth": 1.0, "usdc": 10000.0})
        self._whitelist = config.get("address_whitelist", None)

    # ── Evaluation ───────────────────────────────────────────────────
    async def evaluate(self, interaction, context) -> PluginVerdict:
        # Only evaluate interactions classified as financial transfers.
        if context.metadata.get("interaction_class") != "financial_transfer":
            return self.allow(explanation="Not a financial-transfer interaction.")

        agent_input = interaction.agent_input or ""
        agent_output = interaction.agent_output or ""

        threats: list[str] = []
        reasons: list[str] = []
        confidence = 0.0

        # Rule 1: amount exceeds the configured limit.
        amount, currency = self._extract_transfer_amount(agent_output)
        if amount is not None and currency is not None:
            limit = self._limits.get(currency.lower())
            if limit is not None and amount > limit:
                threats.append("financial.transfer_over_limit")
                reasons.append(
                    f"Transfer of {amount} {currency} exceeds the configured "
                    f"limit of {limit} {currency}."
                )
                confidence = max(confidence, 0.9)

        # Rule 2: destination address not on the whitelist.
        if self._whitelist is not None:
            address = self._extract_address(agent_output)
            if address is not None and address not in self._whitelist:
                threats.append("financial.unlisted_address")
                reasons.append(
                    f"Destination address {address} is not on the approved whitelist."
                )
                confidence = max(confidence, 0.9)

        # Rule 3: transfer initiated in output but never requested in input.
        if self._contains_transfer(agent_output) and not self._contains_transfer(
            agent_input
        ):
            threats.append("financial.unprompted_transfer")
            reasons.append(
                "The output initiates a transfer that was not requested in the input."
            )
            confidence = max(confidence, 0.85)

        if threats:
            return self.block(
                explanation=" ".join(reasons),
                threats=threats,
                confidence=confidence,
                evidence={"amount": amount, "currency": currency},
            )

        return self.allow(explanation="Transfer passed all financial checks.")

    # ── Helpers ──────────────────────────────────────────────────────
    def _extract_transfer_amount(self, text: str) -> tuple[float | None, str | None]:
        match = re.search(r"([\d.]+)\s+(\w+)", text)
        if match:
            return float(match.group(1)), match.group(2)
        return None, None

    def _extract_address(self, text: str) -> str | None:
        match = re.search(r"(0x[0-9a-fA-F]{40})", text)
        return match.group(1) if match else None

    def _contains_transfer(self, text: str) -> bool:
        return bool(
            re.search(r"\b(transfer|send)\b.*\b(eth|usdc|btc)\b", text, re.IGNORECASE)
        )
```

Note the verdict style: `evaluate()` returns `self.block(...)` or `self.allow(...)`.
Threats are **IDs** (`financial.transfer_over_limit`), while the human-readable
prose goes in `explanation`. That separation is what lets policies match on
threat patterns and dashboards group by threat ID.

---

## Step 4 — Write Tests

`evaluate()` and `initialize()` are async, so tests use `pytest-asyncio`
(already a dev dependency).

```python
# File: financial_transfer_guard/test_plugin.py

import pytest
import pytest_asyncio

from agent_scrutiny import Decision
from agent_scrutiny.models import AgentInteraction, EvaluationContext, InteractionType
from plugin import FinancialTransferGuard

WHITELISTED = "0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb"


@pytest_asyncio.fixture
async def plugin():
    p = FinancialTransferGuard()
    await p.initialize(
        {
            "value_limits": {"eth": 1.0, "usdc": 10000.0},
            "address_whitelist": [WHITELISTED],
        }
    )
    return p


def _financial(agent_input: str, agent_output: str):
    interaction = AgentInteraction(
        agent_input=agent_input,
        agent_output=agent_output,
        interaction_type=InteractionType.AGENT_TO_API,
    )
    context = EvaluationContext(
        agent_id="finance-agent",
        metadata={"interaction_class": "financial_transfer"},
    )
    return interaction, context


@pytest.mark.asyncio
async def test_safe_transfer_within_limits(plugin):
    interaction, context = _financial(
        f"Transfer 0.5 ETH to {WHITELISTED}",
        f"Initiating transfer of 0.5 ETH to {WHITELISTED}",
    )
    result = await plugin.evaluate(interaction, context)
    assert result.decision == Decision.ALLOW


@pytest.mark.asyncio
async def test_blocks_transfer_exceeding_limit(plugin):
    interaction, context = _financial(
        f"Transfer 100 ETH to {WHITELISTED}",
        f"Initiating transfer of 100 ETH to {WHITELISTED}",
    )
    result = await plugin.evaluate(interaction, context)
    assert result.decision == Decision.BLOCK
    assert "financial.transfer_over_limit" in result.threats


@pytest.mark.asyncio
async def test_blocks_unlisted_address(plugin):
    unlisted = "0xAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
    interaction, context = _financial(
        f"Transfer 0.5 ETH to {unlisted}",
        f"Initiating transfer of 0.5 ETH to {unlisted}",
    )
    result = await plugin.evaluate(interaction, context)
    assert result.decision == Decision.BLOCK
    assert "financial.unlisted_address" in result.threats


@pytest.mark.asyncio
async def test_blocks_unprompted_transfer(plugin):
    interaction, context = _financial(
        "What is my ETH balance?",
        f"Your balance is 5 ETH. Initiating transfer of 0.5 ETH to {WHITELISTED}",
    )
    result = await plugin.evaluate(interaction, context)
    assert result.decision == Decision.BLOCK
    assert "financial.unprompted_transfer" in result.threats


@pytest.mark.asyncio
async def test_skips_non_financial_context(plugin):
    interaction = AgentInteraction(
        agent_input="What is 2 + 2?",
        agent_output="The answer is 4.",
        interaction_type=InteractionType.USER_TO_AGENT,
    )
    context = EvaluationContext(agent_id="assistant-1")  # no interaction_class
    result = await plugin.evaluate(interaction, context)
    assert result.decision == Decision.ALLOW
```

---

## Step 5 — Register the Plugin

Plugins are passed to the `Scrutinizer` constructor. Per-plugin configuration is
supplied to `initialize()`, keyed by plugin name.

```python
import asyncio

from agent_scrutiny import Scrutinizer, PromptInjectionDetector
from plugin import FinancialTransferGuard

WHITELISTED = "0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb"


async def main():
    scrutinizer = Scrutinizer(
        plugins=[
            PromptInjectionDetector(),   # a built-in detector, also a plugin
            FinancialTransferGuard(),    # our custom plugin
        ],
    )

    # Configuration is routed to each plugin's initialize() by name.
    await scrutinizer.initialize(
        plugin_configs={
            "financial-transfer-guard": {
                "value_limits": {"eth": 1.0, "usdc": 10000.0},
                "address_whitelist": [WHITELISTED],
            },
        }
    )

    verdict = await scrutinizer.evaluate_interaction(
        agent_input="Transfer 100 ETH to 0x0000000000000000000000000000000000000000",
        agent_output="Initiating transfer of 100 ETH...",
        agent_id="finance-agent",
        metadata={"interaction_class": "financial_transfer"},
    )

    print(verdict.is_blocked)     # True
    print(verdict.threats)        # ['financial.transfer_over_limit', ...]
    print(verdict.explanation)

    await scrutinizer.shutdown()


asyncio.run(main())
```

The financial guard and the built-in prompt-injection detector run in parallel;
their verdicts are aggregated by "most severe wins" before any policies or the
mode are applied.

---

## Step 6 — Create the Plugin Manifest *(Stage 2)*

The registry and manifest tooling arrive in Stage 2. When they do, each plugin
will ship a `plugin.yaml` describing it. The current draft shape:

```yaml
# File: financial_transfer_guard/plugin.yaml

name: financial-transfer-guard
version: 0.1.0
category: threat_detector
description: "Detects unauthorized fund-transfer requests based on configurable limits and address whitelists."
author: "Your Name"
license: MIT

requires_context:
  - interaction_class

configuration:
  value_limits:
    type: object
    description: "Per-currency transfer limits (e.g., eth: 1.0)"
    default: { eth: 1.0, usdc: 10000.0 }
  address_whitelist:
    type: array
    description: "Approved destination addresses. If omitted, all addresses are allowed."
    default: null

compatibility:
  agent_scrutiny_min: "0.2.0"   # minimum Scrutinizer version (Stage 2 target)
  python_min: "3.9"
```

---

## Next Steps

- Read the full [Plugin Specification](../../plugins/plugin-specification.md) for the verdict model, aggregation rules, and isolation guarantees.
- See the [Official Plugins](../../plugins/official/index.md) page for how the project's own plugins are structured.
- To contribute your plugin, follow the process in [Contributing](../../contributing.md).
