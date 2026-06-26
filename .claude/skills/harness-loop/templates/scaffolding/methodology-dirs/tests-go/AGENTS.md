# AGENTS.md — tests-go/ (generated `*_test.go` files when language = Go)

> Conventions for the Go test tree the wizard writes into a user project when
> Q3 (language) = Go. Rendered from
> `templates/scaffolding/methodology-dirs/tests-go/`. Target path in the
> generated repo: alongside the source files (`*_test.go`), not in a separate
> directory.

## 1. Layout — test files live next to source

- Test files are named `*_test.go` and live **in the same package** as the
  source they test. Example: `src/calculator/calculator.go` ↔
  `src/calculator/calculator_test.go`.
- Go does not use a separate `tests/` directory. The `go test ./...` command
  discovers `*_test.go` files anywhere under the module root.
- A package can contain multiple `*_test.go` files; group tests by the source
  file they cover.

Do not invent `tests/` or `__tests__/` dirs. Go's tooling treats any
`*_test.go` file anywhere as a test file; an extra `tests/` dir confuses
imports and package layout.

## 2. Test functions

- Test functions are named `Test<Subject>` (exported) and take
  `*testing.T` as the only parameter: `func TestCalculator(t *testing.T) {…}`.
- Test functions live in the same package as the code under test (white-box).
  Use an external test package (`package foo_test`) only when black-box
  testing against the public API is required.

## 3. Table-driven tests with t.Run

- Prefer table-driven tests for any function with >2 input cases:
  ```go
  func TestAdd(t *testing.T) {
      cases := []struct{ name string; a, b, want int }{
          {"both positive", 1, 2, 3},
          {"zero identity", 0, 5, 5},
      }
      for _, tc := range cases {
          t.Run(tc.name, func(t *testing.T) {
              if got := Add(tc.a, tc.b); got != tc.want {
                  t.Errorf("Add(%d, %d) = %d, want %d", tc.a, tc.b, got, tc.want)
              }
          })
      }
  }
  ```
- Each `t.Run` subtest is named and reported independently.

## 4. Assertions — t.Errorf / t.Fatalf

- Use `t.Errorf("…", args)` for a failure that does **not** abort the test
  (multiple `Errorf`s accumulate).
- Use `t.Fatalf("…", args)` for a failure that **must** abort the test
  (e.g. setup failed, nothing else can run).
- Do **not** use `panic` for test failures — `t.Fatal*` is the idiomatic way.
- Avoid assertion libraries (`testify`) unless the project already uses them;
  prefer stdlib `t.Errorf` / `t.Fatalf` for portability.

## 5. Mocks

- Go favours interfaces over mocks: define a small interface and pass a fake
  implementation in tests.
- For generated stubs, use `mockgen` (gomock) or `counterfeiter` when the
  interface has many methods.
- Mock external collaborators (HTTP, DB, filesystem, clock); never mock the
  unit under test itself.

## 6. Benchmarks

- Benchmark functions are named `Benchmark<Subject>` and take `*testing.B`.
  Run with `go test -bench=. ./...`.

## 7. Running tests

- All tests: `go test ./...`. Single package: `go test ./src/calculator`.
- Single test: `go test ./src/calculator -run TestAdd`.
- Verbose: `go test ./... -v`. Stop on first failure: `go test ./... -failfast`.

## 8. Coverage threshold — ≥80% line coverage

- Target: **≥80% line coverage** on production code.
- Enforced via `go test -cover -coverprofile=coverage.out ./...` with a CI
  gate parsing `go tool cover -func` for the total line.
- HTML report: `go tool cover -html=coverage.out`. Local quick view:
  `go test -cover ./...` (per-package summary).
- 80% is a floor, not a ceiling. Tests must exercise the *important* paths,
  not chase a number — but anything below 80% is a flag for review.

## 9. What lives here vs. elsewhere

- Production code under the package dirs belongs to whatever methodology the
  project picked (TDD, SDD, DDD, etc.). The `*_test.go` files (rendered from
  `tests-go/`) cover test-side conventions only.
- Integration tests (real DB, HTTP, >1s wall time) live alongside source as
  `*_integration_test.go` with build tag `//go:build integration` so
  `go test ./...` skips them by default.
