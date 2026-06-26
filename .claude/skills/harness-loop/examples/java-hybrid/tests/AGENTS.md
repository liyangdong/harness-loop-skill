# AGENTS.md — tests-java/ (generated `tests/` when language = Java)

> Conventions for the Java/Maven/JUnit5 test tree the wizard writes into a
> user project when Q3 (language) = Java. Rendered from
> `templates/scaffolding/methodology-dirs/tests-java/`. Target path in the
> generated repo: `tests/` (or project root, depending on Q4 layout — see
> wizard/decision-tree.md).

## 1. Layout — Maven Standard Directory Layout

- `src/main/java/` — production code (one class per file, package matches dir).
- `src/test/java/` — test code, mirrors `src/main/java/` package-for-package.
- `pom.xml` at the root of this module.
- Resources (if any): `src/main/resources/`, `src/test/resources/`.

Do not invent non-standard dirs (`src/`, `lib/`, `test/`). Maven + surefire
hard-code the standard layout; deviating silently breaks `mvn test`.

## 2. Test class naming

- Every test class ends with the suffix `Test`. Example: `CalculatorTest.java`.
- One test class per production class: `Calculator` ↔ `CalculatorTest`.
- Test classes are package-private (`class`, not `public class`) — JUnit 5
  does not require `public`, and keeping them package-private reduces surface.

## 3. Test methods

- Annotate with `@Test` (from `org.junit.jupiter.api.Test`).
- Add `@DisplayName("…")` with a one-line statement of intent (the *behavior*,
  not the implementation). Reviewers read the display name first.
- Method name: the behavior under test in `lowerCamelCase`, e.g.
  `returnsZeroForEmptyInput()`. Do not prefix with `test` — the `@Test`
  annotation already says so.
- One logical assertion per test. If you need `assertAll`, group related
  invariants of the *same* behavior, not multiple behaviors.

## 4. Assertions — JUnit 5 only

- Use `org.junit.jupiter.api.Assertions.*`:
  - `assertEquals(expected, actual, message)` — always pass a message.
  - `assertThrows(ExpectedException.class, () -> { … })` for error paths.
  - `assertTrue` / `assertFalse` only when no stronger assertion exists.
- Do NOT mix Hamcrest `assertThat` or JUnit 4 `org.junit.Assert.*` — pick one
  (JUnit 5 assertions) for the whole module.

## 5. Collaborators — Mockito

- Mock external collaborators (HTTP clients, DB, clock, file system) with
  `Mockito.mock(Type.class)` or the `@Mock` + `MockitoExtension` annotation.
- Stub with `when(collaborator.call(arg)).thenReturn(value)` — prefer
  `eq(...)`, `any()`, `argThat(...)` matchers over literal args when behavior
  is input-dependent.
- Verify interactions sparingly: only when the *interaction itself* (not the
  return value) is the contract. State-based assertions are preferred.
- Mockito version is pinned in `pom.xml` (`${mockito.version}`).

## 6. Running tests

- One command: `mvn -q test`. The `-q` keeps output to failures only.
- A single test class: `mvn -q test -Dtest=CalculatorTest`.
- A single method: `mvn -q test -Dtest=CalculatorTest#returnsZeroForEmptyInput`.

`mvn test` compiles `src/main/java/` and `src/test/java/`, runs surefire on
all `*Test` classes, and fails the build on the first error.

## 7. Coverage threshold — ≥80% line coverage

- Target: **≥80% line coverage** on production code (`src/main/java/`).
- Enforced when JaCoCo is configured in `pom.xml` (see template — currently
  advisory; add `<jacoco-maven-plugin>` with a `check` goal to enforce).
- Run locally: `mvn -q test jacoco:report` then open
  `target/site/jacoco/index.html`.
- CI: emit `target/site/jacoco/jacoco.xml` for tooling (Codecov, etc.).
- 80% is a floor, not a ceiling. Tests must exercise the *important* paths,
  not chase a number — but anything below 80% is a flag for review.

## 8. What lives here vs. elsewhere

- Production code under `src/main/java/` belongs to whatever methodology the
  project picked (TDD, SDD, DDD, etc.). This `tests/` (rendered from
  `tests-java/`) covers test-side conventions only.
- Integration tests (anything touching a real DB, HTTP, or >1s wall time)
  go in a separate module or in `src/test/java/` with `@Tag("integration")`
  and a surefire `<excludedGroups>integration</excludedGroups>` default.
