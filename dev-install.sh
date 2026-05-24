#!/usr/bin/env bash
# ShadowRepo — Local-dev shell alias installer (contributors only).
#
# Adds a `claude-sr` alias that runs `claude --plugin-dir <this repo>`,
# so edits to the source are picked up live (via /reload-plugins mid-session).
# End-users should install via marketplace instead:
#   /plugin marketplace add VW-ai/ShadowRepo-Skill
#   /plugin install shadowrepo@shadowrepo
#
# Dual-mode: source or execute
#
# Recommended (alias active immediately in current shell):
#   source ./dev-install.sh
#
# Also works as a plain script (alias only active in NEW shells until you
# run `source ~/.zshrc`):
#   ./dev-install.sh
#
# Subcommands:
#   source ./dev-install.sh remove   # or:  ./dev-install.sh remove

# ─── Detect whether we are sourced or executed ──────────
if (return 0 2>/dev/null); then
  _SR_SOURCED=1
else
  _SR_SOURCED=0
fi

# Don't pollute caller's shell options when sourced; fail fast when executed.
[ "$_SR_SOURCED" = "1" ] || set -e

# ─── Resolve repo root (works in bash and zsh, sourced or executed) ──
if [ -n "${BASH_SOURCE[0]:-}" ]; then
  _SR_SCRIPT="${BASH_SOURCE[0]}"
else
  _SR_SCRIPT="${(%):-%x}"   # zsh-only fallback
  [ -z "$_SR_SCRIPT" ] && _SR_SCRIPT="$0"
fi
REPO_ROOT="$(cd "$(dirname "$_SR_SCRIPT")" 2>/dev/null && pwd)"

ALIAS_NAME="claude-sr"
ALIAS_LINE="alias ${ALIAS_NAME}='claude --plugin-dir ${REPO_ROOT}'"
MARKER_BEGIN="# >>> shadowrepo plugin alias >>>"
MARKER_END="# <<< shadowrepo plugin alias <<<"

LEGACY_SKILLS_DIR="$HOME/.claude/skills"
LEGACY_NAMES=(shadowrepo shadowrepo-build shadowrepo-check shadowrepo-update shadowrepo-render shadowrepo-preview shadowrepo-help)

# Bail helper: return when sourced, exit when executed
_sr_bail() {
  local code="${1:-0}"
  _sr_cleanup
  if [ "$_SR_SOURCED" = "1" ]; then
    return "$code" 2>/dev/null || true
  else
    exit "$code"
  fi
}

_sr_cleanup() {
  unset -f _sr_detect_rc _sr_sed_inplace _sr_escape_sed _sr_clean_legacy 2>/dev/null
  unset _SR_SCRIPT MARKER_BEGIN MARKER_END EXISTING MODE TITLE ALIAS_STATUS 2>/dev/null
}

# ─── Detect shell rc file ───────────────────────────────
_sr_detect_rc() {
  case "$(basename "${SHELL:-/bin/zsh}")" in
    zsh)  echo "$HOME/.zshrc" ;;
    bash)
      if [ -f "$HOME/.bashrc" ]; then
        echo "$HOME/.bashrc"
      else
        echo "$HOME/.bash_profile"
      fi
      ;;
    fish)
      cat >&2 <<EOF
fish shell detected. Add this to ~/.config/fish/config.fish manually:
  alias ${ALIAS_NAME} 'claude --plugin-dir ${REPO_ROOT}'
EOF
      return 1
      ;;
    *)
      cat >&2 <<EOF
Unknown shell ($SHELL). Add this to your shell rc manually:
  ${ALIAS_LINE}
EOF
      return 1
      ;;
  esac
}

if ! RC="$(_sr_detect_rc)"; then
  _sr_bail 1
fi

# ─── Portable in-place edit that follows symlinks ───────
_sr_sed_inplace() {
  local script="$1"
  local file="$2"
  local tmp
  tmp="$(mktemp)"
  sed "$script" "$file" > "$tmp" && cat "$tmp" > "$file"
  rm -f "$tmp"
}

_sr_escape_sed() {
  printf '%s\n' "$1" | sed 's/[[\.*^$/]/\\&/g'
}

