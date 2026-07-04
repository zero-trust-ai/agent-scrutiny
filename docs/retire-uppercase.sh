#!/usr/bin/env bash
#
# retire-uppercase.sh
#
# Retires the legacy uppercase documentation files that now have canonical
# lowercase (Zensical) equivalents. It NEVER deletes an uppercase file unless
# its lowercase twin is actually tracked in git — so you can't lose content by
# deleting a file whose replacement isn't there yet.
#
# Two files are intentionally NOT auto-deleted and are only reported:
#   - docs/PROJECT-STRUCTURE.md  (its twin docs/project-structure.md is also
#     stale — reconcile before deleting either)
#   - CONTRIBUTING.md            (a GitHub-convention file — replace with a
#     pointer to docs/contributing.md rather than plain-deleting)
#
# Run this from the HUB repo root (agent-scrutiny). If the python/rust repos
# carry their own uppercase doc copies, run it there too.
#
# Usage:
#   ./retire-uppercase.sh            # dry run — shows what would be removed
#   ./retire-uppercase.sh --apply    # actually git rm the safe deletions
#
set -euo pipefail

APPLY=false
[[ "${1:-}" == "--apply" ]] && APPLY=true

git rev-parse --is-inside-work-tree >/dev/null 2>&1 || {
  echo "error: not inside a git repository" >&2
  exit 1
}
cd "$(git rev-parse --show-toplevel)"

mapfile -t ALL < <(git ls-files)
is_tracked() { printf '%s\n' "${ALL[@]}" | grep -Fxq "$1"; }

# uppercase_path : required_lowercase_twin
RETIRE=(
  "docs/ARCHITECTURE.md:docs/architecture.md"
  "docs/THREAT-MODEL.md:docs/threat-model.md"
  "docs/ZERO-TRUST-PRINCIPLES.md:docs/zero-trust-principles.md"
  "docs/GETTING-STARTED.md:docs/getting-started.md"
  "ROADMAP.md:docs/roadmap.md"
)

REVIEW=(
  "docs/PROJECT-STRUCTURE.md|twin docs/project-structure.md is ALSO stale — reconcile first"
  "CONTRIBUTING.md|GitHub-convention file — replace with a pointer to docs/contributing.md"
)

removed=(); skipped_missing_twin=(); skipped_absent=()

for pair in "${RETIRE[@]}"; do
  upper="${pair%%:*}"
  twin="${pair##*:}"

  if ! is_tracked "$upper"; then
    skipped_absent+=("$upper (already gone)")
    continue
  fi
  if ! is_tracked "$twin"; then
    skipped_missing_twin+=("$upper (twin $twin NOT found — kept)")
    continue
  fi

  removed+=("$upper  (twin: $twin)")
  if $APPLY; then
    git rm --quiet "$upper"
  fi
done

hr() { printf '%s\n' "------------------------------------------------------------"; }

echo
$APPLY && echo "MODE: APPLY (deletions staged via git rm)" \
        || echo "MODE: DRY RUN (no changes — re-run with --apply to execute)"
hr

printf 'Retired (%d):\n' "${#removed[@]}"
((${#removed[@]})) && printf '  git rm %s\n' "${removed[@]%% *}" || echo "  (none)"
echo

printf 'Kept — twin missing (%d):\n' "${#skipped_missing_twin[@]}"
((${#skipped_missing_twin[@]})) && printf '  %s\n' "${skipped_missing_twin[@]}" || echo "  (none)"
echo

printf 'Already absent (%d):\n' "${#skipped_absent[@]}"
((${#skipped_absent[@]})) && printf '  %s\n' "${skipped_absent[@]}" || echo "  (none)"
echo

printf 'Needs manual decision (NOT touched):\n'
for item in "${REVIEW[@]}"; do
  f="${item%%|*}"; why="${item##*|}"
  if is_tracked "$f"; then printf '  %s — %s\n' "$f" "$why"; fi
done
hr

if $APPLY && ((${#removed[@]})); then
  echo "Next:"
  echo "  1. Fix inbound links to the deleted files (see the README fixes)."
  echo "  2. git commit -m 'docs: retire legacy uppercase docs in favor of Zensical set'"
fi
