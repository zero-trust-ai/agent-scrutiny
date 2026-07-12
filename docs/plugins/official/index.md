# Official Plugins

Official plugins are maintained by the Agent Scrutiny team. They are the reference implementations for each plugin category and are bundled with the SDK starting in Stage 2.

> **Stage note.** The plugin *system* (base class, manager, registration) is
> available now in Stage 1, so you can build and register your own plugins today
> — see [Plugin Development](../plugin-development.md). The
> official plugins below, the `agent_scrutiny.plugins.official` import path, and
> the registry are **Stage 2**. The usage shown here reflects the real
> registration API so it will be correct when they ship.

---

## Registry

| Plugin | Category | Status | Description |
|---|---|---|---|
| [smart-contract-security](#smart-contract-security) | Threat Detector | Stage 2 — Planned | Detects risks in smart contract interactions including reentrancy, value limit violations, and unwhitelisted addresses. |

---

## smart-contract-security

> **Category:** Threat Detector · **Stage:** 2 · **Status:** In design

### What It Detects

This plugin secures agent interactions that involve smart contract calls. It catches:

- **Value limit violations** — Transfer requests that exceed per-currency limits configured by the operator.
- **Unwhitelisted addresses** — Transfers to destination addresses not on the approved list.
- **Unprompted transfers** — Agent output that initiates a transfer not requested in the input.
- **Reentrancy patterns** — Output that structures multiple sequential calls to the same contract in a pattern consistent with reentrancy exploitation.

### Configuration

These are the plugin's configuration options. They are supplied at initialization
time via `plugin_configs`, keyed by the plugin's name (see the example below);
once the registry ships they can also be declared in a `plugin.yaml` manifest.

```yaml
# Configuration values for smart-contract-security
chains:                 # supported chains
  - ethereum
  - polygon
  - arbitrum

value_limits:           # per-currency transfer limits
  eth: 1.0              # max 1 ETH per transfer
  usdc: 10000.0         # max $10,000 USDC per transfer
  matic: 1000.0

address_whitelist:      # approved destinations (null = all allowed)
  - "0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb"

reentrancy_detection: true
```

### Required Context

`interaction_type` on `AgentInteraction` is a fixed protocol enum
(`user_to_agent`, `agent_to_agent`, `agent_to_api`), so the domain classifier and
chain go in `context.metadata`. The plugin declares these keys in
`required_context()`:

| Metadata key | Type | Description |
|---|---|---|
| `interaction_class` | `string` | Must be `"smart_contract_interaction"` for the plugin to activate. |
| `chain` | `string` | The blockchain being used (e.g., `"ethereum"`). |

### Example

```python
import asyncio

from agent_scrutiny import Scrutinizer, PromptInjectionDetector
from agent_scrutiny.plugins.official import SmartContractSecurityPlugin  # Stage 2


async def main() -> None:
    scrutinizer = Scrutinizer(
        plugins=[
            PromptInjectionDetector(),
            SmartContractSecurityPlugin(),
        ],
    )

    # Configuration is routed to each plugin's initialize() by plugin name.
    await scrutinizer.initialize(
        plugin_configs={
            "smart-contract-security": {
                "chains": ["ethereum", "polygon"],
                "value_limits": {"eth": 1.0, "usdc": 10000.0},
                "address_whitelist": ["0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb"],
            },
        }
    )

    verdict = await scrutinizer.evaluate_interaction(
        agent_input="Transfer 100 ETH to 0x0000000000000000000000000000000000000000",
        agent_output="Initiating transfer of 100 ETH...",
        agent_id="defi-agent",
        metadata={
            "interaction_class": "smart_contract_interaction",
            "chain": "ethereum",
        },
    )

    print(verdict.is_blocked)   # True
    print(verdict.threats)

    await scrutinizer.shutdown()


asyncio.run(main())
```

---

## Contributing an Official Plugin

Community-created plugins can be proposed for official status if they:

1. Fill a gap that no existing plugin covers.
2. Are well-tested and well-documented.
3. Pass the conformance test suite *(Stage 2)*.
4. Are maintained by the contributor (or adopted by the core team).

To propose a plugin for official status, open a discussion with the `official-plugin-proposal` label.
