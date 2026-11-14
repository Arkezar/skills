# Team protocol

This team works on `{{REPO}}`. The main branch is `{{MAIN_BRANCH}}`. The human talks to the lead, `{{LEAD}}`, and refines new ideas with `{{REFINER}}`.

| Agent | Role | Workdir | Branch |
|---|---|---|---|
{{ROSTER_ROWS}}

Read `.herdr-team/SDLC.md` before work. It defines the accepted gates, commands, approvals, state location, and release contract.
On startup or relaunch, the lead reconciles task state and completes the required preflight before implementation.

## Who talks to whom

- `{{LEAD}}` assigns every task. Apart from refining an idea with the human, no agent starts work without a TASK or a HANDOFF.
- Inside a task, agents talk to each other directly. Send handoffs, questions, findings, and rework to the agent that needs them, not through `{{LEAD}}`.
- `{{LEAD}}` gets GOAL, DONE, DECISION, BLOCKED, NOTE, and DRIFT. For task-state transitions, send a NOTE with the new owner, status, candidate SHA, and evidence path. Keep routine progress and other worker messages off the lead's queue.
- If two agents still disagree after two rounds, or a task goes back and forth more than three times, one of them sends DECISION to `{{LEAD}}` with both positions.
- `{{LEAD}}` follows the approval rules in SDLC.md. Ask the human before pushing, releasing, deleting branches or data, or changing a goal's scope.

## Messages

Send one line per message with Herdr. `{{LEAD}}` sends with `.herdr-team/team-send.sh <to> "<message>"` instead, with the same arguments (see Staying on course):

```bash
herdr agent prompt <to> "<message>"
```

Send without `--wait`, then carry on or end your turn. Replies arrive as your next prompt.

Between agents:

- `TASK <id> | for: <goal slug> AC<n>,… | <what to do> | inputs: <paths, branches> | done when: <criteria> | route: <agent> → … → {{LEAD}}`: lead → the first agent on the route. `for:` names the goal and the acceptance criteria the task serves.
- `HANDOFF <id> | <from> | <result: branch@sha> | <for, what to do, and done when from the TASK> | evidence: <report path or CI URL, including prior verdicts> | route: <the rest of the route>`: to the next agent. When the next agent is `{{LEAD}}`, send DONE instead.
- `CHANGES <id> | <from> | <branch@sha> | <findings with file:line, or a report path>`: reviewer, qa, or security → the author. The author fixes the candidate, repeats validation, then returns to independent review as SDLC.md requires.
- `QUESTION <id> | <from> | <question>`: to the agent that owns the answer: the analyst for the spec, the architect for the design, the branch's dev for its code. Pause work on `<id>` until the answer comes. If no agent owns the answer, send DECISION to `{{LEAD}}`.

To `{{LEAD}}`:

- `GOAL <slug> | <from> | <spec path> | <branch@sha>`: the refiner, only after the human approved the spec.
- `DONE <id> | <from> | <summary> | <branch@sha> | evidence: <checks and all required APPROVE verdicts for this SHA>`: the last agent on the route. DONE asks the lead to verify the next gate, including release evidence for delivery tasks. It does not close the task or goal.
- `DECISION <id> | <from> | <what to decide> | options: <a>; <b> | recommend: <one>`: a choice outside your role: scope, priority, a disagreement the agents did not settle, or anything the human must approve. Pause work on `<id>` until the answer comes.
- `BLOCKED <id> | <from> | <what is needed>`.
- `NOTE <id> | <from> | <fact>`: a task-state transition, risk, scope surprise, or agreed interface change. Include the owner, status, SHA, and evidence for transitions. It needs no reply.

Details longer than about 10 lines go into a file in your workdir. Send its absolute path or its repo path with branch@sha so readers in other worktrees can find it. If `herdr agent prompt` fails with `agent_blocked`, run `herdr agent wait <to> --until idle --until done --timeout 600000`, then send once more.

To see where a task is, the lead reads an agent's output with `herdr agent read <name> --source recent-unwrapped --lines 200` and sees everyone's state with `herdr agent list`. It does not ask agents for status.

## Refining an idea

1. The human brings an idea to `{{REFINER}}` in its tab. That is its task until the human approves a spec or drops the idea.
2. `{{REFINER}}` asks the human 2 to 4 questions per round, with its question tool if it has one, and reads the code it needs. It asks other agents with QUESTION, for example the architect about feasibility. Use the idea's slug as `<id>`.
3. Draft the spec with the problem, scope, exclusions, numbered AC as Given/When/Then, and open decisions with owners. Use the repo's spec dir (`specs/` if absent) in the refiner's worktree. If the lead is the refiner, draft in messages and delegate the file to a writer. Agree whether completion means `merged` or `released`.
4. After human approval, the refiner commits the spec on its branch and sends GOAL to the lead. If the lead is the refiner, assign a writer to commit the approved spec on its own branch.
5. The lead integrates the spec through the policy's applicable checks, independent review, and approval rules. Record the goal, completion target, dependencies, and tasks in the state location. Resolve gate-blocking decisions before implementation. Ask the human when priority is unclear. From then on, scope changes need the human's approval.