# ─── Clean up legacy skill-symlink install (pre-plugin) ─
_sr_clean_legacy() {
  local removed=0
  for name in "${LEGACY_NAMES[@]}"; do
    local target="$LEGACY_SKILLS_DIR/$name"
    if [ -L "$target" ]; then
      rm "$target" && removed=$((removed + 1))
    fi
  done
  echo "$removed"
}

# ─── Uninstall ──────────────────────────────────────────
if [ "${1:-}" = "remove" ]; then
  legacy_removed="$(_sr_clean_legacy)"
  alias_removed=0
  if [ -f "$RC" ] && grep -qF "$MARKER_BEGIN" "$RC"; then
    _sr_sed_inplace "/$(_sr_escape_sed "$MARKER_BEGIN")/,/$(_sr_escape_sed "$MARKER_END")/d" "$RC"
    if [ "$_SR_SOURCED" = "1" ]; then
      unalias "$ALIAS_NAME" 2>/dev/null || true
    fi
    alias_removed=1
  fi

  echo ""
  echo "  ◆ ShadowRepo — Uninstalled"
  [ "$alias_removed" = "1" ] && echo "    Alias removed from $RC"
  [ "$legacy_removed" -gt 0 ] && echo "    Removed $legacy_removed legacy skill symlinks from $LEGACY_SKILLS_DIR"
  [ "$alias_removed" = "0" ] && [ "$legacy_removed" = "0" ] && echo "    Nothing to remove."
  echo ""
  _sr_bail 0
fi

# ─── Detect existing install ────────────────────────────
MODE="install"
if [ -f "$RC" ] && grep -qF "$MARKER_BEGIN" "$RC"; then
  EXISTING="$(awk -v b="$MARKER_BEGIN" -v e="$MARKER_END" '
    $0 == b { in_block = 1; next }
    $0 == e { in_block = 0; next }
    in_block && /^alias/ { print; exit }
  ' "$RC")"
  if [ "$EXISTING" = "$ALIAS_LINE" ]; then
    MODE="already"
  else
    MODE="update"
  fi
fi

# ─── Migrate: clean legacy symlinks if any exist ────────
LEGACY_CLEANED="$(_sr_clean_legacy)"

# ─── Install / Update — write to rc file ────────────────
if [ "$MODE" != "already" ]; then
  if [ -f "$RC" ] && grep -qF "$MARKER_BEGIN" "$RC"; then
    _sr_sed_inplace "/$(_sr_escape_sed "$MARKER_BEGIN")/,/$(_sr_escape_sed "$MARKER_END")/d" "$RC"
  fi
  {
    echo ""
    echo "$MARKER_BEGIN"
    echo "$ALIAS_LINE"
    echo "$MARKER_END"
  } >> "$RC"
fi

# ─── If sourced, define alias in caller's shell now ─────
if [ "$_SR_SOURCED" = "1" ]; then
  eval "$ALIAS_LINE"
  ALIAS_STATUS="active in this shell"
else
  ALIAS_STATUS="run \`source $RC\` to activate (or open a new terminal)"
fi

# ─── Output ─────────────────────────────────────────────
case "$MODE" in
  already) TITLE="ShadowRepo — Alias already installed (verified)" ;;
  update)  TITLE="ShadowRepo — Alias updated" ;;
  *)       TITLE="ShadowRepo — Alias installed" ;;
esac

cat <<EOF

  ◆ $TITLE

  Shell rc:  $RC
  Alias:     $ALIAS_NAME ($ALIAS_STATUS)
  Plugin:    $REPO_ROOT

EOF

if [ "$LEGACY_CLEANED" -gt 0 ]; then
  cat <<EOF
  Migrated:  removed $LEGACY_CLEANED legacy skill symlinks from $LEGACY_SKILLS_DIR
             (ShadowRepo is now loaded as a plugin instead)

EOF
fi

cat <<EOF
  Run:     $ALIAS_NAME            # start Claude Code with shadowrepo loaded
  Then:    /shadowrepo-build      # scan the current repo

EOF

_sr_bail 0
