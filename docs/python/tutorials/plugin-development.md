# Tutorial: Plugin Development

> **Stage:** 2 — Plugin development becomes possible when the plugin system is fully operational. This tutorial documents the process in advance so you can design your plugin now.

This tutorial builds a complete plugin from scratch: a **financial transaction security plugin** that detects suspicious fund transfer requests.

---

## What You'll Learn

- How to implement the `SecurityPlugin` interface.
- How to structure your plugin's detection logic.
- How to write tests using the conformance test suite.
- How to register your plugin with the Scrutinizer.

---

## Step 1 — Understand the Interface

Every plugin implements `SecurityPlugin`. Read the [Plugin Specification](../../plugins/plugin-specification.md) for the full contract. Here is the interface you need to implement:

```python
from agent_scrutiny.plugins.base import SecurityPlugin, PluginVerdict
from abc import abstractmethod
from typing import Any

class SecurityPlugin:
    @property
    @abstractmethod
    def name(self) -> str:
        """Unique identifier. Convention: kebab-case."""
        ...

    @property
    @abstractmethod
    def version(self) -> str:
        """Semantic version string."""
        ...

    @property
    @abstractmethod
    def description(self) -> str:
        """One-sentence summary for the plugin registry."""
        ...

    def required_context(self) -> list[str]:
        """Context keys this plugin needs. The Scrutinizer will warn
        if these are missing from the evaluation context."""
        return []

    def initialize(self, config: dict[str, Any]) -> None:
        """Called once when the plugin is loaded. Set up any resources here."""
        pass

    @abstractmethod
    def evaluate(
        self,
        agent_input: str,
        agent_output: str,
        context: dict[str, Any],
    ) -> PluginVerdict:
        """The core detection logic. Called for every interaction."""
        ...

    def shutdown(self) -> None:
        """Called when the plugin is unloaded. Clean up resources here."""
        pass
```

---

## Step 2 — Design Your Plugin

Before writing code, decide:

1. **What threat does this plugin detect?** Be specific. "Financial security" is too broad. "Unauthorized fund transfers exceeding configured limits" is concrete and testable.

2. **What context does it need?** Our plugin needs to know the interaction type and the chain/currency being used. These go in `required_context()`.

3. **What are the detection rules?** Write them out in plain language first:
   - Block any transfer request where the amount exceeds the configured limit for that currency.
   - Flag any transfer to an address not in the agent's whitelist (if a whitelist is configured).
   - Block any transfer request that appears in the agent's output without a corresponding request in the input (unprompted transfer).

---

## Step 3 — Implement the Plugin

```python
# File: financial_transfer_guard/plugin.py

import re
from typing import Any
from agent_scrutiny.plugins.base import SecurityPlugin, PluginVerdict


class FinancialTransferGuard(SecurityPlugin):
    """Detects unauthorized or suspicious fund transfer requests."""

    def __init__(self):
        self._limits: dict[str, float] = {}
        self._whitelist: list[str] | None = None

    # ── Interface: identity ──────────────────────────────────────────

    @property
    def name(self) -> str:
        return "financial-transfer-guard"

    @property
    def version(self) -> str:
        return "0.1.0"

    @property
    def description(self) -> str:
        return "Detects unauthorized fund transfer requests based on configurable limits and address whitelists."

    # ── Interface: context requirements ──────────────────────────────

    def required_context(self) -> list[str]:
        return ["interaction_type"]  # We need to know if this is a financial context

    # ── Interface: lifecycle ─────────────────────────────────────────

    def initialize(self, config: dict[str, Any]) -> None:
        self._limits = config.get("value_limits", {"eth": 1.0, "usdc": 10000.0})
        self._whitelist = config.get("address_whitelist", None)

    # ── Interface: evaluation ────────────────────────────────────────

    def evaluate(
        self,
        agent_input: str,
        agent_output: str,
        context: dict[str, Any],
    ) -> PluginVerdict:
        # Only evaluate financial interactions
        if context.get("interaction_type") != "financial_transfer":
            return PluginVerdict(is_safe=True, reason="Not a financial transfer context.")

        threats = []

        # Rule 1: Check transfer amount against limits
        amount, currency = self._extract_transfer_amount(agent_output)
        if amount is not None and currency is not None:
            limit = self._limits.get(currency.lower())
            if limit is not None and amount > limit:
                threats.append(
                    f"Transfer amount {amount} {currency} exceeds configured "
                    f"limit of {limit} {currency}."
                )

        # Rule 2: Check destination address against whitelist
        address = self._extract_address(agent_output)
        if address and self._whitelist is not None:
            if address not in self._whitelist:
                threats.append(
                    f"Destination address {address} is not in the approved whitelist."
                )

        # Rule 3: Detect unprompted transfers
        if self._contains_transfer(agent_output) and not self._contains_transfer(agent_input):
            threats.append(
                "Agent output contains a transfer action that was not requested in the input."
            )

        if threats:
            return PluginVerdict(
                is_safe=False,
                reason="; ".join(threats),
                risk_score=0.95,
            )

        return PluginVerdict(is_safe=True, reason="Transfer request within policy limits.")

    # ── Private helpers ──────────────────────────────────────────────

    def _extract_transfer_amount(self, text: str) -> tuple[float | None, str | None]:
        match = re.search(r"(?:transfer|send)\s+([\d.]+)\s+(\w+)", text, re.IGNORECASE)
        if match:
            return float(match.group(1)), match.group(2)
        return None, None

    def _extract_address(self, text: str) -> str | None:
        match = re.search(r"(0x[0-9a-fA-F]{40})", text)
        return match.group(1) if match else None

    def _contains_transfer(self, text: str) -> bool:
        return bool(re.search(r"\b(transfer|send)\b.*\b(eth|usdc|btc)\b", text, re.IGNORECASE))
```

