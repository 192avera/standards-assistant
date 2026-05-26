#!/usr/bin/env bash
# install.sh — Install or update the company standards assistant in a project.
#
# Usage:
#   ./install.sh                            — installs into the current directory
#   ./install.sh <path>                     — installs into the specified directory
#   ./install.sh <path> --branch <branch>   — installs from a specific branch
#   ./install.sh --branch <branch>          — current directory, specific branch
#
# What it does:
#   - Clones the latest master of the standards repo (shallow, fast)
#   - Copies CLAUDE.md and .claude/ workflow files into the target project
#   - Records the installed commit hash in .claude/.standards_version
#   - Never overwrites .claude/context/project_context.md
#   - Copies .claudeignore.example; creates .claudeignore from it only if one does not exist
#
# Run this script again at any time to update to the latest standards.

set -euo pipefail

STANDARDS_REPO="https://github.com/192avera/standards-assistant.git"

# Parse arguments — TARGET defaults to current directory, BRANCH defaults to master
BRANCH="master"
TARGET=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --branch|-b) BRANCH="$2"; shift 2 ;;
    *) TARGET="$1"; shift ;;
  esac
done
TARGET=$(cd "${TARGET:-.}" && pwd)

echo "Installing standards assistant into: $TARGET"

# Clone latest master to a temp directory
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

echo "Fetching latest standards..."
git clone --depth 1 --branch "$BRANCH" --quiet "$STANDARDS_REPO" "$TMP/standards"

COMMIT=$(git -C "$TMP/standards" rev-parse HEAD)
SHORT=$(echo "$COMMIT" | cut -c1-8)

# Ensure .claude subdirectories exist in target
mkdir -p "$TARGET/.claude/agents"
mkdir -p "$TARGET/.claude/context"
mkdir -p "$TARGET/.claude/commands"

# Copy workflow files
cp "$TMP/standards/CLAUDE.md"                                        "$TARGET/CLAUDE.md"
cp "$TMP/standards/.claude/settings.json"                            "$TARGET/.claude/settings.json"
cp "$TMP/standards/.claude/agents/coordinator.md"                    "$TARGET/.claude/agents/coordinator.md"
cp "$TMP/standards/.claude/agents/implementer.md"                    "$TARGET/.claude/agents/implementer.md"
cp "$TMP/standards/.claude/agents/reviewer.md"                       "$TARGET/.claude/agents/reviewer.md"
cp "$TMP/standards/.claude/context/standards.md"                     "$TARGET/.claude/context/standards.md"
cp "$TMP/standards/.claude/context/creating_project_context.md"      "$TARGET/.claude/context/creating_project_context.md"
cp "$TMP/standards/.claude/agents/documentator.md"                   "$TARGET/.claude/agents/documentator.md"
cp "$TMP/standards/.claude/check-updates.sh"                           "$TARGET/.claude/check-updates.sh"
cp "$TMP/standards/.claude/commands/pre-pr-check.md"                 "$TARGET/.claude/commands/pre-pr-check.md"
cp "$TMP/standards/.claude/commands/commit.md"                        "$TARGET/.claude/commands/commit.md"
cp "$TMP/standards/.claude/commands/pr.md"                            "$TARGET/.claude/commands/pr.md"
chmod +x "$TARGET/.claude/check-updates.sh"

# Copy .claudeignore.example always; create .claudeignore only if absent
cp "$TMP/standards/.claudeignore.example"                             "$TARGET/.claudeignore.example"
if [[ ! -f "$TARGET/.claudeignore" ]]; then
  cp "$TMP/standards/.claudeignore.example"                           "$TARGET/.claudeignore"
fi

# Record installed version and branch — never overwrite project_context.md
echo "$COMMIT" > "$TARGET/.claude/.standards_version"
echo "$BRANCH" > "$TARGET/.claude/.standards_branch"

echo ""
echo "Standards assistant installed at version $SHORT."

if [[ -f "$TARGET/.claude/context/project_context.md" ]]; then
  echo "Existing project_context.md was preserved."
else
  echo "No project_context.md found — the assistant will run the setup interview on first session start."
fi

if [[ -f "$TARGET/.claudeignore" ]]; then
  echo "Existing .claudeignore was preserved. See .claudeignore.example for any new additions."
fi

echo ""
echo "Done. Open Claude Code in $TARGET to get started."
