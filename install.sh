#!/usr/bin/env bash
# ShadowRepo Skill Suite — Install / Uninstall
#
# Usage:
#   ./install.sh          # Install skills to ~/.claude/skills/
#   ./install.sh remove   # Uninstall

set -e

REPO_ROOT="$(cd "$(dirname "$0")" && pwd)"
SKILLS_SOURCE="$REPO_ROOT/skills"
CLAUDE_SKILLS="$HOME/.claude/skills"

# ─── Skill catalog ─────────────────────────────────────
SKILL_NAMES=()
SKILL_DESCS=()
register_skill() { SKILL_NAMES+=("$1"); SKILL_DESCS+=("$2"); }

register_skill build   "Build feature tree + spec graph"
register_skill check   "Detect code-spec drift"
register_skill update  "Fix drifted specs"
register_skill render  "Generate docs from specs"
register_skill preview "Impact assessment (coming soon)"
register_skill help    "Show capabilities"

# ─── Uninstall ──────────────────────────────────────────
if [ "$1" = "remove" ]; then
  removed=0
  for s in "${SKILL_NAMES[@]}"; do
    target="$CLAUDE_SKILLS/shadowrepo-$s"
    [ -L "$target" ] && rm "$target" && removed=$((removed + 1))
  done
  [ -L "$CLAUDE_SKILLS/shadowrepo" ] && rm "$CLAUDE_SKILLS/shadowrepo"

  if [ "$removed" -gt 0 ]; then
    echo ""
    echo "  ◆ ShadowRepo — Uninstalled"
    echo ""
    echo "  Removed $removed skills from ~/.claude/skills/"
    echo ""
  else
    echo "  Nothing to remove."
  fi
  exit 0
fi

# ─── Detect existing install ────────────────────────────
MODE="install"
if [ -L "$CLAUDE_SKILLS/shadowrepo" ]; then
  EXISTING="$(readlink "$CLAUDE_SKILLS/shadowrepo")"
  if [ "$EXISTING" = "$SKILLS_SOURCE" ]; then
    MODE="already"
  else
    MODE="update"
  fi
fi

# ─── Install ────────────────────────────────────────────
mkdir -p "$CLAUDE_SKILLS"

ln -snf "$SKILLS_SOURCE" "$CLAUDE_SKILLS/shadowrepo"

for s in "${SKILL_NAMES[@]}"; do
  ln -snf "shadowrepo/$s" "$CLAUDE_SKILLS/shadowrepo-$s"
done

# ─── Output ─────────────────────────────────────────────
case "$MODE" in
  already) TITLE="◆ ShadowRepo — Already installed (verified)" ;;
  update)  TITLE="◆ ShadowRepo — Updated" ;;
  *)       TITLE="◆ ShadowRepo — Installed" ;;
esac

if command -v gum >/dev/null 2>&1; then
  # ─── gum TUI ──────────────────────────────────────
  SKILLS_LINES=""
  for i in "${!SKILL_NAMES[@]}"; do
    SKILLS_LINES+="$(printf "  /shadowrepo-%-8s  %s" "${SKILL_NAMES[$i]}" "${SKILL_DESCS[$i]}")"$'\n'
  done

  echo ""
  gum style --border double --padding "1 2" --border-foreground 5 \
    "$TITLE" \
    "Semantic Code Knowledge Graph"
  echo ""
  gum style --border rounded --padding "1 2" --border-foreground 4 \
    "Skills:" \
    "" \
    "$SKILLS_LINES"
  gum style --border rounded --padding "1 2" --border-foreground 2 \
    "Get started:" \
    "" \
    "  1. cd into any repo" \
    "  2. /shadowrepo-build    first-time setup" \
    "  3. /shadowrepo-check    after code changes" \
    "  4. /shadowrepo-update   fix drifted specs" \
    "  5. /shadowrepo-render   generate docs"
  echo ""
else
  # ─── Plain fallback ───────────────────────────────
  echo ""
  echo "  $TITLE"
  echo "  Semantic Code Knowledge Graph"
  echo ""
  echo "  Skills:"
  echo ""
  for i in "${!SKILL_NAMES[@]}"; do
    printf "    /shadowrepo-%-8s  %s\n" "${SKILL_NAMES[$i]}" "${SKILL_DESCS[$i]}"
  done
  echo ""
  echo "  Get started:"
  echo ""
  echo "    1. cd into any repo"
  echo "    2. /shadowrepo-build    first-time setup"
  echo "    3. /shadowrepo-check    after code changes"
  echo "    4. /shadowrepo-update   fix drifted specs"
  echo "    5. /shadowrepo-render   generate docs"
  echo ""
fi
