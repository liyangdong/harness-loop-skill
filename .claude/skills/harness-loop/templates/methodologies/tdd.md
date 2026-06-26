## 工作循环: TDD (Test-Driven Development)

Red-Green-Refactor. Write a failing test that pins down one behavior, write the
minimum code that makes it pass, then clean up. The test always goes first;
implementation exists to satisfy tests, never the other way around.

### Workflow

1. Pick one unit of behavior from `TASKS.md` or the current spec. Write its
   name as a new test function in `tests/` before any production code exists.
2. Run `bash scripts/check-tests.sh` and watch the new test fail with the
   expected assertion error. If it fails for a different reason (import error,
   syntax error), fix the test setup — the failure must be a behavior failure.
3. Write the minimum implementation in `src/` (or your project's source dir)
   that turns the new test green. Do not add behavior the test does not yet
   demand.
4. Run `bash scripts/check-tests.sh` again. All tests, including the new one,
   must pass. If anything else breaks, you wrote too much — back it out.
5. Refactor: rename, extract, deduplicate. Run the test suite after each
   refactor step; stop and revert if any test goes red.
6. Commit with a message that names the behavior added (e.g.
   `feat(pricing): apply regional tax in subtotal`), not the test file.
7. Update `state/iteration.md` progress field before the loop's next tick.

### Acceptance criteria

- [ ] `bash scripts/check-tests.sh` exits 0 (all tests green)
- [ ] Every code change in this iteration has at least one new or modified
      test in `tests/` covering the changed behavior
- [ ] Test-to-source line ratio did not drop compared to the previous commit
      (checkable by `check-entropy.sh` if 熵扫描 is on, else by `git diff --stat`)
- [ ] No production code was committed before its corresponding test

### Required artifacts

- `tests/` — directory holding the test suite. Scaffolding subdirectory is
  `tests-{{LANGUAGE}}/` from the generator; the project sees it as `tests/`.
- `scripts/check-tests.sh` — runs the test command for `{{LANGUAGE}}` and
  exits non-zero on any failure.

### Anti-patterns

- **Implementation first.** Writing the production code, then bolting on a
  test that passes by construction. The test did not pin behavior; it
  documented a coincidence. Always write the test first and see it fail.
- **Skipping the "see it fail" step.** If you run the suite only after
  writing implementation, you cannot tell whether the test would have caught
  the absence of the behavior. A test that passes against missing code is a
  no-op test.
- **Big-bang tests.** One test asserting ten behaviors at once. When it fails
  you cannot tell which behavior broke. One behavior per test function.
- **Refactor without re-running.** Changing names or extracting functions
  without re-running the suite between edits. A red test caught three steps
  later is much harder to localize than one caught immediately.
