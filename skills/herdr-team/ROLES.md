# Roles

The role catalog for step 3. A **writer** gets its own worktree. A **reader** works in the main checkout and reads other branches with `git diff`/`git show`. Tiers map to concrete models in [HARNESSES.md](HARNESSES.md).

## Sizing

Start from the core three: lead, dev, reviewer. That is the smallest team with independent review. Add a role only when a profile fact matches its "include when". Above six agents, the lead spends more on coordination than an extra lane gives back. In a small repo, fold roles together (analyst into lead, security into reviewer, devops into dev) and name the fold in the role file.

## lead — delivery lead (always, exactly 1)

- Mission: turn the human's goals into merged, reviewed changes.
- Owns: the plan and task list, dispatch, the SDLC order, merges into the main branch, all talk with the human.
- Done means: each goal is merged with tests green and an APPROVE, or the human agreed to park it.
- Reader; merges are its only writes. Tier: frontier, high effort, on a harness that queues input while it works.

## analyst — requirements

- Mission: make each goal unambiguous before anyone builds.
- Owns: specs with testable acceptance criteria (Given/When/Then), a domain glossary, open questions sent to the lead.
- Done means: the lead accepted the spec.
- Include when: the repo is empty, or a product-facing app has an issue tracker or `specs/` dir, or goals arrive vague.
- Writer (specs only). Tier: workhorse.

## architect

- Mission: keep the structure fit for the next changes.
- Owns: design notes and ADRs, module boundaries, interfaces, and a design check before any cross-module task.
- Done means: each design names the modules it touches, the interface changes, and one rejected alternative.
- Include when: the repo is empty, has several packages or services, has an ADR dir, is large (more than about 50k lines), or has a cross-cutting change planned.
- Writer (docs only). Tier: frontier, high effort.

## dev — developer (1 to 3)

- Mission: implement tasks test-first on its own branch.
- Owns: the code and unit tests for its tasks, keeping its branch rebased, commits in the repo's message convention.
- Done means: the acceptance criteria are met, the repo's tests, lint, and typecheck are green on the branch, and DONE was sent with branch@sha.
- Count: one per independently changeable area (`dev-web`, `dev-api`), at most 3.
- Writer. Tier: workhorse, medium effort.

## qa — quality

- Mission: prove the change works, and find where it does not.
- Owns: a test plan per goal, integration and e2e tests, full-suite runs on dev branches, bug reports with repro steps.
- Done means: every acceptance criterion maps to a passing test, or a bug report went to the lead.
- Include when: there is a test suite or a UI/API surface, or the profile lists risk areas.
- Writer (tests). Tier: workhorse or fast.

## reviewer (always, exactly 1)

- Mission: an independent second opinion before every merge.
- Owns: reviewing `<main>...team/<role>` against the spec, the conventions, and security basics. The verdict is APPROVE, or CHANGES with file:line findings.
- Done means: every branch it was given has a verdict sent to the lead.
- Reader. Tier: frontier, from a different model vendor than the devs when one is available.

## devops — delivery

- Mission: keep build, CI, and release working.
- Owns: CI config, containers, IaC, release scripts, release notes.
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
| devops | `<CI system>`, docker |
| security | security review |
| docs | documentation, readme |
