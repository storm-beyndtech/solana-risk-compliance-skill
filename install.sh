#!/usr/bin/env bash
# Installer for solana-risk-compliance-skill (Claude Code skill addon)
set -euo pipefail

SKILL_NAME="solana-risk-compliance"
SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEST="${HOME}/.claude/skills/${SKILL_NAME}"
ASSUME_YES="false"

for arg in "$@"; do
  case "$arg" in
    -y|--yes) ASSUME_YES="true" ;;
    -h|--help)
      echo "Usage: ./install.sh [-y]"
      echo "  -y, --yes   Non-interactive install to ~/.claude/skills/"
      exit 0 ;;
  esac
done

echo "Installing ${SKILL_NAME} -> ${DEST}"
if [ -d "$DEST" ] && [ "$ASSUME_YES" != "true" ]; then
  read -r -p "Destination exists. Overwrite? [y/N] " ans
  case "$ans" in [yY]*) ;; *) echo "Aborted."; exit 1 ;; esac
fi

rm -rf "$DEST"
mkdir -p "$DEST/skill"

# SKILL.md must sit at the skill-folder ROOT for Claude Code to discover it.
cp "${SRC_DIR}/skill/SKILL.md" "$DEST/SKILL.md"
# The sub-skills stay under skill/ (SKILL.md references them as skill/<file>.md).
find "${SRC_DIR}/skill" -maxdepth 1 -type f ! -name 'SKILL.md' -exec cp {} "$DEST/skill/" \;
# Agents, commands, rules sit alongside (referenced as agents/… rules/… etc.).
cp -R "${SRC_DIR}/agents" "${SRC_DIR}/commands" "${SRC_DIR}/rules" "$DEST/"
cp "${SRC_DIR}/README.md" "${SRC_DIR}/LICENSE" "${SRC_DIR}/EXAMPLES.md" "$DEST/" 2>/dev/null || true

echo "Done. The skill is installed at: ${DEST}"
echo "Entry point: ${DEST}/SKILL.md   (invocable as /${SKILL_NAME})"
echo "Restart Claude Code (or /reload) so it picks up the new skill."
echo "Optional: set RUGBURN_API_URL / RUGBURN_API_KEY to enable engine integration."