---

## Step 4 — Write Tests

Tests should cover the happy path, each detection rule, and edge cases:

```python
# File: financial_transfer_guard/test_plugin.py

import pytest
from plugin import FinancialTransferGuard


@pytest.fixture
def plugin():
    p = FinancialTransferGuard()
    p.initialize({
        "value_limits": {"eth": 1.0, "usdc": 10000.0},
        "address_whitelist": ["0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb"],
    })
    return p


def test_safe_transfer_within_limits(plugin):
    result = plugin.evaluate(
        agent_input="Transfer 0.5 ETH to 0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb",
        agent_output="Initiating transfer of 0.5 ETH to 0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb",
        context={"interaction_type": "financial_transfer"},
    )
    assert result.is_safe is True


def test_blocks_transfer_exceeding_limit(plugin):
    result = plugin.evaluate(
        agent_input="Transfer 100 ETH to 0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb",
        agent_output="Initiating transfer of 100 ETH to 0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb",
        context={"interaction_type": "financial_transfer"},
    )
    assert result.is_safe is False
    assert "exceeds configured limit" in result.reason


def test_blocks_unlisted_address(plugin):
    result = plugin.evaluate(
        agent_input="Transfer 0.5 ETH to 0xAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA",
        agent_output="Initiating transfer of 0.5 ETH to 0xAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA",
        context={"interaction_type": "financial_transfer"},
    )
    assert result.is_safe is False
    assert "not in the approved whitelist" in result.reason


def test_blocks_unprompted_transfer(plugin):
    result = plugin.evaluate(
        agent_input="What is my ETH balance?",
        agent_output="Your balance is 5 ETH. Initiating transfer of 1 ETH to 0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb",
        context={"interaction_type": "financial_transfer"},
    )
    assert result.is_safe is False
    assert "not requested in the input" in result.reason


def test_skips_non_financial_context(plugin):
    result = plugin.evaluate(
        agent_input="What is 2 + 2?",
        agent_output="The answer is 4.",
        context={"interaction_type": "general"},
    )
    assert result.is_safe is True
```

---

## Step 5 — Register the Plugin

```python
from agent_scrutiny import Scrutinizer
from plugin import FinancialTransferGuard

scrutinizer = Scrutinizer(policies=["prompt-injection"])

# Load the plugin with configuration
scrutinizer.load_plugin(
    FinancialTransferGuard(),
    config={
        "value_limits": {"eth": 1.0, "usdc": 10000.0},
        "address_whitelist": ["0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb"],
    },
)

# The Scrutinizer now runs both core detection AND the financial plugin
result = scrutinizer.evaluate(
    agent_input="Transfer 100 ETH to 0x...",
    agent_output="Initiating transfer of 100 ETH...",
    context={
        "agent_id": "finance-agent",
        "interaction_type": "financial_transfer",
    },
)
```

---

## Step 6 — Create the Plugin Manifest

Every plugin ships with a `plugin.yaml` that describes it for the registry:

```yaml
# File: financial_transfer_guard/plugin.yaml

name: financial-transfer-guard
version: 0.1.0
category: threat_detector
description: "Detects unauthorized fund transfer requests based on configurable limits and address whitelists."
author: "Your Name"
license: MIT

requires_context:
  - interaction_type

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
  agent_scrutiny_min: "0.2.0"
  python_min: "3.9"
```

---

## Next Steps

- Read the full [Plugin Specification](../../plugins/plugin-specification.md) for edge cases and advanced patterns.
- Look at the [Official Plugins](../../plugins/official/index.md) page to see how the project's own plugins are structured.
- To contribute your plugin to the community registry, follow the plugin contribution process in [Contributing](../../contributing.md).
