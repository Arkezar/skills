---
name: herdr-team
description: Staff an SDLC team of coding agents that work together in Herdr. Surveys the repo (interviews the user when it is empty), proposes roles with a harness and model per agent from what is installed, and after the user accepts, writes the team files, installs skills with `npx skills`, and launches the team. Use to set up, resize, or relaunch an agent team, or to pick models for several agents.
---

# Herdr team

A **team** is a lead plus workers, each a coding agent in its own Herdr tab, running one SDLC loop: spec → design → build → test → review → integrate. The lead alone assigns work and merges. The human talks to the lead, and refines new ideas with the analyst. Inside a task, agents message each other directly through Herdr. The lead gets only results, decisions to take, and facts that change the plan. Every writer gets its own git worktree.

Talk to the user in their language. Write the team files in the language of the repo's docs (English for an empty repo).

Paths below are relative to this skill's directory. References: [ROLES.md](ROLES.md), [HARNESSES.md](HARNESSES.md), [INTERVIEW.md](INTERVIEW.md), [templates/PROTOCOL.md](templates/PROTOCOL.md).

## 1. Inventory

Run `scripts/discover.sh <repo>`. Its output is the source of truth for the proposal: Herdr state, the available harnesses with their model catalogs, tools, and repo facts.

- Herdr missing: stop and tell the user.
- `npx` missing: skill installs drop out of the plan. `jq` missing: launch drops out until the user installs it.

Done when every available harness has a catalog, or is marked default-only.

## 2. Understand the project

Branch on the repo facts:

- **Existing team** (`existing team: yes`): show the roster from `.herdr-team/team.tsv` and ask: relaunch as is (step 7), amend (step 3, starting from this roster), or rebuild.
- **Empty** (`empty: yes`): run the interview in INTERVIEW.md. Done when the brief has every field answered.
- **Otherwise**, survey: README, manifests, CI config, test dirs, `AGENTS.md`/`CLAUDE.md`, `docs/`, `specs/`, ADRs, `git log --oneline -30`, `git worktree list`, `git remote -v`. Write a **profile**: stacks and their directories, size, test maturity (runner, CI), delivery (CI, containers, IaC, releases), risk areas (auth, payments, PII, public endpoints, secrets), independently changeable areas (lanes), and the conventions in force. Done when every claim cites a path or a command's output.

## 3. Compose

- **Roles and headcount** from ROLES.md. Every role you include points to a profile or brief fact.
- **Harness, model, effort** per agent from HARNESSES.md. A model is proposable only if discover printed it in that harness's catalog.
- **Names**: `<slug>-<role>`, where slug is the repo name cut to at most 8 chars. Names must match `[a-z][a-z0-9_-]{0,31}` and must not appear in `herdr agent list`.
- **Workdir**: writers get `../<repo>-<role>` on branch `team/<role>`. Readers use `.`.
- **Skills** per role: first the installed ones (`npx -y skills@latest ls`, then with `-g`), then `npx -y skills@latest find <query>` with the seeds in ROLES.md. Keep at most 3 per role, each with 1K+ installs or a known publisher. The lead always gets `herdrdev/herdr@herdr`.
- **Integrations**: each chosen kind that discover does not list as `current` needs `herdr integration install <kind>`.

## 4. Propose and get acceptance

Send one message:

1. The profile (or brief) in at most 5 lines.
2. The roster:

   | Agent | Role | Harness | Model | Effort | Workdir (branch) | Skills | Why |
   |---|---|---|---|---|---|---|---|

3. The side effects, in the order step 6 runs them: files written, integrations installed, skill install commands, the commit, worktrees, and launch topology (one workspace `<repo> team`, one tab per agent). Add a cost note: how many agents run frontier models.
4. Approvals: agents keep their harness's default approvals, and a blocked agent shows up in Herdr's sidebar. Offer the autonomy flags from HARNESSES.md if the user wants fewer dialogs.

Ask: accept, amend, or cancel (use the harness's question tool if it has one). After an amendment, show the full table again. Write and install nothing until the user explicitly accepts the table as shown. Done when they have.

## 5. Write the team files

Write these files in `.herdr-team/`:

- `team.tsv`: lead first, in the format given in the header of `scripts/launch-team.sh`. Each agent arg is its own TAB field.
- `PROTOCOL.md`: from `templates/PROTOCOL.md`, with every `{{…}}` filled in. `{{REFINER}}` is the analyst, or the lead if the team has no analyst.
- `roles/<name>.md`, one per agent: its ROLES.md entry made concrete for this repo, with real paths, the build/test/lint commands, its branch, its skills, and the conventions in force. The lead's file also says: use the herdr skill, and after `ready`, wait for a goal from the human or a GOAL message. The analyst's file says: after `ready`, wait for the human to bring an idea, or for a TASK.
- `BRIEF.md`: the interview brief (empty-repo branch only).

Done when no `{{` remains and every roster name has a role file.

## 6. Install and prepare

Run these in the repo root, in order. Stop at the first failure and report it.

1. `herdr integration install <kind>` for each kind from step 3.
2. Skills, project scope, one command per source: `npx -y skills@latest add <source> -s <skill>... -a <skills-agent-id>... -y` (agent ids are in HARNESSES.md).
3. Commit the team files, `.agents/`, the per-harness skill dirs, and `skills-lock.json` with `chore: add herdr agent team`. Worktrees branch from this commit, so they get the files and skills.
4. Run `git worktree add ../<repo>-<role> -b team/<role>` for each writer that has no worktree yet.

## 7. Launch

This needs a Herdr pane (`HERDR_ENV=1`). If you are not in one, give the user the command `<this skill>/scripts/launch-team.sh <repo>/.herdr-team` to run from a Herdr pane, and stop.

Launching takes minutes and may wait on the human, so run it in a sibling pane:

```bash
herdr pane split --current --direction down --cwd "$PWD" --no-focus   # pane id: .result.pane.pane_id
herdr pane run <pane> "<this skill>/scripts/launch-team.sh .herdr-team"
herdr pane wait-output <pane> --regex 'team ready|launch-team:' --timeout 240000   # repeat until it matches
```

When the script reports it is waiting for you, tell the user which tab needs them. If it fails with `launch-team: …`, read the pane, report, and ask how to go on. It is safe to run again: it skips agents that are already running.

Done when the pane shows `team ready`. Then report `herdr agent list` for the team and tell the user to talk to the lead (`herdr agent focus <lead>`). If the team has an analyst, also tell them to bring new ideas to it (`herdr agent focus <analyst>`).
