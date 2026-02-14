# Git Branching Methodology

> **Applies to:** `agent-scrutiny` · `agent-scrutiny-python` · `agent-scrutiny-rust`
> **Version:** 1.0
> **Last Updated:** February 2026

This document defines the branching strategy, naming conventions, merge rules, and release tagging standard used across all Agent Scrutiny repositories. All contributors — core team and community alike — are expected to follow it.

---

## Philosophy

Agent Scrutiny uses a lightweight variant of **GitHub Flow**, extended with a `develop` integration branch to protect `main` from partially-implemented stage work. The goals are:

- `main` is always deployable and always reflects published, reviewed work.
- `develop` is always buildable, but may contain in-progress stage features.
- History on `main` is clean and meaningful — each commit represents a completed stage or hotfix.
- The branching model should be simple enough that new contributors can onboard to it in minutes.

---

## Branch Structure

```
main                        ← production; docs site deploys from here
│
develop                     ← integration; all feature work lands here first
│
├── stage/2-mcp-plugins     ← optional stage branch for large, parallel efforts
│   ├── feat/plugin-registry
│   ├── feat/mcp-message-validator
│   └── feat/smart-contract-plugin
│
├── feat/rag-policy-engine  ← feature branches off develop
├── fix/verdict-risk-score
├── docs/threat-model-reentrancy
├── plugin/hipaa-compliance
└── hotfix/ci-deploy-broken ← branches off main; backported to develop
```

---

## Protected Branches

`main` and `develop` are **protected**. Direct pushes are disabled. All changes arrive via pull request.

| Branch | Protection Rules |
|---|---|
| `main` | Require PR · Require 1 approving review · Require all CI checks to pass · No force push · No deletion |
| `develop` | Require PR · Require 1 approving review · Require all CI checks to pass · No force push · No deletion |

No exceptions. Core team members follow the same rules as community contributors.

---

## Branch Types and Naming

All branches use a `type/short-description` convention with lowercase kebab-case descriptions.

| Prefix | Purpose | Branch from | Merges into | Examples |
|---|---|---|---|---|
| `feat/` | New capability or feature | `develop` (or `stage/N`) | `develop` (or `stage/N`) | `feat/scrutinizer-class`, `feat/plugin-registry` |
| `fix/` | Bug fix | `develop` | `develop` | `fix/broken-nav-link`, `fix/verdict-risk-score` |
| `docs/` | Documentation-only change | `develop` | `develop` | `docs/threat-model-reentrancy`, `docs/rust-install-guide` |
| `plugin/` | Plugin development | `develop` | `develop` | `plugin/smart-contract-security`, `plugin/hipaa-compliance` |
| `stage/` | Integration branch for a large stage | `develop` | `develop` | `stage/1-core`, `stage/2-mcp-plugins` |
| `hotfix/` | Critical production fix | `main` | `main` and `develop` | `hotfix/ci-deploy-broken` |
| `chore/` | Tooling, dependencies, CI maintenance | `develop` | `develop` | `chore/update-zensical`, `chore/ci-cleanup` |

### Naming Rules

- Use only lowercase letters, digits, and hyphens.
- Keep descriptions short but meaningful — 2–5 words is the target.
- Do not include your username or ticket numbers in the branch name (those belong in the PR description).
- Do not use generic names like `feat/updates` or `fix/stuff`.

---

## Workflows

### Standard Feature or Fix

The most common workflow. Used for any work that does not require a stage integration branch.

```
1.  Branch off develop
    git checkout develop && git pull
    git checkout -b feat/your-feature-name

2.  Do your work in commits
    git commit -m "feat: describe what this commit does"

3.  Keep your branch current (rebase, not merge)
    git fetch origin
    git rebase origin/develop

4.  Push and open a PR targeting develop
    git push origin feat/your-feature-name

5.  Address review feedback, then squash merge into develop
```

### Large Stage Work

Used when a stage involves many parallel PRs that would make `develop` noisy. The stage branch acts as a mini-`develop` for that stage.

