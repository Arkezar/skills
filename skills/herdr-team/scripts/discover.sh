#!/usr/bin/env bash
# Inventory for a herdr-team proposal: Herdr, installed agent harnesses with
# their model catalogs, and basic repo facts. Read-only; installs nothing.
# Usage: discover.sh [repo-dir]
set -uo pipefail
repo=${1:-.}

section() { printf '\n## %s\n' "$1"; }

# Herdr kind -> executable, where they differ.
bin_for() {
	case $1 in
	cursor) echo cursor-agent ;;
	kiro) echo kiro-cli ;;
	*) echo "$1" ;;
	esac
}

# A mise shim for a tool that is not installed would install it on first run,
# so it does not count as available.
available() {
	local p
	p=$(command -v "$1") || return 1
	case $p in
	*/mise/shims/* | */mise/command-wrappers/*) mise which "$1" >/dev/null 2>&1 ;;
	esac
}

catalog() {
	case $1 in
	pi) timeout 60 pi --list-models 2>/dev/null | awk 'NR > 1 { print $1 "/" $2 "\tthinking=" $5 }' ;;
	codex) timeout 60 codex debug models 2>/dev/null |
		jq -r '.models[] | select(.visibility == "list") |
			"\(.slug)\tefforts=\([.supported_reasoning_levels[].effort] | join(","))\t\(.description)"' ;;
	opencode) timeout 60 opencode models 2>/dev/null ;;
	claude)
		timeout 20 claude --help 2>/dev/null | grep -A3 -- '--model <model>' | grep -o "'[a-z]*'" | tr -d "'" | sed 's/$/\t(alias)/'
		timeout 20 claude --help 2>/dev/null | grep -A1 -- '--effort <level>' | tr -s ' ' | paste -sd ' '
		;;
	*) return 1 ;;
	esac
}

section herdr
if command -v herdr >/dev/null; then
	herdr --version
	echo "inside a herdr pane: $([ "${HERDR_ENV:-}" = 1 ] && echo yes || echo no)"
	herdr status server 2>&1 | sed 's/^/  /'
	echo "integrations:"
	herdr integration status 2>&1 | sed 's/^/  /'
	kinds=$(herdr agent 2>&1 | sed -n 's/^ *kinds: //p' | tr '|' ' ')
else
	echo "herdr: NOT INSTALLED — a team cannot be launched"
	kinds=""
fi

section harnesses
for kind in $kinds; do
	bin=$(bin_for "$kind")
	available "$bin" || continue
	printf '\n### %s (%s)\n' "$kind" "$(command -v "$bin")"
	if ! catalog "$kind"; then
		echo "no known catalog command: read \`$bin --help\`; if it lists no models, propose only the harness default"
	fi
done

section tools
for t in git jq npx curl; do printf '%s: %s\n' "$t" "$(command -v "$t" || echo MISSING)"; done
echo "OPENCODE_API_KEY: $([ -n "${OPENCODE_API_KEY:-}" ] && echo set || echo 'not set') (Jev pre-check)"

section repo
cd "$repo" || exit 1
if root=$(git rev-parse --show-toplevel 2>/dev/null); then
	echo "root: $root"
	echo "branch: $(git branch --show-current)"
	echo "commits: $(git rev-list --count HEAD 2>/dev/null || echo 0)"
	echo "worktrees: $(git worktree list | wc -l)"
	files=$({ git ls-files; git ls-files --others --exclude-standard; } | sort -u)
else
	echo "git: not a repository"
	files=$(find . -type f -not -path './.git/*' | sed 's|^\./||')
fi
# Empty = nothing beyond root-level boilerplate.
substantive=$(printf '%s\n' "$files" | grep -vEi '^(readme|license|licence|\.gitignore|\.gitattributes|\.editorconfig)' | grep -c .)
echo "files: $(printf '%s\n' "$files" | grep -c .)  substantive: $substantive  empty: $([ "$substantive" -eq 0 ] && echo yes || echo no)"
echo "existing team: $([ -f .herdr-team/team.tsv ] && echo "yes (.herdr-team/team.tsv)" || echo no)"
echo "top extensions:"
printf '%s\n' "$files" | grep -oE '\.[A-Za-z0-9]+$' | sort | uniq -c | sort -rn | head -10
