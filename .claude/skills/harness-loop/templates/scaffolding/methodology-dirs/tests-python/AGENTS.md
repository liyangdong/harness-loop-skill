# AGENTS.md — tests-python/ (generated `tests/` when language = Python)

> Conventions for the Python/pytest test tree the wizard writes into a user
> project when Q3 (language) = Python. Rendered from
> `templates/scaffolding/methodology-dirs/tests-python/`. Target path in the
> generated repo: `tests/` at the project root.

## 1. Layout

- `tests/` directory at the project root.
- Test files named `test_*.py` (e.g. `test_calculator.py`).
- Production code lives under `src/` or the package root — not in `tests/`.
- One `conftest.py` at the project root for shared fixtures; nested
  `conftest.py` files for directory-scoped fixtures.

Do not invent non-standard dirs (`test/`, `__tests__/`). `pytest` discovers
tests by the `test_*.py` filename convention; deviating silently skips tests.

## 2. Test naming

- Test functions (not classes) are the default: `def test_<behavior>():`.
- Test classes are allowed only when grouping related tests of one unit:
  `class TestCalculator:` (no `unittest.TestCase` subclassing).
- Function names describe the behavior under test, e.g.
  `test_returns_zero_for_empty_input()`. Do not abbreviate.

## 3. Fixtures — pytest fixtures

- Use `@pytest.fixture` for setup, not module-level globals.
- Scope fixtures (`scope="module"`, `scope="session"`) when expensive to build.
- Yield teardowns inside the fixture: `yield resource; resource.close()`.
- Inject collaborators via fixture parameters, not via imports of globals.

## 4. Data-driven tests

- Use `@pytest.mark.parametrize("name,input,expected", [...])` for table-style
  data-driven tests. Prefer this over `for` loops inside a test body — each
  parametrize row appears as its own test result.

## 5. Collaborators — mocks

- Use `unittest.mock` (stdlib): `Mock()`, `MagicMock()`, `patch(...)`.
- Prefer `pytest-mock`'s `mocker` fixture for scoping patches automatically:
  `mocker.patch("module.ClassName.method", return_value=...)`.
- Mock external collaborators (HTTP, DB, filesystem, clock). Do not mock the
  unit under test itself.

## 6. Assertions

- Use plain `assert` statements — pytest rewrites assertions for rich output.
- Avoid `unittest.TestCase.assertEquals` / `self.assert*` — pick pytest
  assertion style for the whole module.

## 7. Running tests

- One command: `pytest tests/`. Discovers all `test_*.py` under `tests/`.
- A single file: `pytest tests/test_calculator.py`.
- A single test: `pytest tests/test_calculator.py::test_returns_zero_for_empty_input`.
- Verbose: `pytest tests/ -v`. Stop on first failure: `pytest tests/ -x`.

## 8. Coverage threshold — ≥80% line coverage

- Target: **≥80% line coverage** on production code.
- Enforced via `pytest --cov=src --cov-fail-under=80` (requires `pytest-cov`).
- Run locally: `pytest tests/ --cov=src --cov-report=term-missing`.
- HTML report: `pytest tests/ --cov=src --cov-report=html` then open
  `htmlcov/index.html`.
- 80% is a floor, not a ceiling. Tests must exercise the *important* paths,
  not chase a number — but anything below 80% is a flag for review.

## 9. What lives here vs. elsewhere

- Production code under `src/` belongs to whatever methodology the project
  picked (TDD, SDD, DDD, etc.). This `tests/` (rendered from `tests-python/`)
  covers test-side conventions only.
- Integration tests (real DB, HTTP, >1s wall time) live under `tests/` with
  a `@pytest.mark.integration` marker and are skipped by default via
  `pytest -m "not integration"` in CI.