```
1.  Core team creates the stage branch off develop
    git checkout develop && git pull
    git checkout -b stage/2-mcp-plugins
    git push origin stage/2-mcp-plugins

2.  Contributors branch feat/* off the stage branch
    git checkout stage/2-mcp-plugins
    git checkout -b feat/mcp-message-validator

3.  Feature PRs target the stage branch, not develop

4.  When the stage is feature-complete and reviewed,
    open one PR merging stage/N into develop
    (merge commit — preserves stage history)
```

### Stage Release to Production

Happens when a stage is complete, fully tested, and ready to publish.

```
1.  Open a PR from develop → main
    Title: "Release: Stage 1 — Scrutinizer Core"
    Description: summarize what's in the stage

2.  Require 2 approving reviews (elevated for production merges)

3.  Merge commit (no squash — preserves full stage history)

4.  Tag the merge commit on main
    git tag -a v0.2.0 -m "Stage 1 complete — Scrutinizer core and plugin foundation"
    git push origin v0.2.0

5.  The Zensical docs site (hub repo) and any release artifacts
    (Python package, Rust crate) deploy automatically from main
```

### Hotfix

Used only for critical production issues that cannot wait for the normal `develop → main` cycle.

```
1.  Branch off main (not develop)
    git checkout main && git pull
    git checkout -b hotfix/description

2.  Make the minimal fix — this is not the place for refactoring

3.  Open two PRs simultaneously:
      PR 1: hotfix/description → main  (get this deployed fast)
      PR 2: hotfix/description → develop  (keep develop current)

4.  Tag the main merge
    git tag -a v0.2.1 -m "Hotfix: description of the fix"
    git push origin v0.2.1
```

---

## Pull Request Standards

Every PR — regardless of size, author, or urgency — must meet these standards before it can be merged.

### Required Elements

- **Title** uses conventional commit format: `type: short description`
  - `feat: add prompt injection detector`
  - `fix: handle empty input in validator`
  - `docs: update MCP security threat model`
  - `plugin: add smart contract security plugin`

- **Description** answers three questions:
  1. What did you change?
  2. Why did you change it?
  3. How can a reviewer verify it works?

- **Size** is focused. One PR per feature or fix. If your PR touches more than ~400 lines across unrelated concerns, consider splitting it.

### Required Checks (All Repos)

All CI checks must pass before a PR can be merged. Specifically:

| Check | Hub Repo | Python Repo | Rust Repo |
|---|---|---|---|
| Zensical docs build | ✓ | — | — |
| pytest (80%+ coverage) | — | ✓ | — |
| cargo test | — | — | ✓ |
| flake8 / mypy | — | ✓ | — |
| cargo clippy / rustfmt | — | — | ✓ |
| bandit / safety (security scan) | — | ✓ | — |

### Reviews

- Every PR requires **at least 1 approving review**.
- `develop → main` release PRs require **2 approving reviews**.
- **No self-merges.** Even if you have merge permissions, you must have another reviewer approve your own PRs.
- Reviewers check: correctness, test coverage, documentation, security implications, and adherence to this branching standard.

---

## Merge Strategy

| PR type | Merge strategy | Rationale |
|---|---|---|
| `feat/`, `fix/`, `docs/`, `plugin/`, `chore/` → `develop` | **Squash merge** | Keeps `develop` history clean; one logical commit per unit of work |
| `stage/N` → `develop` | **Merge commit** | Preserves the history of how the stage was assembled |
| `develop` → `main` | **Merge commit** | Preserves full stage history; makes the release boundary clear |
| `hotfix/` → `main` | **Fast-forward** or **merge commit** | Either is acceptable; tag the result either way |
| `hotfix/` → `develop` | **Merge commit** | Preserves the hotfix as a distinct event in develop's history |

**Rebase policy:** Rebase your feature branch on top of `develop` (or `stage/N`) before opening a PR. Do not merge `develop` into your branch — this clutters history with noise merge commits.

```bash
# Keep your branch current via rebase, not merge
git fetch origin
git rebase origin/develop
```

---

## Commit Message Standard

