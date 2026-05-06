#!/usr/bin/env bash
# install.sh — Install or update the company standards assistant in a target project.
#
# Usage:
#   ./install.sh <target-project-path>
#
# What it does:
#   - Clones the latest master of the standards repo (shallow, fast)
#   - Copies CLAUDE.md and .claude/ workflow files into the target project
#   - Records the installed commit hash in .claude/.standards_version
#   - Never overwrites .claude/context/project_context.md
#
# Run this script again at any time to update to the latest standards.

set -euo pipefail

STANDARDS_REPO="https://github.com/192avera/standards-assistant.git"

TARGET="${1:-}"

if [[ -z "$TARGET" ]]; then
  echo "Usage: ./install.sh <target-project-path>"
  exit 1
fi

if [[ ! -d "$TARGET" ]]; then
  echo "Error: target directory '$TARGET' does not exist."
  exit 1
fi

echo "Installing standards assistant into: $TARGET"

# Clone latest master to a temp directory
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

echo "Fetching latest standards..."
git clone --depth 1 --quiet "$STANDARDS_REPO" "$TMP/standards"

COMMIT=$(git -C "$TMP/standards" rev-parse HEAD)
SHORT=$(echo "$COMMIT" | cut -c1-8)

# Ensure .claude subdirectories exist in target
mkdir -p "$TARGET/.claude/agents"
mkdir -p "$TARGET/.claude/context"

# Copy workflow files
cp "$TMP/standards/CLAUDE.md"                                        "$TARGET/CLAUDE.md"
cp "$TMP/standards/.claude/settings.json"                            "$TARGET/.claude/settings.json"
cp "$TMP/standards/.claude/agents/coordinator.md"                    "$TARGET/.claude/agents/coordinator.md"
cp "$TMP/standards/.claude/agents/implementer.md"                    "$TARGET/.claude/agents/implementer.md"
cp "$TMP/standards/.claude/agents/reviewer.md"                       "$TARGET/.claude/agents/reviewer.md"
cp "$TMP/standards/.claude/context/standards.md"                     "$TARGET/.claude/context/standards.md"
cp "$TMP/standards/.claude/context/creating_project_context.md"      "$TARGET/.claude/context/creating_project_context.md"
cp "$TMP/standards/check-updates.sh"                                  "$TARGET/.claude/check-updates.sh"
chmod +x "$TARGET/.claude/check-updates.sh"

# Record installed version — never overwrite project_context.md
echo "$COMMIT" > "$TARGET/.claude/.standards_version"

echo ""
echo "Standards assistant installed at version $SHORT."

if [[ -f "$TARGET/.claude/context/project_context.md" ]]; then
  echo "Existing project_context.md was preserved."
else
  echo "No project_context.md found — the assistant will run the setup interview on first session start."
fi

echo ""
echo "Done. Open Claude Code in $TARGET to get started."
