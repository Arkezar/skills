# Roles

The role catalog for step 3. A **writer** gets its own worktree. A **reader** works in the main checkout and reads other branches with `git diff`/`git show`. Tiers map to concrete models in [HARNESSES.md](HARNESSES.md). Every role follows the gates and evidence rules in `.herdr-team/SDLC.md`.

## Sizing

Start from the core four: lead, dev, reviewer, auditor. That is the smallest team with independent review and a check that the lead stays on the goal. Add a role only when a profile fact matches its "include when". Above six agents, the lead spends more on coordination than an extra lane gives back. In a small repo, fold roles together (analyst into lead, security into reviewer, devops into dev) and name the fold in the role file.

## lead — delivery lead (always, exactly 1)

- Mission: turn the human's goals into merged, reviewed changes.
- Owns: the durable task state, preflight assignment, routes, decisions, answers to DRIFT, and integration through the accepted workflow. Owns all human communication except idea refinement.
- Done means: each goal reaches its agreed merged or released target with SDLC evidence, or the human parks it.
- Reader of implementation code. Its writes are task-state updates and integration. When it refines a spec, a writer commits that spec. Tier: frontier, high effort, on a harness that queues input while it works.

## analyst — requirements

- Mission: refine the human's ideas into approved specs, and make each goal unambiguous before anyone builds.
- Owns: refinement talks with the human, specs with numbered, testable acceptance criteria (Given/When/Then), a domain glossary, answers to other agents' spec questions. Scope questions go to the lead as DECISION.
- Done means: the human approved the spec and the lead got it as GOAL. As a spec stage on a route: every criterion is testable and the spec went to the next agent.
- Include when: the human wants to refine ideas with an agent, the repo is empty, a product-facing app has an issue tracker or `specs/` dir, or goals arrive vague. Without an analyst, the lead refines ideas.
- Writer (specs only). Tier: frontier, high effort, because refinement needs strong reasoning.

## architect

- Mission: keep the structure fit for the next changes.
- Owns: design notes and ADRs, module boundaries, interfaces, a design check before any cross-module task, and answers to the devs' design questions.
- Done means: each design names the modules it touches, the interface changes, and one rejected alternative.
- Include when: the repo is empty, has several packages or services, has an ADR dir, is large (more than about 50k lines), or has a cross-cutting change planned.
- Writer (docs only). Tier: frontier, high effort.

## dev — developer (1 to 3)

- Mission: implement tasks test-first on its own branch.
- Owns: the code and unit tests for its tasks, fixes for CHANGES from qa and the reviewer, keeping its branch rebased, commits in the repo's message convention.
- Done means: the acceptance criteria and applicable SDLC checks pass on the candidate SHA. The next agent receives branch@sha and evidence. Incorporate QA's test commits before final validation and review.
- Count: one per independently changeable area (`dev-web`, `dev-api`), at most 3.
- Writer. Tier: workhorse, medium effort.

## qa — quality

- Mission: prove the change works, and find where it does not.
- Owns: a test plan per goal, integration and e2e tests, required checks on the combined candidate, and bug reports with repro steps. Commit tests only on its own branch. Follow the QA commit flow in PROTOCOL.md.
- Done means: every AC maps to a passing test or justified manual check under SDLC.md, with evidence for the combined candidate SHA. Otherwise send CHANGES to the dev.
- Include when: there is a test suite or a UI/API surface, or the profile lists risk areas.
- Writer (tests). Tier: workhorse or fast.

## reviewer (always, exactly 1)

- Mission: an independent second opinion before every merge.
- Owns: reviewing `<main>...team/<role>` against the spec, the conventions, and security basics. The verdict is APPROVE, or CHANGES with file:line findings.
- Done means: each candidate has a verdict for its exact SHA. CHANGES go to its author. APPROVE and prior evidence go to the next agent. Review again after candidate changes. Remain independent of all candidate authors.
- Reader. Tier: frontier, from a different model vendor than the devs when one is available.

## auditor — drift check (always, exactly 1)

- Mission: keep the lead's work on the goals the human set, so the team does not dig into work that no goal needs.
- Owns: checking each copy that `team-send.sh` passes on (GOAL, TASK, DECIDED, CLOSED) against the goal's numbered criteria and the team log, DRIFT reports to the lead, and a notification to the human when the lead goes on drifting.
- Done means: every copy was checked, and every drift it found was answered by a DECIDED or reported to the human.
- Reader. It never sends work to workers. Tier: workhorse, medium effort, from a different model vendor than the lead when one is available.

## devops — delivery

- Mission: keep build, CI, and release working.
- Owns: CI config, containers, IaC, release scripts, release notes, artifact identity, smoke checks, and the recovery procedure.
- Done means: delivery reaches the release gate in SDLC.md, or the lead receives a blocker with evidence. Prepare code changes on its branch for validation and review before release.
- Include when: CI config, a Dockerfile, IaC, or deploy scripts exist, or a goal includes shipping.
- Writer. Tier: workhorse.

## security

- Mission: catch what an attacker would use.
- Owns: a threat model per goal, security review of branches, dependency audit.
- Include when: the code has auth, crypto, payments, PII, public network services, or secrets in IaC. Otherwise the reviewer covers security basics.
- Reader. Tier: frontier.

## docs — technical writer

- Mission: keep the docs true to the code that was merged.
- Owns: README, docs, changelog entries.
- Include when: the repo is a library or public API, has a docs site or `docs/` dir, or ships a user-facing CLI.
- Writer. Tier: fast.

## Skill seeds

Queries for `npx skills find`. Add the stack to each query (`react testing`, not `testing`).

| Role | Seeds |
|---|---|
| lead | `herdrdev/herdr@herdr` (always) |
| analyst | spec, requirements |
| architect | architecture, adr |
| dev | `<stack>` best practices, tdd |
| qa | `<test framework>`, e2e testing |
| reviewer | code review |
| auditor | none: it works from PROTOCOL.md and the policy's goal state |
| devops | `<CI system>`, docker |
| security | security review |
| docs | documentation, readme |
