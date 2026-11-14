#!/usr/bin/env bash
# Run launch-team.sh against temporary worktrees and a stub Herdr.
# Usage: bash tests/launch-team.test.sh
set -euo pipefail
script=$(cd "$(dirname "$0")/.." && pwd)/skills/herdr-team/scripts/launch-team.sh
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/bin" "$tmp/running"
export PATH="$tmp/bin:$PATH" HERDR_ENV=1 CALLS="$tmp/calls" RUNNING="$tmp/running"
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null

cat >"$tmp/bin/herdr" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
jq -cn --args '$ARGS.positional' -- "$@" >>"$CALLS"
case "$1 $2" in
'workspace list') echo '{"result":{"workspaces":[]}}' ;;
'workspace create') echo '{"result":{"workspace":{"workspace_id":"w1"},"tab":{"tab_id":"t1"},"root_pane":{"pane_id":"p1"}}}' ;;
'agent get')
	[ -f "$RUNNING/$3" ] || exit 1
	jq -n --arg state "${AGENT_STATE:-idle}" '{result:{agent:{agent_status:$state}}}' ;;
'agent start') touch "$RUNNING/$3" ;;
'agent prompt') [ "${PROMPT_FAIL:-}" != "$3" ] ;;
'agent wait') : ;;
'notification show') : ;;
'tab create') echo '{"result":{"root_pane":{"pane_id":"p2"}}}' ;;
'tab rename') : ;;
*) echo "unexpected Herdr call: $*" >&2; exit 1 ;;
esac
EOF
chmod +x "$tmp/bin/herdr"

repo="$tmp/repo"
git init -q -b main "$repo"
git -C "$repo" config user.name Test
git -C "$repo" config user.email test@example.invalid
mkdir -p "$repo/.herdr-team/roles"
printf 'app-lead\tpi\t.\napp-dev\tpi\t../repo-dev\t--allowedTools\tBash(herdr agent prompt *)\n' >"$repo/.herdr-team/team.tsv"
echo '# Accepted protocol' >"$repo/.herdr-team/PROTOCOL.md"
echo '# Accepted policy' >"$repo/.herdr-team/SDLC.md"
echo '# Lead role' >"$repo/.herdr-team/roles/app-lead.md"
echo '# Dev role' >"$repo/.herdr-team/roles/app-dev.md"
git -C "$repo" add .
git -C "$repo" commit -qm 'test: configure team'
git -C "$repo" worktree add -qb team/dev "$tmp/repo-dev"
team="$repo/.herdr-team"

fail() { echo "FAIL $*" >&2; exit 1; }
check() { local name=$1; shift; "$@" || fail "$name"; echo "ok   $name" >&2; }
no_calls() { [ ! -s "$CALLS" ]; }
expect_failure() {
	local expected=$1
	: >"$CALLS"
	if output=$(bash "$script" "$team" 2>&1); then fail "expected failure: $expected"; fi
	grep -Fq "$expected" <<<"$output" || fail "missing error '$expected': $output"
}

mv "$team/SDLC.md" "$team/SDLC.saved"
expect_failure 'SDLC.md missing or empty'
check 'missing policy fails before Herdr calls' no_calls
mv "$team/SDLC.saved" "$team/SDLC.md"

echo '{{UNSET}}' >>"$team/roles/app-dev.md"
expect_failure 'unresolved placeholders'
check 'unresolved role fails before Herdr calls' no_calls
git -C "$repo" show HEAD:.herdr-team/roles/app-dev.md >"$team/roles/app-dev.md"

echo '# Old policy' >"$tmp/repo-dev/.herdr-team/SDLC.md"
expect_failure 'app-dev: stale SDLC.md'
check 'stale writer policy fails before any agent starts' no_calls
cp "$team/SDLC.md" "$tmp/repo-dev/.herdr-team/SDLC.md"

git -C "$tmp/repo-dev" checkout -q --detach
expect_failure 'detached HEAD'
check 'detached writer fails before Herdr calls' no_calls
git -C "$tmp/repo-dev" checkout -q team/dev

printf 'broken\n' >"$team/team.tsv"
expect_failure 'expected name, kind, and workdir'
check 'malformed roster fails before Herdr calls' no_calls
: >"$team/team.tsv"
expect_failure 'team.tsv has no agents'
check 'empty roster fails before Herdr calls' no_calls

git init -q -b main "$tmp/foreign"
printf 'app-lead\tpi\t.\napp-dev\tpi\t../foreign\n' >"$team/team.tsv"
expect_failure 'workdir belongs to another repo'
check 'unrelated checkout fails before Herdr calls' no_calls

git -C "$repo" show HEAD:.herdr-team/team.tsv >"$team/team.tsv"

# The final line does not need a newline.
printf '%s' "$(<"$team/team.tsv")" >"$team/team.tsv"
cp "$team/team.tsv" "$tmp/repo-dev/.herdr-team/team.tsv"
: >"$CALLS"
output=$(bash "$script" "$team")
check 'fresh launch reaches team ready' grep -Fq 'team ready:' <<<"$output"
check 'startup does not claim SDLC readiness' grep -Fq 'must verify preflight' <<<"$output"
check 'starts both agents, including final unterminated row' jq -es 'map(select(.[0:2] == ["agent","start"])) | length == 2' "$CALLS" >/dev/null
check 'launch args preserve spaces' jq -es 'any(.[]; .[0:3] == ["agent","start","app-dev"] and .[-1] == "Bash(herdr agent prompt *)")' "$CALLS" >/dev/null
check 'both agents read policy and state' jq -es 'map(select(.[0:2] == ["agent","prompt"])) | length == 2 and all(.[]; .[3] | contains(".herdr-team/SDLC.md") and contains("task state"))' "$CALLS" >/dev/null

: >"$CALLS"
bash "$script" "$team" >/dev/null
check 'relaunch never starts duplicate agents' jq -es 'all(.[]; .[0:2] != ["agent","start"])' "$CALLS" >/dev/null
check 'relaunch sends current instructions to both agents' jq -es 'map(select(.[0:2] == ["agent","prompt"])) | length == 2' "$CALLS" >/dev/null

export AGENT_STATE=busy
expect_failure 'finish or pause its current task'
check 'busy agent receives no replacement instructions' jq -es 'all(.[]; .[0:2] != ["agent","prompt"])' "$CALLS" >/dev/null
unset AGENT_STATE

export PROMPT_FAIL=app-dev
expect_failure 'role brief not acknowledged'
check 'failed briefing never reports ready' bash -c '! grep -Fq "team ready:" <<<"$1"' -- "$output"
unset PROMPT_FAIL

echo 'all passed'
