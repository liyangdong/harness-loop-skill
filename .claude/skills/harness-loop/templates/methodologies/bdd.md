## 工作循环: BDD (Behavior-Driven Development)

Gherkin scenarios before implementation. Each feature is described as a set of
Given/When/Then scenarios in a `.feature` file. Step definitions glue those
scenarios to executable code. The scenarios ARE the spec, in a form both
humans and the test runner can read.

### Workflow

1. Write a `.feature` file at `features/<feature>.feature`. Each scenario uses
   strict Gherkin syntax: `Feature:`, `Scenario:`, `Given`, `When`, `Then`,
   `And`. One scenario per behavior; no `But` (ambiguous in some runners).
2. Read every scenario out loud. If a non-engineer on the team cannot
   understand it, rewrite it in plainer language. BDD's value lives in the
   readability of the scenario text.
3. Run `bash scripts/check-tests.sh`. The new scenarios will be flagged as
   "undefined steps" — copy the suggested step-definition snippets.
4. Implement step definitions under `features/step_definitions/` (or the
   language-appropriate location). Each step binds to one line of glue code
   that calls into production code.
5. Write the minimum production code that makes the step definitions pass.
   Run `bash scripts/check-tests.sh` again — the scenario must report green.
6. Refactor: extract page objects, factories, or helpers as the step set
   grows. Re-run the suite after every extraction; never commit a red
   scenario.
7. When a scenario changes during implementation, edit the `.feature` file
   FIRST, then update step definitions, then production code. Scenario text
   is the source of truth.

### Acceptance criteria

- [ ] Every behavior added this iteration has at least one scenario in a
      `features/*.feature` file
- [ ] `bash scripts/check-tests.sh` reports zero undefined and zero pending
      steps (all scenarios green)
- [ ] No production code in this iteration lacks a scenario exercising it
- [ ] Each scenario uses exactly one `When` clause (a single action per
      scenario; checkable by grepping `When` count per `Scenario` block)

### Required artifacts

- `features/*.feature` — Gherkin feature files. Scaffolding directory is
  `templates/scaffolding/methodology-dirs/features/`.
- `features/step_definitions/` — glue code mapping Gherkin steps to
  production code. One step definition file per feature is the common shape.

### Anti-patterns

- **Implementation without a scenario.** Writing production code first, then
  inventing a scenario that happens to pass. The scenario did not drive the
  design; it rubber-stamped it. Always write the scenario first.
- **Ambiguous Given/When/Then.** "Given some state, When the user does stuff,
  Then it works." Each clause must name a concrete precondition, a concrete
  action, and a concrete observable outcome. "stuff" and "works" fail this.
- **Multi-action scenarios.** One scenario chaining three `When` clauses to
  test a workflow. Scenarios should pin one behavior; workflows are covered
  by composing multiple single-behavior scenarios.
- **Leaky step definitions.** Step code reaching into database or HTTP
  internals instead of going through the public API the user would touch.
  The scenario then tests the implementation, not the behavior.
