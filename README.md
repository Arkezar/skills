# skills

Agent skills you can install with the [skills CLI](https://github.com/vercel-labs/skills).

```bash
npx skills add Arkezar/skills --skill herdr-team    # from GitHub
npx skills add ~/Source/skills --skill herdr-team    # from a local checkout
```

| Skill | What it does |
|---|---|
| [herdr-team](skills/herdr-team/SKILL.md) | Staffs an SDLC team of coding agents that work together in [Herdr](https://herdr.dev). It surveys the repo, or interviews you when the repo is empty, and proposes roles with a harness and model per agent. It also proposes SDLC gates, checks, approvals, task state, and release criteria. After you accept the roster and policy, it installs skills and launches the team. |

## Checks

Run these commands from the repo root. The tests require Bash, Git, and jq.
They use temporary repos and a stub Herdr. They do not start real agents.

```bash
bash -n skills/herdr-team/scripts/*.sh tests/*.sh
bash tests/team-send.test.sh
bash tests/launch-team.test.sh
```

Existing teams need an accepted `.herdr-team/SDLC.md` before relaunch.
Synchronize the protocol, policy, roster, and role files across their worktrees.
Agent startup and SDLC readiness are separate checks.
