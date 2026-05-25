#!/usr/bin/env bash
# check-updates.sh — Check whether the installed standards are current, or update them. (v3)
#
# This script lives in .claude/ after install. Run it from your project root:
#   bash .claude/check-updates.sh           — check only
#   bash .claude/check-updates.sh --update  — check and apply if behind
#
# The standards assistant also runs this automatically on session start (check only).

set -euo pipefail

STANDARDS_REPO="https://github.com/192avera/standards-assistant.git"
VERSION_FILE=".claude/.standards_version"
UPDATE=false

if [[ "${1:-}" == "--update" ]]; then
  UPDATE=true
fi

if [[ ! -f "$VERSION_FILE" ]]; then
  echo "No .standards_version found. Run install.sh to install the standards assistant."
  exit 1
fi

LOCAL=$(cat "$VERSION_FILE")
LOCAL_SHORT=$(echo "$LOCAL" | cut -c1-8)

echo "Checking for standards updates..."

REMOTE=$(git ls-remote "$STANDARDS_REPO" HEAD 2>/dev/null | cut -f1)

if [[ -z "$REMOTE" ]]; then
  echo "Could not reach the standards repository. Check your network or the repo URL."
  exit 1
fi

REMOTE_SHORT=$(echo "$REMOTE" | cut -c1-8)

if [[ "$LOCAL" == "$REMOTE" ]]; then
  echo "Standards are up to date ($LOCAL_SHORT)."
  exit 0
fi

echo ""
echo "Standards update available."
echo "  Installed : $LOCAL_SHORT"
echo "  Latest    : $REMOTE_SHORT"
echo ""

if [[ "$UPDATE" == false ]]; then
  echo "Run the following to update:"
  echo "  bash .claude/check-updates.sh --update"
  echo ""
  exit 2  # exit 2 = update available (lets CLAUDE.md bootstrap detect it cleanly)
fi

# --update path: pull latest and copy files into this project
echo "Applying update..."

TARGET=$(pwd)
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

git clone --depth 1 --quiet "$STANDARDS_REPO" "$TMP/standards"
COMMIT=$(git -C "$TMP/standards" rev-parse HEAD)
SHORT=$(echo "$COMMIT" | cut -c1-8)

mkdir -p "$TARGET/.claude/agents"
mkdir -p "$TARGET/.claude/context"
mkdir -p "$TARGET/.claude/commands"

cp "$TMP/standards/CLAUDE.md"                                        "$TARGET/CLAUDE.md"
cp "$TMP/standards/.claude/settings.json"                            "$TARGET/.claude/settings.json"
cp "$TMP/standards/.claude/agents/coordinator.md"                    "$TARGET/.claude/agents/coordinator.md"
cp "$TMP/standards/.claude/agents/implementer.md"                    "$TARGET/.claude/agents/implementer.md"
cp "$TMP/standards/.claude/agents/reviewer.md"                       "$TARGET/.claude/agents/reviewer.md"
cp "$TMP/standards/.claude/agents/documentator.md"                   "$TARGET/.claude/agents/documentator.md"
cp "$TMP/standards/.claude/context/standards.md"                     "$TARGET/.claude/context/standards.md"
cp "$TMP/standards/.claude/context/creating_project_context.md"      "$TARGET/.claude/context/creating_project_context.md"
cp "$TMP/standards/.claude/check-updates.sh"                           "$TARGET/.claude/check-updates.sh"
cp "$TMP/standards/.claude/commands/pre-pr-check.md"                 "$TARGET/.claude/commands/pre-pr-check.md"
chmod +x "$TARGET/.claude/check-updates.sh"

echo "$COMMIT" > "$TARGET/.claude/.standards_version"

echo "Standards updated to $SHORT."
if [[ -f "$TARGET/.claude/context/project_context.md" ]]; then
  echo "project_context.md was preserved."
fi
