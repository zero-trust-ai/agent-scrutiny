# Project Structure

This page maps the **agent-scrutiny-python** repository — the reference SDK.

Shared documentation (architecture, threat model, plugin specification, roadmap)
lives in the **hub** repository (`agent-scrutiny`) and is published on this site.
It is *not* duplicated in the SDK repo, so you won't find a `docs/` tree of shared
specs here.

---

## Current Layout (Stage 1)

```
agent-scrutiny-python/
│
├── README.md                    # SDK overview and quick start
├── LICENSE                      # MIT
├── setup.py                     # reads deps from requirements*.txt (single source of truth)
├── requirements.txt             # production dependencies
├── requirements-dev.txt         # dev / test dependencies
├── pytest.ini                   # pytest configuration
├── pyrightconfig.json           # Pyright/Pylance config (excludes .venv)
├── MANIFEST.in                  # sdist include rules
├── .gitignore
│
├── .github/
│   └── workflows/
│       └── ci.yml               # CI: tests, lint, type-check, coverage
│
├── src/
│   └── agent_scrutiny/
│       ├── __init__.py          # public API exports; __version__
│       ├── models.py            # Pydantic models + enums
│       ├── core.py              # Scrutinizer + Mode
│       │
│       ├── detectors/           # built-in detectors (each is a Plugin)
│       │   ├── __init__.py
│       │   ├── prompt_injection.py     # PromptInjectionDetector
│       │   ├── input_validator.py      # InputValidator
│       │   └── data_exfiltration.py    # DataExfiltrationDetector
│       │
│       ├── plugins/             # plugin system
│       │   ├── __init__.py
│       │   ├── base.py          # Plugin abstract base class
│       │   └── manager.py       # PluginManager (parallel eval, fail-closed)
│       │
│       └── policies/            # policy system
│           ├── __init__.py
│           ├── base.py          # Policy abstract base class
│           ├── engine.py        # PolicyEngine (sequential, fail-closed)
│           └── builtin.py       # ThresholdPolicy, ThreatCategoryPolicy,
│                                #   AgentAllowlistPolicy, RequireMultipleThreatsPolicy
│
├── tests/                       # pytest + pytest-asyncio; one module per component
│
└── examples/
    └── basic_usage.py           # runnable Scrutinizer example
```

---

## Module Responsibilities

| Module | Responsibility |
|---|---|
| `models.py` | Frozen Pydantic models (`AgentInteraction`, `EvaluationContext`, `PluginVerdict`, `SecurityVerdict`) and enums (`Decision`, `InteractionType`, `Severity`). All models use `ConfigDict(extra="forbid", frozen=True)`. |
| `core.py` | The `Scrutinizer` orchestrator and the `Mode` enum. Runs the four-phase pipeline: parallel plugin evaluation → aggregation → policy transformation → mode application. |
| `detectors/` | Built-in detectors. Each subclasses `Plugin` and runs through the same pipeline as third-party plugins. |
| `plugins/base.py` | The `Plugin` contract every plugin implements. |
| `plugins/manager.py` | Loads plugins, runs them in parallel, and aggregates verdicts ("most severe wins"). Fails closed on plugin errors. |
| `policies/base.py` | The `Policy` contract. |
| `policies/engine.py` | Applies policies sequentially after aggregation. Fails closed on policy errors. |
| `policies/builtin.py` | The shipped policies (threshold, threat-category, agent-allowlist, require-multiple-threats). |

---

## Planned Additions (Later Stages)

These directories do not exist yet; they are introduced as their stages land:

| Path | Stage | Purpose |
|---|---|---|
| `plugins/registry.py`, `plugins/official/` | 2 | Plugin discovery and official plugin bundle |
| `mcp/` | 2 | MCP message-signing / transport security |
| `rag/` | 3 | RAG-backed dynamic policies |
| `multi_agent/` | 4 | Behavioral profiling and anomaly detection |
| `cli.py` | 2+ | Command-line interface (the `console_scripts` entry point in `setup.py` is reserved for it) |

---

## Conventions

- **Python files:** `lowercase_with_underscores.py`
- **Test files:** `test_*.py`, mirroring the package layout
- **Documentation:** `lowercase-kebab-case.md` — the Zensical convention. (The
  project previously used `UPPERCASE.md` for top-level docs; that convention is
  retired.)
- **Classes:** `PascalCase` · **Functions:** `snake_case` · **Constants:** `UPPER_SNAKE_CASE`
- **Pydantic models:** always `ConfigDict(extra="forbid", frozen=True)`
- **Detectors with pattern libraries** expose a frozen `Pattern` model, a
  `DEFAULT_PATTERNS` tuple, a `DEFAULT_PATTERN_LIBRARY_VERSION`, and a constructor
  taking `custom_patterns` plus `include_defaults=True`.

---

## Adding a New Component

1. **Create the module** in the appropriate package (`detectors/`, `plugins/`, `policies/`).
2. **Add tests** in `tests/`, mirroring the package path.
3. **Update `__init__.py`** to export any new public API.
4. **Document it** — update the relevant page in the hub docs (and the API reference).
5. **Add an example** in `examples/` if it introduces a user-facing capability.
6. If the change affects staging, **update the roadmap** in the hub repository.

---

## The `src/` Layout

The package lives under `src/` rather than at the repo root. This prevents
accidental imports of the in-tree package before it's installed, so tests always
run against the installed (editable) package — install with `pip install -e .`
(or `pip install -e ".[dev]"` for the test toolchain).

---

*Last updated for: Stage 1 (Python SDK complete).*
