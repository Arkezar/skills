#!/usr/bin/env bash
# The lead's send command: herdr agent prompt, plus a copy for the auditor.
# GOAL, TASK, DECIDED, and CLOSED are logged in <git common dir>/herdr-team.log
# and copied to the auditor (the team.tsv name ending in -auditor) as "CC <message>".
# Jev pre-check: if .herdr-team/jev holds a model id and OPENCODE_API_KEY is set,
# a TASK that Jev finds clearly on course is logged only, not copied.
# Usage: team-send.sh <to> <message>   (copy into .herdr-team/, run in the repo)
set -uo pipefail

die() { echo "team-send: $*" >&2; exit 1; }
[ $# -eq 2 ] || die "usage: team-send.sh <to> <message>"
to=$1 msg=$2
root=$(git rev-parse --show-toplevel) || die "not in a git repo"
team=$root/.herdr-team
log=$(git rev-parse --path-format=absolute --git-common-dir)/herdr-team.log
auditor=$(awk -F'\t' '$1 ~ /-auditor$/ { print $1; exit }' "$team/team.tsv" 2>/dev/null)
jev_url=${JEV_URL:-https://opencode.ai/inference/systemone/v1/systemone}
min_confidence=0.8 # below this, the auditor decides

herdr agent prompt "$to" "$msg" >/dev/null || exit # on failure the lead retries; nothing was copied

type=${msg%% *}
case $type in GOAL | TASK | DECIDED | CLOSED) ;; *) exit 0 ;; esac

# Prints "skip" for a clear on-course TASK, else "<choice> <confidence>". Fails when Jev is off or errors.
jev_check() {
	local model slug goal spec_path spec="" tasks
	model=$(head -n1 "$team/jev" 2>/dev/null) && [ -n "$model" ] && [ -n "${OPENCODE_API_KEY:-}" ] || return 1
	slug=$(sed -n 's/^TASK [^|]*| *for: *\([^ |]*\).*/\1/p' <<<"$msg")
	[ -n "$slug" ] || return 1
	goal=$(grep -F $'\tGOAL '"$slug " "$log" 2>/dev/null | tail -n1 | cut -f2-)
	[ -n "$goal" ] || return 1 # a TASK for an unknown goal goes to the auditor
	spec_path=$(cut -d'|' -f3 <<<"$goal" | sed 's/^ *//; s/ *$//')
	case $spec_path in /* | *..*) spec_path="" ;; esac # the spec goes to Jev: only files inside the repo
	[ -n "$spec_path" ] && [ -f "$root/$spec_path" ] && spec=$(head -c 20000 "$root/$spec_path")
	tasks=$(grep -F $'\tTASK ' "$log" | grep -F "for: $slug " | cut -f2-)
	jq -n --arg model "$model" --arg goal "$goal" --arg spec "$spec" --arg tasks "$tasks" --arg task "$msg" '{
		model: $model,
		state: {goal: $goal, spec: $spec, earlier_tasks: $tasks, new_task: $task},
		questions: {course: {
			type: "choice",
			instructions: "A lead sends tasks to coding agents to reach `goal`. Its acceptance criteria are in `goal` and `spec`. Does `new_task` keep the team on course?",
			criteria: {
				on_course: "The task directly serves the acceptance criteria it names, and its work stays inside the scope of the goal.",
				drift: "The task serves no acceptance criterion, goes beyond the criteria it names, adds scope the goal does not have, repeats work that `earlier_tasks` already did, or unblocks another task that itself only unblocks a task."
			}
		}}
	}' | curl -fsS --max-time 10 -H @<(printf 'Authorization: Bearer %s\n' "$OPENCODE_API_KEY") \
		-H 'Content-Type: application/json' --data-binary @- "$jev_url" |
		jq -er --argjson min "$min_confidence" '.answers.course | select(.choice) |
			if .choice == "on_course" and .confidence >= $min then "skip" else "\(.choice) \(.confidence)" end'
}

verdict=""
[ "$type" = TASK ] && verdict=$(jev_check 2>/dev/null)
printf '%s\t%s\n' "$(date -u +%FT%TZ)" "$msg" >>"$log"

[ -n "$auditor" ] && [ "$to" != "$auditor" ] && [ "$verdict" != skip ] || exit 0
herdr agent prompt "$auditor" "CC $msg${verdict:+ | jev: $verdict}" >/dev/null ||
	echo "team-send: sent to $to, but the copy to $auditor failed" >&2
