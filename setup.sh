#!/bin/sh
# setup.sh — Set up the marketplace for development.
#
# Usage:
#   ./setup.sh           Full setup (validate + install guild-skills plugin)
#   ./setup.sh --plugin  Install the guild-skills plugin only
#
# Requirements: Python 3.11+, pip, jaymd96-guild
# POSIX-compliant — works on Linux, macOS, and WSL.

set -eu

REPO_ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$REPO_ROOT"

# ── Helpers ──────────────────────────────────────────────────────────

info()  { printf '==> %s\n' "$1"; }
ok()    { printf '  ✓ %s\n' "$1"; }
fail()  { printf '  ✗ %s\n' "$1" >&2; exit 1; }

check_cmd() {
    command -v "$1" >/dev/null 2>&1 || fail "$1 not found. Please install it first."
}

# ── Actions ──────────────────────────────────────────────────────────

check_guild() {
    check_cmd guild
    ok "guild available"
}

run_validate() {
    info "Validating marketplace"
    guild validate
    ok "Validation passed"
}

run_build() {
    info "Building marketplace.json"
    guild build
    ok "Build complete"
}

install_plugin() {
    info "Installing guild-skills plugin for Claude Code"
    check_cmd guild
    guild setup-plugin "$REPO_ROOT/.claude/plugins"
    ok "Plugin installed to .claude/plugins/"
}

# ── Main ─────────────────────────────────────────────────────────────

MODE="${1:-full}"

case "$MODE" in
    --plugin)
        install_plugin
        ;;
    --help|-h)
        head -8 "$0" | tail -6
        exit 0
        ;;
    full|*)
        check_guild
        run_build
        run_validate
        install_plugin
        ;;
esac

info "Done"
