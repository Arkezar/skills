# Team protocol

This team works on `{{REPO}}`. The main branch is `{{MAIN_BRANCH}}`. The human talks to the lead, `{{LEAD}}`, and refines new ideas with `{{REFINER}}`.

| Agent | Role | Workdir | Branch |
|---|---|---|---|
{{ROSTER_ROWS}}

## Who talks to whom

- `{{LEAD}}` assigns every task. Apart from refining an idea with the human, no agent starts work without a TASK or a HANDOFF.
- Inside a task, agents talk to each other directly. Send handoffs, questions, findings, and rework to the agent that needs them, not through `{{LEAD}}`.
- `{{LEAD}}` gets only GOAL, DONE, DECISION, BLOCKED, NOTE, and DRIFT. Do not send it progress updates or copies of messages between agents.
- If two agents still disagree after two rounds, or a task goes back and forth more than three times, one of them sends DECISION to `{{LEAD}}` with both positions.
- `{{LEAD}}` asks the human before pushing, releasing, deleting branches or data, or changing a goal's scope.

## Messages

Send one line per message with Herdr:

```bash
herdr agent prompt <to> "<message>"
```

Send without `--wait`, then carry on or end your turn. Replies arrive as your next prompt.

Between agents:

- `TASK <id> | for: <goal slug> AC<n>,… | <what to do> | inputs: <paths, branches> | done when: <criteria> | route: <agent> → … → {{LEAD}}`: lead → the first agent on the route. `for:` names the goal and the acceptance criteria the task serves.
- `HANDOFF <id> | <from> | <result: branch@sha or paths> | <for, what to do, and done when from the TASK> | route: <the rest of the route>`: to the next agent on the route. When the next one is `{{LEAD}}`, send DONE instead.
- `CHANGES <id> | <from> | <findings with file:line, or a path>`: reviewer, qa, or security → the author of the branch or file. The author fixes it, then sends HANDOFF back to the agent that sent CHANGES.
- `QUESTION <id> | <from> | <question>`: to the agent that owns the answer: the analyst for the spec, the architect for the design, the branch's dev for its code. Pause work on `<id>` until the answer comes. If no agent owns the answer, send DECISION to `{{LEAD}}`.

To `{{LEAD}}`:

- `GOAL <slug> | <from> | <spec path> | <branch@sha>`: the refiner, only after the human approved the spec.
- `DONE <id> | <from> | <summary, with the verdict if you reviewed> | <branch@sha or paths>`: the last agent on the route.
- `DECISION <id> | <from> | <what to decide> | options: <a>; <b> | recommend: <one>`: a choice outside your role: scope, priority, a disagreement the agents did not settle, or anything the human must approve. Pause work on `<id>` until the answer comes.
- `BLOCKED <id> | <from> | <what is needed>`.
- `NOTE <id> | <from> | <fact>`: only a fact that changes the plan: a risk, a scope surprise, or an interface change that agents agreed on. It needs no reply.

Details longer than about 10 lines go into a file in your workdir; send its path. If `herdr agent prompt` fails with `agent_blocked`, run `herdr agent wait <to> --until idle --until done --timeout 600000`, then send once more.

To see where a task is, the lead reads an agent's output with `herdr agent read <name> --source recent-unwrapped --lines 200` and sees everyone's state with `herdr agent list`. It does not ask agents for status.

## Refining an idea

1. The human brings an idea to `{{REFINER}}` in its tab. That is its task until the human approves a spec or drops the idea.
2. `{{REFINER}}` asks the human 2 to 4 questions per round, with its question tool if it has one, and reads the code it needs. It asks other agents with QUESTION, for example the architect about feasibility. Use the idea's slug as `<id>`.
3. It writes the spec in the repo's spec dir (`specs/` if there is none): the problem, what is in and out of scope, numbered acceptance criteria (AC1, AC2, …) as Given/When/Then, and each open decision with the role that settles it.
4. When the human approves the spec, `{{REFINER}}` commits it on its branch and sends GOAL to `{{LEAD}}`. If `{{REFINER}}` is `{{LEAD}}`, it commits the spec on `{{MAIN_BRANCH}}` and plans the goal itself.
5. `{{LEAD}}` merges the spec commit into `{{MAIN_BRANCH}}`, places the goal among the others (it asks the human only when the order is unclear), and sends TASKs for it. From then on, a scope change is a DECISION for the human.

## Staying on course

`{{AUDITOR}}` checks that the lead's work serves the open goals and nothing else. `{{LEAD}}` sends it these copies, without `--wait`:

- each GOAL it takes on, before its first TASK. For a goal the human gave it directly: `GOAL <slug> | {{LEAD}} | <the goal> | criteria: AC1 <…>; AC2 <…>`.
- each TASK it sends.
- `DECIDED <id> | {{LEAD}} | <its answer to a DECISION or a DRIFT>`.
- `CLOSED <slug> | {{LEAD}} | merged <sha>, or parked by the human`.

`{{AUDITOR}}` stays silent while the work is on course. It sends `DRIFT <slug> | {{AUDITOR}} | <what drifts, from which criterion> | recommend: drop, park, or ask the human` to `{{LEAD}}` when:

- a TASK serves no criterion of an open goal, or its work goes beyond the criteria it names;
- work serves other work, not a criterion, more than one level deep (a task to unblock a task to unblock a task);
- tasks go on for a goal whose criteria all pass;
- a DECIDED adds or drops scope without the human's approval;
- a goal is CLOSED with a criterion that neither passes nor was parked by the human.

On DRIFT, `{{LEAD}}` drops or parks the drifting work, or asks the human to approve it as a scope change, then sends DECIDED. The lead does not overrule a DRIFT on its own. If the next copies continue the drift and no DECIDED answered it, `{{AUDITOR}}` alerts the human, who reads the details in its tab:

```bash
herdr notification show "herdr-team: drift on <slug>" --body "<one line>" --sound request
```

`{{AUDITOR}}` never sends messages to workers.

## Flow

For each goal, the lead chooses the stages the goal needs and puts their agents, in this order, on the TASK's route. If a stage's role is not on the team, the lead does that stage itself before it sends the TASK, or leaves it out.

1. **spec** (analyst): numbered acceptance criteria. Leave it out for a goal that came as GOAL.
2. **design** (architect): a design note when the change crosses modules.
3. **build** (dev): test-first, on the dev's own branch.
4. **test** (qa): the full suite plus new tests against the dev branch. Bugs go to the dev as CHANGES.
5. **review** (reviewer, then security if on the team): APPROVE, or CHANGES on `{{MAIN_BRANCH}}...<branch>`.
6. **integrate** (lead): when DONE arrives with an APPROVE, merge the branch with green tests into `{{MAIN_BRANCH}}`. Tell the devs; they rebase.
7. **docs and release** (docs, devops): a new TASK after the merge.

Independent tasks run in parallel lanes. Each agent works on one task at a time. A TASK or HANDOFF that arrives while you are busy waits until you finish; take them in the order they came.

## Git

- One writer per worktree. Commit only on your own branch.
- Only the lead merges into `{{MAIN_BRANCH}}`.
- Rebase on `{{MAIN_BRANCH}}` when the lead announces a merge.
