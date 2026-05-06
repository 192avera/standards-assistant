#!/usr/bin/env bash
# check-updates.sh — Check whether the installed standards are current with the remote repo.
#
# This script lives in .claude/ after install. Run it from your project root:
#   bash .claude/check-updates.sh
#
# The standards assistant also runs this automatically on session start.

set -euo pipefail

STANDARDS_REPO="https://github.com/192avera/standards-assistant.git"
VERSION_FILE=".claude/.standards_version"

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
else
  echo ""
  echo "Standards update available."
  echo "  Installed : $LOCAL_SHORT"
  echo "  Latest    : $REMOTE_SHORT"
  echo ""
  echo "To update, run install.sh from the standards repo:"
  echo "  bash /path/to/standards-assistant/install.sh $(pwd)"
  echo ""
  exit 2  # exit 2 = update available (lets CLAUDE.md bootstrap detect it cleanly)
fi
