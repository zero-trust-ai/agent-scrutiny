# API Reference — Rust SDK

> **Status:** Stage 0 — This page documents the *planned* API. Trait definitions and struct layouts will be finalized when Stage 1 implementation begins.

---

## `scrutiny-core` — Scrutinizer Engine

### `Scrutinizer`

The central evaluation engine. Thread-safe and designed for concurrent use.

```rust
use scrutiny_core::{Scrutinizer, ScrutinizerConfig, SecurityVerdict};

// Create a Scrutinizer
let config = ScrutinizerConfig {
    policies: vec!["prompt-injection".into(), "data-exfiltration".into()],
    mode: Mode::Strict,
    log_level: LogLevel::Info,
    ..Default::default()
};

let scrutinizer = Scrutinizer::new(config)?;

// Evaluate an interaction
let verdict = scrutinizer.evaluate(EvaluationRequest {
    agent_input:  "What is the weather?".into(),
    agent_output: "I don't have real-time data.".into(),
    context:      Some(context_map),
})?;

// Async variant
let verdict = scrutinizer.evaluate_async(request).await?;
```

### `SecurityVerdict`

```rust
pub struct SecurityVerdict {
    pub is_safe:            bool,
    pub risk_score:         f64,                    // 0.0 – 1.0
    pub threat_type:        Option<String>,
    pub threat_types:       Vec<String>,
    pub threats_detected:   usize,
    pub explanation:        String,
    pub matched_patterns:   Vec<String>,
    pub violated_policies:  Vec<String>,
    pub plugin_details:     HashMap<String, serde_json::Value>,
    pub recommendation:     Option<String>,
}
```

### `ScrutinizerConfig`

```rust
pub struct ScrutinizerConfig {
    pub policies:        Vec<String>,
    pub custom_policies: Vec<PolicyDefinition>,
    pub mode:            Mode,
    pub log_level:       LogLevel,
}

pub enum Mode {
    Strict,       // Block on any threat signal
    Permissive,   // Log but allow
}
```

---

## `scrutiny-plugins` — Plugin System

### `SecurityPlugin` Trait

Every plugin implements this trait. It mirrors the Python `SecurityPlugin` abstract base class exactly.

```rust
use scrutiny_plugins::{SecurityPlugin, PluginVerdict};

pub trait SecurityPlugin: Send + Sync {
    /// Unique plugin identifier (kebab-case).
    fn name(&self) -> &str;

    /// Semantic version string.
    fn version(&self) -> &str;

    /// One-sentence summary.
    fn description(&self) -> &str;

    /// Context keys this plugin requires.
    fn required_context(&self) -> Vec<&str> {
        vec![]
    }

    /// Called once when the plugin is loaded.
    fn initialize(&mut self, config: &serde_json::Value) -> Result<(), Box<dyn std::error::Error>> {
        Ok(())
    }

    /// Core detection logic. Called for every interaction.
    fn evaluate(
        &self,
        agent_input:  &str,
        agent_output: &str,
        context:      &HashMap<String, serde_json::Value>,
    ) -> PluginVerdict;

    /// Called when the plugin is unloaded.
    fn shutdown(&mut self) {}
}
```

### `PluginVerdict`

```rust
pub struct PluginVerdict {
    pub is_safe:    bool,
    pub reason:     String,
    pub risk_score: f64,    // 0.0 – 1.0; 0.0 if is_safe == true
}
```

### Plugin Registration

```rust
use scrutiny_core::Scrutinizer;
use my_plugin::MyPlugin;

let mut scrutinizer = Scrutinizer::new(config)?;

scrutinizer.load_plugin(
    Box::new(MyPlugin::new()),
    &serde_json::json!({
        "value_limits": { "eth": 1.0 }
    }),
)?;
```

---

## `scrutiny-detectors` — Core Detectors

Detectors are not plugins — they are built into the core evaluation pipeline. They are exposed here for configuration purposes.

```rust
use scrutiny_detectors::DetectorConfig;

let detector_config = DetectorConfig {
    prompt_injection: PromptInjectionConfig {
        pattern_library: PatternLibrary::Default,
        sensitivity: Sensitivity::High,
    },
    input_validator: InputValidatorConfig {
        max_input_length: 10_000,
        allowed_encodings: vec!["utf-8".into()],
    },
    data_exfiltration: DataExfiltrationConfig {
        scan_output: true,
        custom_patterns: vec![],
    },
};
```

---

## `scrutiny-mcp` — MCP Security *(Stage 2)*

```rust
use scrutiny_mcp::{MCPScrutinizer, Message, ValidationResult};

let mcp = MCPScrutinizer::new(trust_policy)?;

let result: ValidationResult = mcp.validate_message(&message)?;

match result {
    ValidationResult::Valid => { /* process */ }
    ValidationResult::Invalid { reason } => { /* log and drop */ }
}
```

---

## Error Handling

The Rust SDK uses the standard `Result<T, E>` pattern. All fallible operations return typed errors:

```rust
use scrutiny_core::error::ScrutinyError;

pub enum ScrutinyError {
    InvalidInput(String),
    PolicyNotFound(String),
    PluginError { plugin: String, source: Box<dyn std::error::Error> },
    ConfigurationError(String),
}
```

All error variants implement `Display` and `std::error::Error`, and are compatible with the `?` operator and `anyhow`.
