#!/usr/bin/env bash
# Builds a scratch repository for one eval scenario, with this checkout's
# skills and router installed into it, runs the scenario's own `setup`
# when it has one, and prints the scenario's prompt.
#
#   evals/setup.sh <scenario> <new empty dir> [claude|opencode]
set -euo pipefail

usage="usage: evals/setup.sh <scenario> <new empty dir> [claude|opencode]"
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
scenario="${1:?$usage}"
dir="${2:?$usage}"
agent="${3:-claude}"

src="$here/$scenario"
[ -f "$src/scenario.md" ] && [ -d "$src/repo" ] || { echo "no scenario: $scenario" >&2; exit 1; }
[ ! -e "$dir" ] || { echo "$dir already exists — pick a new directory" >&2; exit 1; }

mkdir -p "$dir"
dir="$(cd "$dir" && pwd)"
cp -R "$src/repo/." "$dir/"

git -C "$dir" init -q -b main
"$here/../install.sh" --agents "$agent" --scope project --dir "$dir" >/dev/null
git -C "$dir" add -A
git -C "$dir" -c user.name=eval -c user.email=eval@example.invalid commit -q -m "scenario: $scenario"

if [ -x "$src/setup" ]; then
  "$src/setup" "$dir" || { echo "$scenario/setup failed" >&2; exit 1; }
fi

echo "Scratch repo: $dir"
echo "Start a fresh $agent session there and paste:"
echo
awk '/^## Prompt/{p=1; next} /^## /{p=0} p' "$src/scenario.md" | sed '/^$/d'
