# Installation — Rust SDK

> **Status:** Stage 0 — The Rust SDK repository is being set up. Installation instructions will be finalized when the first crate is published.

---

## Prerequisites

- **Rust** (stable toolchain, 1.75+). Install via [rustup](https://www.rs-lang.org/tools/install.html).
- **Cargo** (bundled with Rust).
- **Git**.

Verify your Rust installation:

```bash
rustc --version     # rustc 1.75.0 or later
cargo --version     # cargo 1.75.0 or later
```

---

## Option 1 — Add as a Cargo Dependency *(coming in Stage 1)*

Once the first crate is published to [crates.io](https://crates.io):

```toml
# Cargo.toml
[dependencies]
scrutiny-core = "0.1"
```

This is not yet available.

---

## Option 2 — Build from Source (Current)

```bash
# Clone the repository
git clone https://github.com/zero-trust-ai/agent-scrutiny-rust.git
cd agent-scrutiny-rust

# Build all crates
cargo build

# Run the test suite
cargo test
```

---

## Option 3 — Development Setup (For Contributors)

```bash
# Everything in Option 2, plus:

# Install additional dev tools
cargo install cargo-clippy       # linting
cargo install cargo-fmt          # formatting
cargo install cargo-nextest      # faster test runner (optional)

# Run lints
cargo clippy

# Check formatting
cargo fmt -- --check

# Run tests with coverage (requires nightly)
rustup run nightly cargo install cargo-llvm-cov
cargo llvm-cov --workspace
```

---

## Workspace Crates

The Rust SDK is a Cargo workspace. Each crate can be used independently:

| Crate | Purpose | Use When |
|---|---|---|
| `scrutiny-core` | Scrutinizer engine | You want the evaluation pipeline |
| `scrutiny-detectors` | Threat detectors | You need prompt injection or exfiltration detection |
| `scrutiny-plugins` | Plugin trait + manager | You're writing a Rust plugin |
| `scrutiny-mcp` | MCP security | You're securing agent-to-agent communication |
| `scrutiny-cli` | CLI tool | You want a command-line interface |

Minimal dependency for most users:

```toml
[dependencies]
scrutiny-core = "0.1"
scrutiny-detectors = "0.1"
```

---

## Troubleshooting

**Compilation errors about missing features**

Make sure you're on a recent stable Rust toolchain:

```bash
rustup update stable
rustup default stable
```

**Tests fail with linking errors**

Some crates (e.g., `scrutiny-mcp` with cryptographic operations) may require system libraries. On Linux:

```bash
sudo apt install libssl-dev pkg-config
```

On macOS, these are typically included with Xcode command-line tools:

```bash
xcode-select --install
```
