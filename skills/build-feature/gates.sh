#!/bin/sh
# Local facts for the gates of serenity.md. Usage, from a checkout: sh gates.sh <branch>
set -u

branch=${1:?usage: gates.sh <branch>}
root=$(git rev-parse --show-toplevel) || exit 1
config="$root/docs/agents/factory.yml"
[ -f "$config" ] || { echo "no docs/agents/factory.yml in $root"; exit 1; }

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

protected_paths() {
  awk -v q="'" '
    /^protected_paths:/ { inside = 1; next }
    inside && /^[^[:space:]#]/ { exit }
    inside && /^[[:space:]]*-[[:space:]]/ {
      value = $0
      sub(/^[[:space:]]*-[[:space:]]+/, "", value)
      sub(/[[:space:]]+#.*$/, "", value)
      first = substr(value, 1, 1)
      if (first == "\"" || first == q) { value = substr(value, 2); sub(/["\047][[:space:]]*$/, "", value) }
      print value
    }' "$config"
}

main=$(setting repository main_branch)
main=${main:-main}
location=$(setting specs location)
specs=$(setting specs folder)
[ "$specs" = none ] && specs=
status_line=$(sed -n "s/^    status_line:[[:space:]]*['\"]\{0,1\}\([^'\"]*\).*/\1/p" "$config" | head -n 1)
base="origin/$main"

git fetch -q origin "$main" || exit 1
git rev-parse -q --verify "$branch^{commit}" >/dev/null || { echo "no branch $branch"; exit 1; }

echo "head: $(git rev-parse "$branch")"
echo "behind $base: $(git rev-list --count "$branch..$base")"

git diff --numstat "$base...$branch" |
  awk '{ if ($1 != "-") lines += $1 + $2; files++ }
       END { printf "changed: %d files, %d lines (lockfiles and generated files included)\n", files, lines }'

echo "specs touched:"
if [ "$location" = issue ]; then
  echo "  none expected (specs.location: issue): read the closed issue's body for unticked boxes"
elif [ -n "$specs" ]; then
  git diff --name-only "$base...$branch" -- "$specs" | while read -r spec; do
    status=$(git show "$branch:$spec" 2>/dev/null | grep -m 1 -F "${status_line:-Status:}")
    open=$(git show "$branch:$spec" 2>/dev/null | grep -c '^[[:space:]]*[-*][[:space:]]\[[[:space:]]\]')
    echo "  $spec | ${status:-no status line} | unticked boxes: $open"
  done
fi

echo "protected paths changed:"
changed=$(git diff --name-only "$base...$branch")
protected_paths | while read -r entry; do
  case $entry in
    *' '*) echo "  check by hand: $entry" ;;
    */) printf '%s\n' "$changed" | awk -v p="$entry" 'index($0, p) == 1 { print "  " $0 }' ;;
    *) printf '%s\n' "$changed" | awk -v p="$entry" '$0 == p { print "  " $0 }' ;;
  esac
done

echo "added suppressions:"
git diff "$base...$branch" |
  grep -n -E '^\+.*(eslint-disable|oxlint-disable|biome-ignore|@ts-ignore|@ts-expect-error|@ts-nocheck|type: ?ignore|noqa|pylint: ?disable|rubocop:disable|nolint|@SuppressWarnings|#\[allow\(|\.skip\(|\.only\(|xit\(|xdescribe\(|@Disabled|@Ignore|#\[ignore\]|pytest\.mark\.skip)' |
  sed 's/^/  /'

echo "existing files modified, deleted or renamed (look for migrations):"
git diff --name-status "$base...$branch" | grep -v '^A' | sed 's/^/  /'