All commits follow the [Conventional Commits](https://www.conventionalcommits.org/) specification.

### Format

```
<type>: <short description>

<optional body — explain why, not what>

<optional footer — e.g., Closes #42, BREAKING CHANGE: ...>
```

### Types

| Type | When to use |
|---|---|
| `feat` | A new capability |
| `fix` | A bug fix |
| `docs` | Documentation only |
| `plugin` | Plugin additions or changes |
| `test` | Adding or updating tests |
| `refactor` | Code change that is neither a fix nor a feature |
| `perf` | Performance improvement |
| `chore` | Build system, CI, dependency updates |
| `revert` | Reverting a previous commit |

### Examples

```
feat: add prompt injection detector with pattern library

fix: handle empty agent_output in Scrutinizer.evaluate()

docs: add reentrancy pattern to threat model

plugin: add financial-transfer-guard with value limit enforcement

test: add edge cases for MCP message replay detection

chore: update zensical to 0.0.17
```

### Rules

- Use the imperative mood: "add feature" not "added feature" or "adds feature."
- Keep the first line under 72 characters.
- Do not end the first line with a period.
- Reference issues in the footer, not the subject line.

---

## Tagging and Versioning

Releases are tagged on `main` using annotated tags. Tags are permanent — never delete or move a tag.

### Version Format

Agent Scrutiny follows [Semantic Versioning](https://semver.org/): `MAJOR.MINOR.PATCH`.

| Version bump | When |
|---|---|
| `MINOR` | Stage release (`0.1.0` → `0.2.0`) |
| `PATCH` | Hotfix (`0.2.0` → `0.2.1`) |
| `MAJOR` | Breaking changes to the plugin specification or public API |

During Stage 0, all versions are `0.x.y`. The first production-ready release (Stage 5 complete) will be `1.0.0`.

### Tagging a Release

```bash
# After merging develop → main for a stage release
git checkout main && git pull
git tag -a v0.2.0 -m "Stage 1 complete — Scrutinizer core and plugin foundation"
git push origin v0.2.0
```

### Tag Naming

| Event | Tag format | Example |
|---|---|---|
| Stage release | `vMAJOR.MINOR.0` | `v0.2.0` |
| Hotfix | `vMAJOR.MINOR.PATCH` | `v0.2.1` |
| Pre-release / alpha | `vMAJOR.MINOR.0-alpha.N` | `v0.2.0-alpha.1` |

---

## Cross-Repository Coordination

The three repositories are independent but coordinated. The hub defines contracts; the implementations follow.

### Rule: Spec Before Implementation

Do not merge a stage to `main` in `agent-scrutiny-python` or `agent-scrutiny-rust` until the corresponding specification changes (architecture, plugin spec, threat model) have landed on `main` in `agent-scrutiny` (the hub).

```
Hub repo:     Stage N spec merged to main   ← must happen first
                        │
Python repo:  Stage N implementation merged to main
Rust repo:    Stage N implementation merged to main
```

### Rule: Plugin Spec Changes Are Breaking

Any change to `docs/plugins/plugin-specification.md` in the hub that alters the plugin interface contract must:

1. Bump the specification version in that document.
2. Trigger a `MINOR` version bump in both SDK repos when the change ships to their `main`.
3. Be called out explicitly in the release PR description.

### Rule: Hotfixes Are Repo-Local

A hotfix in one repository does not automatically trigger hotfixes in the others. Each repo responds to issues in its own release cycle unless a critical shared specification error is discovered — in which case the hub repo hotfix takes priority.

---

## Quick Reference Card

```
New feature or fix
  git checkout develop && git pull
  git checkout -b feat/your-feature
  # ... work ...
  git rebase origin/develop
  # Open PR → develop (squash merge)

Stage release
  # Open PR: develop → main (merge commit, 2 reviews)
  git tag -a vX.Y.0 -m "Stage N complete — description"
  git push origin vX.Y.0

Hotfix
  git checkout main && git pull
  git checkout -b hotfix/description
  # ... minimal fix ...
  # Open PR → main  AND  PR → develop
  git tag -a vX.Y.Z -m "Hotfix: description"
  git push origin vX.Y.Z
```

---

## Enforcement

This standard is enforced through:

1. **GitHub branch protection rules** on `main` and `develop` in all three repositories.
2. **CI checks** that block merges when tests, linting, or the docs build fails.
3. **Code review** — reviewers are expected to flag PRs that violate naming conventions or merge strategy.

Questions about this standard? Open a discussion in the [agent-scrutiny hub](https://github.com/zero-trust-ai/agent-scrutiny/discussions) with the label `process`.