# Installation — Python SDK

---

## Prerequisites

- **Python 3.9 or later**
- **pip** (bundled with Python)
- **Git** (if installing from source or contributing)

---

## Option 1 — Install from PyPI *(coming in Stage 1)*

Once the first release is published, installation will be:

```bash
pip install agent-scrutiny
```

This is not yet available. Use Option 2 in the meantime.

---

## Option 2 — Install from Source (Current)

```bash
# Clone the repository
git clone https://github.com/zero-trust-ai/agent-scrutiny-python.git
cd agent-scrutiny-python

# Create and activate a virtual environment (recommended)
python -m venv venv
source venv/bin/activate          # Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Install the package in editable mode
pip install -e .
```

### Verify the Installation

```bash
python -c "import agent_scrutiny; print(agent_scrutiny.__version__)"
# Expected output: 0.1.0-dev
```

---

## Option 3 — Development Setup (For Contributors)

If you plan to contribute code or run the full test suite:

```bash
# Everything in Option 2, plus:
pip install -r requirements-dev.txt

# Run the test suite
pytest

# Run with coverage report
pytest --cov=agent_scrutiny --cov-report=term-missing
```

### Development Dependencies

The `requirements-dev.txt` file includes:

| Tool | Purpose |
|---|---|
| pytest | Test runner |
| pytest-cov | Coverage reporting |
| pytest-asyncio | Async test support |
| pytest-mock | Mocking utilities |
| black | Code formatter |
| isort | Import sorter |
| flake8 | Linter |
| mypy | Type checker |
| pre-commit | Git hook manager |

### Set Up Pre-Commit Hooks

```bash
pre-commit install
# Hooks now run automatically on every git commit
```

This ensures your code passes formatting and linting checks before it's committed.

---

## Dependencies

### Production (`requirements.txt`)

| Package | Version | Purpose |
|---|---|---|
| python-dotenv | ≥1.0.0 | Environment variable management |
| pydantic | ≥2.5.0 | Data validation and serialization |
| typing-extensions | ≥4.9.0 | Backported typing features |
| structlog | ≥24.1.0 | Structured logging |
| colorama | ≥0.4.6 | Cross-platform terminal colors |
| pyyaml | ≥6.0.1 | YAML configuration parsing |
| cryptography | ≥41.0.0 | Cryptographic operations (MCP layer) |

---

## Troubleshooting

**`ModuleNotFoundError: No module named 'agent_scrutiny'`**

You forgot `pip install -e .` or your virtual environment is not activated. Run:

```bash
source venv/bin/activate
pip install -e .
```

**Tests fail with import errors**

Make sure you installed dev dependencies:

```bash
pip install -r requirements-dev.txt
```

**Python version too old**

Agent Scrutiny requires Python 3.9+. Check your version:

```bash
python --version
```