## Staying on course

`{{AUDITOR}}` checks that the lead's work serves the open goals and nothing else. `{{LEAD}}` sends every message with `.herdr-team/team-send.sh`. The script logs each GOAL, TASK, DECIDED, and CLOSED in `$(git rev-parse --path-format=absolute --git-common-dir)/herdr-team.log` and copies it to `{{AUDITOR}}` as `CC <message>`. `{{LEAD}}`:

- sends each approved GOAL to `{{AUDITOR}}` before its first TASK, including spec review or bootstrap work. Include the refiner's spec path and branch@sha so the auditor can read an unmerged spec. For a goal the human gave directly: `GOAL <slug> | {{LEAD}} | <the goal> | criteria: AC1 <…>; AC2 <…>`.
- answers each DECISION with `DECIDED <id> | {{LEAD}} | <answer>` to the agent that asked, and each DRIFT with DECIDED to `{{AUDITOR}}`.
- sends `CLOSED <slug> | {{LEAD}} | <merged sha, released version and sha, or parked by the human> | evidence: <state record>` after the goal reaches its agreed completion target.

Jev pre-check: when `.herdr-team/jev` holds a model id and `OPENCODE_API_KEY` is set, the script first asks Jev whether a TASK serves its goal. A TASK that Jev finds clearly on course is only logged. Every other TASK reaches `{{AUDITOR}}` with Jev's verdict (`| jev: <choice> <confidence>`). Before it judges a copy, `{{AUDITOR}}` reads the log for the goal's full history.

`{{AUDITOR}}` stays silent while the work is on course. It sends `DRIFT <slug> | {{AUDITOR}} | <what drifts, from which criterion> | recommend: drop, park, or ask the human` to `{{LEAD}}` when:

- a TASK serves no criterion of an open goal, or its work goes beyond the criteria it names;
- work serves other work, not a criterion, more than one level deep (a task to unblock a task to unblock a task);
- tasks go on for a goal whose criteria and agreed completion target already pass;
- a DECIDED adds or drops scope without the human's approval;
- a goal is CLOSED before its completion target or with an unmet criterion, without the human's recorded exception or parking decision.

On DRIFT, `{{LEAD}}` drops or parks the drifting work, or asks the human to approve it as a scope change, then sends DECIDED. The lead does not overrule a DRIFT on its own. If the next copies continue the drift and no DECIDED answered it, `{{AUDITOR}}` alerts the human, who reads the details in its tab:

```bash
herdr notification show "herdr-team: drift on <slug>" --body "<one line>" --sound request
```

`{{AUDITOR}}` never sends messages to workers.

## Flow

For each task, the lead assigns a route through the applicable stages in order.
Use SDLC.md for mandatory gates and evidence. A missing specialist transfers the duty to a named agent, not out of the route.
Keep review independent of every author of the candidate.

1. **ready** (lead, analyst, architect): approved AC, settled dependencies, completed preflight, and design for cross-module work.
2. **build** (dev): test-first on its own branch. Include required docs and release preparation in this or a dependent task.
3. **validate** (qa, or the assigned validation owner): run the policy's required checks on the candidate. Map every AC to evidence.
4. **review** (reviewer, then security when required): inspect `{{MAIN_BRANCH}}...<branch>`. Record verdicts for the exact candidate SHA. Preserve all verdicts in subsequent handoffs.
5. **integrate** (lead): verify evidence and approvals for the candidate. Use the accepted local-merge or PR workflow. Record the integration SHA and required post-integration checks. Complete the integration gate before marking merged or unblocking dependents.
6. **release** (devops, or its named substitute): for delivery goals, release the validated artifact after required docs and human approval. Record smoke checks and recovery results before marking released.

### QA commits

QA changes only its own worktree. It incorporates the dev candidate there and commits new tests on its own branch.
Send the test commit SHAs to the dev with CHANGES. The dev incorporates those commits on its own branch.
The dev returns the combined candidate to QA for validation, then to independent review.
Only this combined branch proceeds to integration. A QA-only branch or an earlier dev SHA is not the final candidate.

Independent tasks run in parallel lanes. Each agent works on one task at a time. A TASK or HANDOFF that arrives while you are busy waits until you finish; take them in the order they came.

## Git

- One writer per worktree. Commit code, tests, and docs only on your own branch.
- The lead owns task-state updates and integration. Only the lead integrates into `{{MAIN_BRANCH}}`, through the accepted workflow.
- Before a new task, incorporate the latest main branch. During a task, coordinate rebases with downstream agents.
- Incorporate required design, docs, and test commits from other writers into the candidate branch before final validation.
- After a candidate changes, follow SDLC.md to renew checks and review before integration.
- Before relaunch, verify assigned branches and synchronize accepted protocol, policy, and role files. Preserve uncommitted work.
