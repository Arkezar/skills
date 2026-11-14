#!/usr/bin/env bash
# Tests for skills/herdr-team/scripts/team-send.sh with stub herdr and curl.
# Usage: tests/team-send.test.sh
set -uo pipefail
script=$(cd "$(dirname "$0")/.." && pwd)/skills/herdr-team/scripts/team-send.sh
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
fails=0

# Stubs: herdr records "<to>: <text>"; curl saves the request and prints $JEV_REPLY.
mkdir "$tmp/bin"
cat >"$tmp/bin/herdr" <<'EOF'
#!/usr/bin/env bash
[ "$3" = "${HERDR_FAIL:-}" ] && { echo "agent_blocked" >&2; exit 1; }
printf '%s: %s\n' "$3" "$4" >>"$CALLS"
EOF
cat >"$tmp/bin/curl" <<'EOF'
#!/usr/bin/env bash
cat >"$REQUEST"
[ -n "${JEV_REPLY:-}" ] || exit 22
printf '%s' "$JEV_REPLY"
EOF
chmod +x "$tmp/bin/herdr" "$tmp/bin/curl"
export PATH="$tmp/bin:$PATH" CALLS="$tmp/calls" REQUEST="$tmp/request"

repo=$tmp/repo
git init -q "$repo" && cd "$repo" || exit 1
mkdir -p .herdr-team specs
printf 'app-lead\tpi\t.\napp-dev\tpi\t../app-dev\napp-auditor\tpi\t.\n' >.herdr-team/team.tsv
echo "AC1 Given a user, when they log in, then they see the dashboard" >specs/login.md
log=$(git rev-parse --path-format=absolute --git-common-dir)/herdr-team.log
task='TASK t1 | for: login AC1 | build login | inputs: - | done when: AC1 passes | route: app-dev → app-lead'

check() { # check <name> <expected calls>
	local got
	got=$(cat "$CALLS" 2>/dev/null)
	if [ "$got" = "$2" ]; then echo "ok   $1"; else
		echo "FAIL $1"; printf '  expected: %s\n  got:      %s\n' "$2" "$got"; fails=$((fails + 1))
	fi
	rm -f "$CALLS"
}

"$script" app-auditor 'GOAL login | app-lead | specs/login.md | -'
check "GOAL to the auditor is sent once, not copied" 'app-auditor: GOAL login | app-lead | specs/login.md | -'
grep -q $'\tGOAL login ' "$log" && echo "ok   GOAL is logged" || { echo "FAIL GOAL is logged"; fails=$((fails + 1)); }

"$script" app-dev 'QUESTION t1 | app-lead | which db?'
check "other types are not copied" 'app-dev: QUESTION t1 | app-lead | which db?'

"$script" app-dev "$task"
check "without Jev every TASK is copied" "app-dev: $task
app-auditor: CC $task"

echo jev-1.13 >.herdr-team/jev
export OPENCODE_API_KEY=test-key

JEV_REPLY='{"answers":{"course":{"type":"choice","choice":"on_course","confidence":0.95}}}' "$script" app-dev "$task"
check "clear on-course TASK is not copied" "app-dev: $task"
jq -e '.model == "jev-1.13" and (.state.spec | test("AC1 Given")) and (.state.goal | test("GOAL login"))' "$REQUEST" >/dev/null &&
	echo "ok   Jev request has the model, goal, and spec" || { echo "FAIL Jev request has the model, goal, and spec"; fails=$((fails + 1)); }

JEV_REPLY='{"answers":{"course":{"type":"choice","choice":"drift","confidence":0.9}}}' "$script" app-dev "$task"
check "drift TASK is copied with the verdict" "app-dev: $task
app-auditor: CC $task | jev: drift 0.9"

JEV_REPLY='{"answers":{"course":{"type":"choice","choice":"on_course","confidence":0.5}}}' "$script" app-dev "$task"
check "unsure on-course TASK is copied" "app-dev: $task
app-auditor: CC $task | jev: on_course 0.5"

JEV_REPLY='' "$script" app-dev "$task"
check "Jev error: TASK is copied without a verdict" "app-dev: $task
app-auditor: CC $task"

other='TASK t2 | for: billing AC1 | refactor billing | inputs: - | done when: - | route: app-dev → app-lead'
JEV_REPLY='{"answers":{"course":{"type":"choice","choice":"on_course","confidence":0.99}}}' "$script" app-dev "$other"
check "TASK for an unknown goal is copied" "app-dev: $other
app-auditor: CC $other"

"$script" app-auditor 'GOAL leak | app-lead | ../outside.md | -'
rm -f "$CALLS"
echo secret >"$tmp/outside.md"
JEV_REPLY='{"answers":{"course":{"type":"choice","choice":"drift","confidence":0.9}}}' "$script" app-dev 'TASK t3 | for: leak AC1 | x | inputs: - | done when: - | route: app-dev → app-lead' >/dev/null
jq -e '.state.spec == ""' "$REQUEST" >/dev/null &&
	echo "ok   spec path outside the repo is not sent" || { echo "FAIL spec path outside the repo is not sent"; fails=$((fails + 1)); }
rm -f "$CALLS"

lines=$(wc -l <"$log")
HERDR_FAIL=app-dev "$script" app-dev "$task" 2>/dev/null && { echo "FAIL failed send exits non-zero"; fails=$((fails + 1)); }
check "failed send: nothing copied" ""
[ "$(wc -l <"$log")" -eq "$lines" ] && echo "ok   failed send: nothing logged" || { echo "FAIL failed send: nothing logged"; fails=$((fails + 1)); }

[ "$fails" -eq 0 ] && echo "all passed" || { echo "$fails failed"; exit 1; }
