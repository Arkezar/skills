# skills

Agent skills you can install with the [skills CLI](https://github.com/vercel-labs/skills).

```bash
npx skills add ~/Source/skills --skill herdr-team          # from this checkout
npx skills add <git-url-of-this-repo> --skill herdr-team   # once it is published
```

| Skill | What it does |
|---|---|
| [herdr-team](skills/herdr-team/SKILL.md) | Staffs an SDLC team of coding agents that work together in [Herdr](https://herdr.dev). It surveys the repo, or interviews you when the repo is empty, and proposes roles with a harness and model per agent. After you accept, it installs skills and launches the team. |
