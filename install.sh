#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILLS_DIR="$SCRIPT_DIR/skills"

if [ ! -d "$SKILLS_DIR" ]; then
  echo "Error: skills/ directory not found at $SKILLS_DIR"
  exit 1
fi

TARGETS=(
  "$HOME/.claude/skills"
  "$HOME/.gemini/skills"
  "$HOME/.agents/skills"
)

for target in "${TARGETS[@]}"; do
  mkdir -p "$target"
  for skill in "$SKILLS_DIR"/*/; do
    name="$(basename "$skill")"
    link="$target/$name"
    if [ -L "$link" ]; then
      rm "$link"
    elif [ -e "$link" ]; then
      echo "Skipping $link (exists and is not a symlink)"
      continue
    fi
    ln -s "$skill" "$link"
    echo "Linked $name -> $target/"
  done
done

echo ""
echo "Installed $(ls -1d "$SKILLS_DIR"/*/ | wc -l | tr -d ' ') skills to:"
for target in "${TARGETS[@]}"; do
  echo "  $target"
done
