#!/bin/sh
# Stop gate of factorydeck-skills. Before an agent stops with work that is not on the main
# branch yet, runs checks.command of docs/agents/factory.yml and sends the agent back while it
# fails, at most MAX_BLOCKS times in a row so that a run always ends. Does nothing in a
# repository without that file, or when it sets checks.stop_gate to false.
set -u

MAX_BLOCKS=3
REPORTED_LINES=80

input=$(cat)

field() {
  printf '%s' "$input" | tr '\n' ' ' |
    sed -n "s/.*\"$1\"[[:space:]]*:[[:space:]]*\"\([^\"]*\)\".*/\1/p" | head -n 1
}

dir=$(field cwd)
[ -n "$dir" ] || dir=${CLAUDE_PROJECT_DIR:-$PWD}
cd "$dir" 2>/dev/null || exit 0
root=$(git rev-parse --show-toplevel 2>/dev/null) || exit 0
config="$root/docs/agents/factory.yml"
[ -f "$config" ] || exit 0

# Reads « section: / key: value » from plain block YAML: a top-level section, then a key
# indented by two spaces. Strips one level of quotes and a trailing comment.
setting() {
  awk -v section="$1" -v key="$2" -v q="'" '
    /^[^[:space:]#]/ { current = $0; sub(/:.*/, "", current); next }
    current == section && index($0, "  " key ":") == 1 {
      value = substr($0, length(key) + 4)
      sub(/^[[:space:]]+/, "", value)
      first = substr(value, 1, 1)
      if (first == "\"" || first == q) {
        value = substr(value, 2)
        end = index(value, first)
        if (end > 0) value = substr(value, 1, end - 1)
      } else {
        sub(/[[:space:]]+#.*$/, "", value)
      }
      sub(/[[:space:]]+$/, "", value)
      print value
      exit
    }' "$config"
}

case $(setting checks stop_gate) in
  false | False | FALSE | no | off) exit 0 ;;
esac
check=$(setting checks command)
case $check in
  '' | *'<'*'>'*) exit 0 ;;
esac

main=$(setting repository main_branch)
dirty=$(git status --porcelain 2>/dev/null)
ahead=$(git rev-list --count "origin/${main:-main}..HEAD" 2>/dev/null || echo 0)
if [ -z "$dirty" ] && [ "$ahead" -eq 0 ]; then
  exit 0
fi

key=$(printf '%s %s' "$(field session_id)" "$root" | cksum | cut -d ' ' -f 1)
state="${TMPDIR:-/tmp}/factorydeck-stop-gate-$key"
log="$state.log"

if (cd "$root" && sh -c "$check") >"$log" 2>&1; then
  rm -f "$state" "$log"
  exit 0
fi

blocks=$(cat "$state" 2>/dev/null || echo 0)
if [ "$blocks" -ge "$MAX_BLOCKS" ]; then
  rm -f "$state"
  printf 'factorydeck stop gate: `%s` still fails after %s attempts; letting the agent stop. Log: %s\n' \
    "$check" "$MAX_BLOCKS" "$log" >&2
  exit 0
fi
blocks=$((blocks + 1))
printf '%s\n' "$blocks" >"$state"

{
  printf 'The check command `%s` fails in %s (attempt %s of %s).\n' "$check" "$root" "$blocks" "$MAX_BLOCKS"
  printf 'Fix the cause before stopping; never loosen a check to pass it. Last %s lines of its output (full log: %s):\n\n' \
    "$REPORTED_LINES" "$log"
  tail -n "$REPORTED_LINES" "$log"
} >&2
exit 2
