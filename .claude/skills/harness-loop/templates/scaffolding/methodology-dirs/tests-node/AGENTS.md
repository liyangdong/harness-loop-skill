# AGENTS.md — tests-node/ (generated `tests/` when language = Node/TypeScript)

> Conventions for the Node/TypeScript/vitest test tree the wizard writes into
> a user project when Q3 (language) = Node. Rendered from
> `templates/scaffolding/methodology-dirs/tests-node/`. Target path in the
> generated repo: `tests/` at the project root.

## 1. Layout

- `tests/` directory at the project root.
- Test files named `*.test.ts` (or `*.test.js` for plain JS projects).
  Example: `calculator.test.ts`.
- Production code lives under `src/` — not in `tests/`.
- A `vitest.config.ts` at the project root pins test environment, coverage
  thresholds, and include/exclude globs.

Do not invent non-standard dirs (`__tests__/`, `spec/`). vitest discovers
tests by the `*.test.*` filename convention; deviating silently skips tests.

## 2. Test structure — describe / it

- Wrap related tests in `describe("UnitName", () => { … })`.
- Each test is an `it("should <behavior>", () => { … })` or `test(...)`.
- Describe the behavior under test, not the implementation:
  `it("should return zero for empty input")`.

## 3. Assertions — expect

- Use `expect(actual).toBe(expected)` for primitives (strict equality).
- Use `toEqual(expected)` for deep object equality.
- Use `toThrow(ErrorClass)` / `toThrow(/message/)` for error paths.
- Pick one assertion style (vitest's `expect`) for the whole module — do not
  mix `assert`/`should` libraries.

## 4. Mocks — vi.fn / vi.mock

- Stub a function with `const fn = vi.fn(); fn.mockReturnValue(value)` or
  `fn.mockResolvedValue(value)` for async.
- Mock a whole module with `vi.mock("../src/client", () => ({…}))` at the top
  of the test file (hoisted).
- Mock external collaborators (HTTP, DB, filesystem, clock). Do not mock the
  unit under test itself.
- Reset between tests with `afterEach(() => vi.restoreAllMocks())`.

## 5. Fixtures — before / after

- Use `beforeEach`/`afterEach` for per-test setup/teardown.
- Use `beforeAll`/`afterAll` for module-scoped setup that is expensive to build.
- Prefer small factory functions over large fixture files.

## 6. Running tests

- One command: `vitest run` (or `npm test`).
- Watch mode (development): `vitest` (no `run`).
- A single file: `vitest run tests/calculator.test.ts`.
- A single test by name: `vitest run -t "should return zero"`.

## 7. Coverage threshold — ≥80% line coverage

- Target: **≥80% line coverage** on production code under `src/`.
- Enforced via `vitest run --coverage` with `coverage.thresholds.lines = 80`
  in `vitest.config.ts`.
- Run locally: `vitest run --coverage`. HTML report at `coverage/index.html`.
- CI: emit `coverage/lcov.info` (lcov reporter) for tooling (Codecov, etc.).
- 80% is a floor, not a ceiling. Tests must exercise the *important* paths,
  not chase a number — but anything below 80% is a flag for review.

## 8. What lives here vs. elsewhere

- Production code under `src/` belongs to whatever methodology the project
  picked (TDD, SDD, DDD, etc.). This `tests/` (rendered from `tests-node/`)
  covers test-side conventions only.
- Integration tests (real DB, HTTP, >1s wall time) live under `tests/` with
  a `.integration.test.ts` suffix and are excluded from the default vitest
  include glob, run separately in CI.
