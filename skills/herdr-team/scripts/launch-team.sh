#!/usr/bin/env bash
# Start every agent in <team-dir>/team.tsv in its own tab of one Herdr workspace,
# then hand each agent its role brief. Reruns brief existing idle agents again.
# Usage: launch-team.sh [team-dir]   (default .herdr-team; run from a Herdr pane)
#
# team.tsv: one agent per line, TAB-separated, lead first:
#   name  kind  workdir(relative to repo root)  [agent arg]...
# Each agent arg is its own TAB field, so an arg may contain spaces.
set -euo pipefail

die() { echo "launch-team: $*" >&2; exit 1; }
[ "${HERDR_ENV:-}" = 1 ] || die "run this from a Herdr pane (HERDR_ENV=1)"
command -v jq >/dev/null || die "jq is required"
dir=$(cd "${1:-.herdr-team}" && pwd) || die "team directory not found"
[ -f "$dir/team.tsv" ] || die "$dir/team.tsv not found"
root=$(git -C "$dir" rev-parse --show-toplevel)
[ "$dir" = "$root/.herdr-team" ] || die "team directory must be <repo>/.herdr-team"
label="$(basename "$root") team"
common=$(git -C "$root" rev-parse --path-format=absolute --git-common-dir)

# Validate every worktree before any Herdr side effects.
count=0
while IFS=$'\t' read -r -a f || [ "${#f[@]}" -gt 0 ]; do
	[[ ${#f[@]} -eq 0 || ${f[0]} == \#* ]] && continue
	[ "${#f[@]}" -ge 3 ] || die "team.tsv: expected name, kind, and workdir"
	name=${f[0]}
	[[ $name =~ ^[a-z][a-z0-9_-]{0,31}$ ]] || die "invalid agent name: $name"
	cwd=$(cd "$root/${f[2]}" && pwd) || die "$name: workdir ${f[2]} does not exist"
	[ "$(git -C "$cwd" rev-parse --show-toplevel)" = "$cwd" ] || die "$name: workdir must be a checkout root"
	[ "$(git -C "$cwd" rev-parse --path-format=absolute --git-common-dir)" = "$common" ] || die "$name: workdir belongs to another repo"
	git -C "$cwd" symbolic-ref -q HEAD >/dev/null || die "$name: workdir has a detached HEAD"
	for file in team.tsv PROTOCOL.md SDLC.md "roles/$name.md"; do
		[ -s "$dir/$file" ] || die "$file missing or empty; amend and accept the team configuration first"
		if grep -Fq '{{' "$dir/$file"; then die "$file has unresolved placeholders"; fi
		cmp -s "$dir/$file" "$cwd/.herdr-team/$file" || die "$name: stale $file; incorporate the accepted configuration on its branch"
	done
	count=$((count + 1))
done <"$dir/team.tsv"
[ "$count" -gt 0 ] || die "team.tsv has no agents"

state() { herdr agent get "$1" | jq -r '.result.agent.agent_status'; }

# Herdr shows blocked agents in its sidebar; ping the human and wait for them.
wait_for_human() {
	herdr notification show "herdr-team: $1 needs you" --body "$2" --sound request >/dev/null || true
	echo "$1: waiting for you — $2"
	herdr agent wait "$1" --until idle --until "done" --timeout 900000 >/dev/null
}

ws=$(herdr workspace list | jq -r --arg l "$label" '.result.workspaces[] | select(.label == $l) | .workspace_id' | head -n1)
lead=""

while IFS=$'\t' read -r -a f || [ "${#f[@]}" -gt 0 ]; do
	[[ ${#f[@]} -eq 0 || ${f[0]} == \#* ]] && continue
	name=${f[0]} kind=${f[1]} args=("${f[@]:3}")
	lead=${lead:-$name}
	cwd=$(cd "$root/${f[2]}" && pwd)
	if herdr agent get "$name" >/dev/null 2>&1; then
		case $(state "$name") in
		idle | done) echo "$name: already running; reading current instructions again" ;;
		*) die "$name: finish or pause its current task before relaunch" ;;
		esac
	else
		if [ -z "$ws" ]; then
			out=$(herdr workspace create --cwd "$cwd" --label "$label" --no-focus)
			ws=$(jq -r '.result.workspace.workspace_id' <<<"$out")
			herdr tab rename "$(jq -r '.result.tab.tab_id' <<<"$out")" "$name" >/dev/null
			pane=$(jq -r '.result.root_pane.pane_id' <<<"$out")
		else
			pane=$(herdr tab create --workspace "$ws" --cwd "$cwd" --label "$name" --no-focus | jq -r '.result.root_pane.pane_id')
		fi

		if ! err=$(herdr agent start "$name" --kind "$kind" --pane "$pane" --timeout 120000 -- "${args[@]}" 2>&1 >/dev/null); then
			grep -q agent_not_ready <<<"$err" || die "$name: $err"
			wait_for_human "$name" "answer its startup dialog in tab '$name'"
		fi
	fi

	herdr agent prompt "$name" "You are $name on this team. Read .herdr-team/PROTOCOL.md, .herdr-team/SDLC.md, and .herdr-team/roles/$name.md now and follow them for the rest of this session. Read the policy's task state before resuming work. The lead must reconcile state and complete preflight before implementation. Reply with one line: ready." \
		--wait --timeout 300000 >/dev/null || die "$name: role brief not acknowledged; inspect with: herdr agent read $name"
	[ "$(state "$name")" = blocked ] && wait_for_human "$name" "answer its approval dialog in tab '$name'"
	echo "$name: ready ($kind in $cwd)"
done <"$dir/team.tsv"

echo "team ready: workspace $ws, talk to $lead (herdr agent focus $lead)"
echo "SDLC readiness: the lead must verify preflight and task state before implementation."
