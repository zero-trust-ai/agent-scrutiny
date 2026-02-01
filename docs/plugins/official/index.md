# Official Plugins

Official plugins are maintained by the Agent Scrutiny team. They are the reference implementations for each plugin category and are bundled with the SDK starting in Stage 2.

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

```yaml
# In your Scrutinizer configuration or plugin load call:

plugin: smart-contract-security
config:
  # Supported chains
  chains:
    - ethereum
    - polygon
    - arbitrum

  # Per-currency transfer limits
  value_limits:
    eth: 1.0          # Max 1 ETH per transfer
    usdc: 10000.0     # Max $10,000 USDC per transfer
    matic: 1000.0

  # Approved destination addresses (null = all addresses allowed)
  address_whitelist:
    - "0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb"
    - "0x..."

  # Whether to flag reentrancy patterns
  reentrancy_detection: true
```

### Required Context

The interaction context must include:

| Key | Type | Description |
|---|---|---|
| `interaction_type` | `string` | Must be `"smart_contract_interaction"` for the plugin to activate |
| `chain` | `string` | The blockchain being used (e.g., `"ethereum"`) |

### Example

```python
from agent_scrutiny import Scrutinizer
from agent_scrutiny.plugins.official import SmartContractSecurityPlugin

scrutinizer = Scrutinizer(policies=["prompt-injection"])
scrutinizer.load_plugin(
    SmartContractSecurityPlugin(),
    config={
        "chains": ["ethereum", "polygon"],
        "value_limits": {"eth": 1.0, "usdc": 10000.0},
        "address_whitelist": ["0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb"],
    },
)
```

---

## Contributing an Official Plugin

Community-created plugins can be proposed for official status if they:

1. Fill a gap that no existing plugin covers.
2. Are well-tested and well-documented.
3. Pass the conformance test suite.
4. Are maintained by the contributor (or adopted by the core team).

To propose a plugin for official status, open a discussion with the `official-plugin-proposal` label.

---

## Community Plugins

Community-contributed plugins are listed separately and are not maintained by the Agent Scrutiny team. They are discovered through the plugin registry (Stage 2). When evaluating a community plugin, check its:

- Maintenance status (last commit date)
- Test coverage
- Issue tracker responsiveness
- License compatibility (MIT or Apache-2.0 recommended)
