# Harnesses

How to pick and launch a model per Herdr agent kind. `scripts/discover.sh` prints what is installed. A harness counts as available only if discover lists it.

## Picking a model

Only propose a model ID that discover printed in that harness's catalog. If a harness has no catalog, propose only `harness default` and say so.

Map role tiers to the catalog's own words, not to remembered names (they go stale):

- **frontier**: the most capable current model ("frontier", "most demanding", the top family at its highest version). Use it for lead, architect, reviewer, and security.
- **workhorse**: the catalog's recommended coding or everyday model. Use it for dev, analyst, devops, and qa.
- **fast**: the smallest current model ("fast", "affordable", mini or nano sizes). Use it for docs, and for qa on a tight budget.

Choose a current-generation model over entries the catalog marks "older" or "previous". Vendor means the model's maker, not the harness: pi can serve Claude models, so pi and Claude Code can be the same vendor. When two or more vendors are available, put the reviewer on a different vendor from the devs. For the lead, choose a harness whose TUI queues input typed while it works (pi and Claude Code do), because worker reports arrive as prompts.

## Kinds verified on Herdr 0.9.5

Write each launch arg as its own TAB field in `team.tsv`.

| Kind | Catalog | Launch args | Effort values | `npx skills -a` |
|---|---|---|---|---|
| `pi` | `pi --list-models` → `provider/id` | `--model <provider/id>` `--thinking <level>` | off, minimal, low, medium, high, xhigh, max (only if the catalog says `thinking=yes`) | `pi` |
| `claude` | aliases from `claude --help` | `--model <alias>` `--effort <level>` | low, medium, high, xhigh, max | `claude-code` |
| `codex` | `codex debug models` (entries with `visibility == "list"`) | `-m <slug>` `-c model_reasoning_effort=<level>` | the model's `efforts=` | `codex` |
| `opencode` | `opencode models` | none: the 2.3 TUI has no model flag, so it runs its configured default | — | `opencode` |

Messaging needs these extra args. Without them, every report becomes an approval dialog, or fails:

- `claude`: workers add `--allowedTools` `Bash(herdr agent prompt *),Bash(herdr agent wait *)`. The lead also adds `Bash(herdr agent read *),Bash(herdr agent get *),Bash(herdr agent list)` to that same field. Keep `herdr agent send-keys` and `herdr pane` out: they can answer another agent's dialogs or run commands in other panes.
- `codex`: add `-c` `sandbox_workspace_write.network_access=true`. Without it, the sandbox denies the Herdr socket (verified). This also opens network access for the sandbox, so say so in the proposal.

A new worktree triggers trust dialogs in claude and codex. `launch-team.sh` waits for the human to answer them.

## Other kinds

Read `<bin> --help` for a model flag and a model list before you propose a model. Skills-CLI agent ids: `copilot` → `github-copilot`, `cursor` → `cursor`, `kimi` → `kimi-code-cli`, `qwen` → `qwen-code`, `droid` → `droid`, `grok` → `grok`, `kilo` → `kilo`, `devin` → `devin`, `hermes` → `hermes-agent`, `agy` → `antigravity-cli`, `amp` → `amp`, `gemini` → `gemini-cli`, `cline` → `cline`, `kiro` → `kiro-cli`, `qodercli` → `qoder`. The kinds `omp`, `mastracode`, `letta`, `maki`, and `muse` have no skills-CLI id: skip skill installs for them and tell the user.

## Autonomy flags

Offer these only when the user asks for fewer approval dialogs, and put them in the proposal:

- `claude`: `--permission-mode acceptEdits` (file edits run without asking) or `auto`.
- `codex`: `-a never` (failures return to the model instead of asking the human).
