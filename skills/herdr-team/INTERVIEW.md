# Empty-repo interview

Ask in rounds of 2 to 4 questions, one round per message, with the harness's question tool if it has one. Fit each round to the answers so far, and skip anything an earlier answer settled. Where you have a basis, offer a recommended option.

The brief needs these fields:

1. **Product**: what it does, for whom, and the problem it removes.
2. **Shape**: CLI, library, web app, API, mobile, desktop, game, data pipeline, or infra.
3. **Stack**: language, framework, storage, hosting, or "architect decides".
4. **Quality bar**: prototype, internal tool, or production. Test expectations. Compliance or security needs.
5. **Process**: forge and issue tracker, CI, who approves merges and releases (default: the human approves pushes and releases).
6. **Budget**: how many agents, and how many frontier models, are worth paying for.
7. **Harnesses**: CLIs or vendors to use or avoid. Show the ones discover found.

Done when every field has an answer. If the user says a field is undecided, the brief names the role that decides it.

The brief becomes `.herdr-team/BRIEF.md` in step 5:

```markdown
# Project brief

- Product:
- Shape:
- Stack:
- Quality bar:
- Process:
- Budget:
- Harnesses:
- Decided later by: <field> → <role>
```
