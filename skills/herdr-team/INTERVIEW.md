# Empty-repo interview

Ask in rounds of 2 to 4 questions, one round per message, with the harness's question tool if it has one. Fit each round to the answers so far, and skip anything an earlier answer settled. Where you have a basis, offer a recommended option.

The brief needs these fields:

1. **Product**: what it does, for whom, and the problem it removes.
2. **Shape**: CLI, library, web app, API, mobile, desktop, game, data pipeline, or infra.
3. **Stack**: language, framework, storage, hosting, or "architect decides".
4. **Quality bar**: prototype, internal tool, or production. Required tests and manual checks. Security, data, compliance, and accessibility needs.
5. **Process**: forge and tracker, local merge or PR, required CI, and who approves merges, pushes, and releases. Default: the human approves pushes and releases. Define setup and check commands, or assign a bootstrap task to establish them. Choose a durable state location.
6. **Delivery**: whether completion means merged or released. For releases, define the artifact, target, release command, smoke checks, and recovery procedure. Mark irrelevant fields as not applicable with a reason.
7. **Budget**: how many agents, and how many frontier models, are worth paying for.
8. **Harnesses**: CLIs or vendors to use or avoid. Show the ones discover found.

Done when every field has an answer or a named decision owner. Unsettled decisions that affect a gate block that gate. Use the answers to fill templates/SDLC.md before acceptance.

The brief becomes `.herdr-team/BRIEF.md` in step 5:

```markdown
# Project brief

- Product:
- Shape:
- Stack:
- Quality bar:
- Process:
- Delivery:
- Budget:
- Harnesses:
- Decided later by: <field> → <role>
```
