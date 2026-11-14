# SDLC policy

This policy records the process accepted by the human. Every agent reads it with PROTOCOL.md.
Every field needs a concrete value. Use `not applicable: <reason>` for controls that do not apply.

## Delivery and authority

- Quality bar: {{QUALITY_BAR}}.
- Main branch: {{MAIN_BRANCH}}.
- Integration: {{INTEGRATION_MODE_AND_TARGET}} (local merge or PR, including branch protection and required CI checks).
- Merge approval: {{MERGE_APPROVER}}.
- Push approval: {{PUSH_APPROVER}}.
- Release approval: {{RELEASE_APPROVER}}.
- Risk controls: {{RISK_CONTROLS_AND_OWNERS}} (security, dependencies, secrets, data, compliance, and accessibility where applicable).
- State location: {{STATE_LOCATION}} (tracker URL or absolute path to STATE.md in the main checkout).

## Issue tracker

- Tracker choice: {{ISSUE_TRACKER}} (provider, or `none: local STATE.md`).
- Target: {{TRACKER_TARGET}} (instance URL and repository or project identifier).
- Access: {{TRACKER_ACCESS}} (available CLI or MCP tool in the lead's harness, authentication method, and credential reference).
- Permissions: {{TRACKER_PERMISSIONS}} (allowed reads, issue creation, updates, comments, transitions, and actions that need human approval).
- Status mapping: {{TRACKER_STATUS_MAPPING}} (team statuses to native statuses, labels, or fields, including merged versus released).

Choose the tracker explicitly with the human during first setup, even for an existing repo.
Treat remotes and existing integrations as recommendations, not consent.
Use one source of truth: the selected tracker, or local STATE.md after an explicit `none` decision.
Set the state location to that source. Link goals, AC, branches, PRs, and evidence to its task records.
Use native issue IDs in task messages. If one issue contains several tasks, record a stable mapping for their task IDs.
The lead owns tracker updates. Other agents send changes through the protocol unless the policy grants them tracker permissions.
Record credential names or profile references only. Keep token values outside team files and messages.

Before launch, verify the target and read access from the lead's harness with a read-only operation.
Confirm required write permissions from provider metadata or the human. Do not create test issues to probe permissions.
Record the verification result and any blocker. Resolve missing access before dispatching implementation tasks.
Create or change external projects, labels, or workflows only after explicit approval of those side effects.
If the tracker becomes unavailable, report BLOCKED and preserve pending updates for reconciliation.
Resume after access returns, or after the human accepts a policy amendment that changes the source of truth.
For `none`, mark external access fields as not applicable. Keep the local state path and team statuses concrete.

## Environment and checks

Use one row per check and stack directory. Record commands from the repo, not guessed commands.
Mark missing controls as `missing`, with an owner and a prerequisite task. Missing controls are not passing checks.
For a new repo, define the intended checks and a bootstrap task before feature work.

| Check | Working directory | Command or CI job | Required for | Owner |
|---|---|---|---|---|
| Setup | {{SETUP_DIR}} | {{SETUP_COMMAND}} | First build and environment changes | {{SETUP_OWNER}} |
| Build | {{BUILD_DIR}} | {{BUILD_COMMAND}} | {{BUILD_SCOPE}} | {{BUILD_OWNER}} |
| Unit/integration/e2e tests | {{TEST_DIR}} | {{TEST_COMMANDS}} | {{TEST_SCOPE}} | {{TEST_OWNER}} |
| Lint | {{LINT_DIR}} | {{LINT_COMMAND}} | {{LINT_SCOPE}} | {{LINT_OWNER}} |
| Typecheck | {{TYPECHECK_DIR}} | {{TYPECHECK_COMMAND}} | {{TYPECHECK_SCOPE}} | {{TYPECHECK_OWNER}} |
| Risk controls | {{RISK_DIR}} | {{RISK_CHECKS}} | {{RISK_SCOPE}} | {{RISK_OWNER}} |

### Preflight

Before the first implementation, the lead assigns setup and the required checks to a writer.
Record the environment, commands, exit codes, output paths, and baseline SHA in the state location.
Keep credentials outside commits, messages, and test output.
For each failure, record whether it already exists, its owner, and the blocked tasks.
Start feature work only after setup succeeds and required checks pass, or the human approves a bounded exception.
For an empty repo, permit only the approved bootstrap task until its checks exist and pass.
For this task's Ready gate, require approved setup AC and planned checks instead of a passing baseline.
Repeat preflight after changes to setup, commands, or dependencies, and before work resumes in a changed environment.

## Gates and evidence

A role can absorb another role's duty. The duty remains mandatory.

| Gate | Required evidence |
|---|---|
| Ready | Approved scope and numbered AC, dependencies settled, preflight passed, design for cross-module changes |
| Validate | Each AC maps to a passing test or a justified manual check. All applicable required checks pass. |
| Review | Independent reviewer APPROVE for the exact candidate SHA, including any required security verdict |
| Integrate | Approved candidate, required human approval, checks on the integrated result, and required CI success |
| Release | Human approval, identified artifact and environment, deployment result, and passing smoke checks |

Record evidence in the state location or a linked report.
Each check records the exact SHA, directory, command or CI URL, exit status, and output path.
Each review records the reviewer, exact SHA, verdict, and findings or report path.
After any candidate change, including a rebase or conflict resolution, repeat applicable checks and independent review.
The lead verifies the final integration SHA against the approved candidate and records checks for the integrated result.
For a PR workflow, use the forge's required checks. If a merge queue is configured, use it.
Keep integration incomplete until the required checks pass on the final integrated result.
A failed integration blocks dependent work. Ask the human before a revert, repair, or other recovery action that needs approval.

Only the human can waive a gate.
Record each exception with its goal, gate, SHA, reason, risk, compensating check, owner, and expiry or closing condition.
A waiver is not a passing result. Never waive independent review or required human authorization.

## Task state

The lead maintains the state location after every handoff, verdict, decision, blocker, integration, and release.
All agents use this shared location, not the STATE.md snapshot in their own worktree.
Workers send evidence with HANDOFF, CHANGES, and DONE. The lead can read worker output to recover a missed update.
Use this minimum record in the selected tracker or the explicitly chosen local state file:

| Task | Goal / AC | Owner | Status | Branch / SHA | Evidence / verdicts | Dependencies / blockers |
|---|---|---|---|---|---|---|

Statuses: planned → active → validating → reviewing → integrating → merged → released.
Use blocked or parked with a reason. Return changed candidates to validating.
Record each goal's completion target: `merged` or `released`, with the human's approval.
Before resuming work, reconcile this record with branches, CI, and the agents' actual state.
The auditor's message log checks scope. It does not replace task state or quality evidence.

## Release contract

- Release applicability and completion target: {{RELEASE_APPLICABILITY}}.
- Artifact and version method: {{ARTIFACT_AND_VERSION}}.
- Target environment and release owner: {{RELEASE_TARGET_AND_OWNER}}.
- Release command or pipeline: {{RELEASE_COMMAND}}.
- Smoke checks and expected results: {{SMOKE_CHECKS}}.
- Rollback or recovery procedure, including migrations and backups: {{RECOVERY_PROCEDURE}}.

For goals that require delivery, finish required docs and release preparation before release approval.
Release only the identified artifact from the validated integration SHA.
Record the approval, version or digest, source SHA, environment, deployment result, and smoke evidence.
On a failed deployment or smoke check, keep the goal open and use the approved recovery procedure.
Close a `merged` goal after integration passes. Close a `released` goal only after its release gate passes.
For repos without releases, record `not applicable` with a reason in each release field.
