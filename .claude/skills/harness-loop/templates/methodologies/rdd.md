## 工作循环: RDD (README-Driven Development)

README before code. The README is written first, describing the finished
behavior of the feature as if it already works. Implementation then lives up
to the README; if the README lies, the code is wrong, not the README.

### Workflow

1. Open `docs/readme-first.md` (the README-first workspace). Write the section
   for the feature as though it is shipped: what it does, how a user invokes
   it, what they see, what they do not see.
2. Write the public API or CLI surface in the README: signatures, command
   examples, example output. These are the contract — design them carefully
   before any implementation exists.
3. Review the README section for honesty: every example must be runnable as
   written. If you cannot write a real example, the design is not ready.
4. Implement the API or CLI surface described. Match signatures and output
   formats exactly; deviation means the README or the code is wrong, and the
   README wins.
5. Run `bash scripts/check-consistency.sh`. The check extracts examples from
   the README, runs them, and verifies the actual output matches what the
   README claims.
6. When the design genuinely needs to change during implementation, update
   the README FIRST, then update code. Never let the README lag behind code;
   a stale README is worse than no README.
7. On iteration close, every code-visible behavior is described in the README
   and every README example runs successfully against the current code.

### Acceptance criteria

- [ ] Every public function, CLI command, or endpoint added this iteration
      has a runnable example in `docs/readme-first.md`
- [ ] `bash scripts/check-consistency.sh` exits 0 (README examples match
      actual output)
- [ ] No production code in this iteration extends behavior beyond what the
      README documents
- [ ] The README section for the feature is committed before the
      implementation in git history (commit order is enforceable)

### Required artifacts

- `docs/readme-first.md` — the README-first workspace where features are
  described before they are built. Scaffolding is
  `templates/scaffolding/methodology-dirs/readme-first/`.
- (Optional) `docs/readme-first/examples/` — output samples, fixture inputs,
  and reference outputs that `check-consistency.sh` replays against the code.

### Anti-patterns

- **README after implementation.** Writing the code, then documenting what
  was built. The README becomes a post-hoc rationalization; the design
  choices were never subjected to the README's honesty test. Always write
  the README first.
- **Aspirational examples.** Examples in the README that the code does not
  yet support ("we'll add this next sprint"). The README is the contract
  for the current commit; future work goes in `TASKS.md`, not in lies.
- **Vague behavior descriptions.** "The system processes the request
  efficiently." Replace with the concrete observable: "Returns 200 with a
  JSON body of shape X within 200ms p95."
- **README drift.** Code gains a feature, the README is never updated.
  `check-consistency.sh` exists precisely to catch this — never disable it
  on a RDD project.
