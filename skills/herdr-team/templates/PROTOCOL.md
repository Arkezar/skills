# Team protocol

This team works on `{{REPO}}`. The main branch is `{{MAIN_BRANCH}}`. The human talks only to the lead, `{{LEAD}}`.

| Agent | Role | Workdir | Branch |
|---|---|---|---|
{{ROSTER_ROWS}}

## Who talks to whom

- `{{LEAD}}` assigns every task and is the only agent that messages workers.
- Workers message only `{{LEAD}}`.
- `{{LEAD}}` asks the human before pushing, releasing, deleting branches or data, or changing a goal's scope.

## Messages

Send one line per message with Herdr:

```bash
herdr agent prompt <to> "<message>"
```

Send without `--wait`, then carry on or end your turn. Replies arrive as your next prompt.

- `TASK <id> | <goal> | inputs: <paths, branches> | done when: <criteria>`: lead → worker.
- `DONE <id> | <name> | <summary> | <branch@sha or paths>`: worker → lead.
- `QUESTION <id> | <name> | <question>`: worker → lead. Pause work on `<id>` until the answer comes.
- `BLOCKED <id> | <name> | <what is needed>`: worker → lead.

Details longer than about 10 lines go into a file in your workdir; send its path. If `herdr agent prompt` fails with `agent_blocked`, run `herdr agent wait <to> --until idle --until done --timeout 600000`, then send once more.

The lead reads a worker's output with `herdr agent read <name> --source recent-unwrapped --lines 200` and sees everyone's state with `herdr agent list`.

## Flow

For each goal, the lead runs these stages in order. If a stage's role is not on the team, the lead does that stage itself.

1. **spec** (analyst): acceptance criteria.
2. **design** (architect): a design note when the change crosses modules.
3. **build** (dev): test-first, on the dev's own branch.
4. **test** (qa): the full suite plus new tests against the dev branch.
5. **review** (reviewer): APPROVE, or CHANGES on `{{MAIN_BRANCH}}...<branch>`.
6. **integrate** (lead): merge an approved branch with green tests into `{{MAIN_BRANCH}}`. Devs then rebase.
7. **docs and release** (docs, devops).

Independent tasks run in parallel lanes. Each worker has one task at a time.

## Git

- One writer per worktree. Commit only on your own branch.
- Only the lead merges into `{{MAIN_BRANCH}}`.
- Rebase on `{{MAIN_BRANCH}}` when the lead announces a merge.
