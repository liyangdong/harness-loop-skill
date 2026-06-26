# Decision Tree: answers → templates

> Map from each wizard answer (Q1-Q8) to the concrete template files rendered, the
> placeholders substituted, and the output paths written into the user's project.
> Keep this file in sync with `questions.md` — any option added/removed there MUST
> be reflected here in the same commit (per `wizard/AGENTS.md` §4).
>
> All `templates/...` paths are relative to `.claude/skills/harness-loop/`. All
> "output path" entries are relative to the user's project root.

---

## Q1 (project_type) → AGENTS.md mission + default check set

Picks the mission one-liner (1-3 lines, per spec §5.2) injected into the root
`AGENTS.md`'s top section, and the default `Q4` selection if the user accepts
the recommended defaults. The user can still override Q4 in the wizard.

The mission text is **inlined directly in this table** (not a separate template
file) because it is short and project-type-specific — keeping it here means one
fewer template directory to maintain.

| Q1 answer | Mission text (injected as `{{MISSION_ONE_LINER}}`) | Default Q4 selections |
|---|---|---|
| 应用代码项目 | `本仓库是一个应用代码项目。所有变更必须通过测试、lint 和类型检查后方可合入。` | 完成信号, 外部验证, 检查点 |
| 库 / SDK 项目 | `本仓库是一个对外暴露 API 的库 / SDK。公共契约（API 签名、语义化版本）不可被无声破坏。` | 完成信号, 检查点, 熵扫描 |
| 文档 / 学习档案项目 | `本仓库以内容产出为主（文档 / 翻译 / 学习档案）。机械检查聚焦一致性、完成度和熵积累。` | 完成信号, 检查点, 熵扫描 (skip 外部验证) |
| 混合型 | `本仓库是应用代码 + 文档的混合项目。代码子目录遵循测试门控，文档子目录遵循一致性门控，分层配置。` | 完成信号, 外部验证, 检查点, 熵扫描 |

Notes:
- C1 (consistency) and C2 (reference alignment) are always generated as part of
  `check-consistency.sh`; Q1 only tunes the *default* Q4 set, not whether C1/C2 run.
- If the user provides a custom mission line during the wizard (free-text
  override), that string takes precedence over the table above.

---

## Q2 (methodology) → methodology templates + scaffolding

| Q2 answer | Methodology block (injected as `{{METHODOLOGY_BLOCK}}`) | Subdir scaffolding copied to project |
|---|---|---|
| TDD | `templates/methodologies/tdd.md` | `templates/scaffolding/methodology-dirs/tests-{{Q3}}/` → `<project>/tests/` |
| SDD | `templates/methodologies/sdd.md` | `templates/scaffolding/methodology-dirs/specs/` → `<project>/docs/specs/` |
| BDD | `templates/methodologies/bdd.md` | `templates/scaffolding/methodology-dirs/features/` → `<project>/features/` |
| DDD | `templates/methodologies/ddd.md` | `templates/scaffolding/methodology-dirs/domain/` → `<project>/docs/domain/` |
| RDD | `templates/methodologies/rdd.md` | `templates/scaffolding/methodology-dirs/readme-first/` → `<project>/docs/readme-first.md` |
| Plain | `templates/methodologies/plain.md` | (none — no methodology-specific directory) |
| Hybrid | (multiple — see §Hybrid rules below) | (multiple — each selected methodology's directory) |

### Hybrid rules (Q2 = Hybrid)

When Q2 = Hybrid, ask a follow-up multi-select (per `questions.md` Q2 branch
note and spec §5.3.1). For each selected methodology `M`:

1. **Directory coexistence**: copy `M`'s scaffolding directory into the project.
   E.g., SDD + TDD produces both `docs/specs/` and `tests/`.
2. **AGENTS.md section order**: in the root AGENTS.md `## 工作循环` section,
   inject methodology blocks in this priority order (highest first):
   `SDD > TDD > BDD > DDD > RDD`. Rationale: spec-first (what to build) precedes
   impl-first (how to build).
3. **Conflict resolution**: when two methodologies' rules conflict, the
   higher-priority one wins; lower-priority blocks add a "see also" pointer to
   the higher-priority block.
4. **Cross-reference**: the root AGENTS.md explicitly declares the composition,
   e.g. `"SDD 产出 spec 后，TDD 接管实现"` is added to the methodology section.
5. **Plain cannot combine**: Plain is mutually exclusive with the others; if
   the user picks Plain in Hybrid, treat it as a single-methodology Plain choice.

The `{{METHODOLOGY_BLOCK}}` placeholder receives the concatenation of the
selected methodology `.md` fragments, in priority order, separated by `---`.

---

## Q3 (language) → check-tests.sh command block

The selected language drives the `case` branch inside `check-tests.sh.tmpl`
and the test scaffolding subdirectory under `tests-<lang>/`. The placeholder
`{{LANGUAGE}}` is substituted into `check-tests.sh.tmpl`, `check-entropy.sh.tmpl`,
and `gitignore.tmpl` (for language-specific ignores).

| Q3 answer | `{{LANGUAGE}}` value | check-tests.sh body (per-language commands) | Scaffolding dir |
|---|---|---|---|
| Python | `Python` | `pytest tests/` && `ruff check .` && `mypy src/` | `tests-python/` |
| Node.js / TypeScript | `Node` | `vitest run` && `eslint .` && `tsc --noEmit` | `tests-node/` |
| Go | `Go` | `go test ./...` && `golangci-lint run` && `test -z "$(gofmt -l .)"` | `tests-go/` |
| Java | `Java` | `mvn -q test` && `mvn -q checkstyle:check` && `mvn -q compile` | `tests-java/` |
| 多语言 | `Multi` | (per-subdirectory: detect dominant language per top-level dir, run appropriate) | (multiple `tests-<lang>/` dirs) |
| 非代码项目 | `Non-code` | (script prints `"✅ C3 skipped: non-code project"` and exits 0 immediately) | (none — no `tests/` directory generated) |

Notes:
- `Multi` mode is a fallback; the generated `check-tests.sh` includes a
  per-subdirectory dispatch loop. Documented as best-effort; users typically
  refactor to per-language subdir AGENTS.md files later.
- `Non-code` mode still generates `check-tests.sh` (so the script exists and is
  callable from `pre-commit`), but it always succeeds.
- Rust / Kotlin / Scala / C# / Ruby are NOT yet supported (spec §9). If the
  user picks `Other` for a custom language, the wizard asks for an explicit
  test command and writes it directly into `check-tests.sh.tmpl`'s `*` case.

### Language → gitignore fragment

`gitignore.tmpl` includes `{{LANGUAGE_SPECIFIC_IGNORES}}`:

| Language | Appended lines |
|---|---|
| Python | `__pycache__/`<br>`*.pyc`<br>`.venv/` |
| Node | `node_modules/`<br>`dist/`<br>`*.log` |
| Go | (none) |
| Java | `target/`<br>`*.class`<br>`.mvn/wrapper/maven-wrapper.jar` |
| Multi / Non-code | (none) |

---

## Q4 (verification mechanisms) → check scripts generated

Q4 is multiSelect; each selected option produces one or more files. The files
are always written into the user's `<project>/scripts/`, `<project>/.githooks/`,
or `<project>/.github/workflows/`.

| Q4 selected | Output file(s) in project | Template source |
|---|---|---|
| 完成信号 | `scripts/check-promise.sh` | `templates/checks/check-promise.sh.tmpl` |
| 外部验证 | `scripts/check-tests.sh` (always generated, even for Non-code Q3 — exits 0 in that case) | `templates/checks/check-tests.sh.tmpl` |
| 检查点 | `scripts/check-consistency.sh` + `.githooks/pre-commit` + `.github/workflows/consistency.yml` | `templates/checks/check-consistency.sh.tmpl`, `templates/checks/pre-commit.tmpl`, `templates/checks/consistency.yml.tmpl` |
| 熵扫描 | `scripts/check-entropy.sh` + `state/entropy-log.md` | `templates/checks/check-entropy.sh.tmpl`, `templates/scaffolding/state-entropy.tmpl` |
| 卡死检测 | `scripts/check-stuck.sh` (triggers Q5) | `templates/checks/check-stuck.sh.tmpl` |

Notes:
- The `pre-commit` hook calls *every* `check-*.sh` that exists in `scripts/`,
  regardless of Q4 selection (so adding a check later just works). Q4 only
  drives *which scripts are written initially*.
- The `consistency.yml` GitHub Actions workflow mirrors `pre-commit` and runs
  on push/PR for controlled paths.
- If `卡死检测` is NOT selected, Q5 is skipped entirely and `check-stuck.sh`
  is NOT generated.

---

## Q5 (stuck threshold) → `{{STUCK_THRESHOLD}}` substitution

Only asked if Q4 includes `卡死检测`. Otherwise the default value `3` is used
informationally and `check-stuck.sh` is not generated at all.

| Q5 answer | `{{STUCK_THRESHOLD}}` value |
|---|---|
| 2 轮 | `2` |
| 3 轮 (default) | `3` |
| 5 轮 | `5` |
| Other (custom) | (user-provided integer, parsed and validated ≥ 1) |

Substitutes into:
- `templates/checks/check-stuck.sh.tmpl` (the comparison threshold)
- `templates/scaffolding/opencode-config.json.tmpl` (`loop.stuck_threshold`)

If Q4 does NOT include `卡死检测`:
- Q5 is not asked
- `{{STUCK_THRESHOLD}}` is set to `3` (default) but only used in
  `opencode-config.json.tmpl` for documentation purposes; `check-stuck.sh` is
  not generated.

---

## Q6 (model ID) → `{{MODEL_ID}}` substitution

Free-text input; written verbatim into the project's `.opencode/config.json`.

| Q6 answer | `{{MODEL_ID}}` value |
|---|---|
| claude-sonnet-4-6 (default) | `claude-sonnet-4-6` |
| claude-opus-4-7 | `claude-opus-4-7` |
| claude-haiku-4-5 | `claude-haiku-4-5` |
| Other (custom) | (user-provided string, written verbatim — no validation) |

Substitutes into:
- `templates/scaffolding/opencode-config.json.tmpl` (top-level `model` field)

No further branching.

---

## Q7 (learning archive) → concepts/ scaffolding

| Q7 answer | Action |
|---|---|
| 生成 | Copy every file in `templates/concepts/` (except `AGENTS.md`) into `<project>/concepts/`. Resulting files: `concepts/01-repo-as-truth.md` through `concepts/06-entropy-gc.md`. The project becomes a learnable archive itself. |
| 不生成 | Skip — do not create `<project>/concepts/`. Only generate engineering files (AGENTS.md, scripts/, state/, etc.). |

Note: the 6 concept files are ALSO always concatenated into the root AGENTS.md's
`{{CONCEPTS_BLOCK}}` section, regardless of Q7. Q7 only controls whether they're
*also* exported as standalone files for other agents to learn from.

---

## Q8 (strict mode) → `{{STRICT_MODE}}` substitution

| Q8 answer | `{{STRICT_MODE}}` value | Behavior in generated check scripts |
|---|---|---|
| strict (default) | `strict` | `set -e` semantics on failures; exit 1 on any check failure; `pre-commit` blocks the commit; `consistency.yml` fails the PR check |
| advisory | `advisory` | Failures print `⚠️` warning to stderr; exit 0 always; `pre-commit` allows commit; `consistency.yml` posts a comment but does not block |

Substitutes into:
- Every `templates/checks/check-*.sh.tmpl`
- `templates/checks/pre-commit.tmpl`
- `templates/scaffolding/readme-section.tmpl` (the "Strict mode" line)
- Root `AGENTS.md` `## 严格度` section (via `agents-root.md.tmpl`)

For the full strict-vs-advisory semantics, see `templates/strict-mode.md`.

---

## Substitution map (placeholder → source)

Single source of truth for every `{{PLACEHOLDER}}` used across the template
library. If a placeholder appears in a `.tmpl` file, it MUST be listed here.

| Placeholder | Source | Substituted into (template files) |
|---|---|---|
| `{{PROJECT_NAME}}` | User input (asked inline after Q8 if not provided) or `basename $(git rev-parse --show-toplevel)` fallback | `agents-root.md.tmpl`, `tasks-md.tmpl`, README snippet |
| `{{MISSION_ONE_LINER}}` | From Q1: contents of the selected mission fragment file | `agents-root.md.tmpl` |
| `{{CONCEPTS_BLOCK}}` | Concatenation of `templates/concepts/01-06*.md` (always all 6, regardless of Q7) | `agents-root.md.tmpl` |
| `{{RALPH_TENETS_BLOCK}}` | Contents of `templates/ralph-tenets.md` | `agents-root.md.tmpl` |
| `{{METHODOLOGY_BLOCK}}` | From Q2: contents of the selected methodology file(s); for Hybrid, concatenated in priority order SDD > TDD > BDD > DDD > RDD | `agents-root.md.tmpl` |
| `{{SUBDIR_INDEX}}` | Generated from Q2/Q3/Q7 selections (list of generated subdirectories with one-line purposes) | `agents-root.md.tmpl` |
| `{{CHECKS_INDEX}}` | Generated from Q4 selections (list of generated check scripts with one-line purposes) | `agents-root.md.tmpl` |
| `{{TASKS_POINTER}}` | Constant: `"见 TASKS.md。每轮迭代更新 state/iteration.md。"` | `agents-root.md.tmpl` |
| `{{STRICT_MODE_DECL}}` | Same value as `{{STRICT_MODE}}` (kept as a separate token so the declaration section can be reworded without touching scripts) | `agents-root.md.tmpl` (the `## 严格度` section) |
| `{{STRICT_MODE}}` | Q8 | All `check-*.sh.tmpl`, `pre-commit.tmpl`, `readme-section.tmpl` |
| `{{LANGUAGE}}` | Q3 | `check-tests.sh.tmpl`, `check-entropy.sh.tmpl`, `gitignore.tmpl` |
| `{{LANGUAGE_SPECIFIC_IGNORES}}` | Derived from Q3 (see Q3 table above) | `gitignore.tmpl` |
| `{{MODEL_ID}}` | Q6 | `opencode-config.json.tmpl` |
| `{{MAX_ITERATIONS}}` | Constant default `30` (overridable via env var `HARNESS_LOOP_MAX_ITERATIONS` at generation time) | `opencode-config.json.tmpl`, `state-iteration.tmpl` |
| `{{PROMISE_TOKEN}}` | Constant `"DONE"` (overridable via env var `HARNESS_LOOP_PROMISE_TOKEN` at generation time) | `check-promise.sh.tmpl`, `opencode-config.json.tmpl` |
| `{{STUCK_THRESHOLD}}` | Q5 (or default `3` if Q5 skipped) | `check-stuck.sh.tmpl`, `opencode-config.json.tmpl` |
| `{{SOURCE_EXT}}` | Derived from Q3: Python→`py`, Node→`ts`, Go→`go`, Java→`java`, others→`*` | `check-entropy.sh.tmpl` (controls which file extensions are scanned) |
| `{{TODO_THRESHOLD}}` | Constant default `20` (overridable via env var `HARNESS_LOOP_TODO_THRESHOLD`) | `check-entropy.sh.tmpl` |
| `{{TIMESTAMP}}` | `date -Iseconds` at generation time | `state-iteration.tmpl` |
| `{{PROGRESS_SIG}}` | Constant `"initial"` for first generation; updated by the loop on each iteration | `state-iteration.tmpl` |
| `{{LAST_ACTION}}` | Constant `"loop bootstrap"` for first generation | `state-iteration.tmpl` |
| `{{CURRENT_EPIC_DESCRIPTION}}` | User input (asked inline after Q8 if not provided); fallback: `"(fill in current epic)"` | `tasks-md.tmpl` |
| `{{SUBTASK_N}}` | User input (asked inline after Q8 if not provided); fallback: `"- [ ] (define subtask N)"` for N=1..3 | `tasks-md.tmpl` |
| `{{SUBDIR_PATH}}` / `{{SUBDIR_PURPOSE}}` / `{{SUBDIR_CONVENTIONS}}` / `{{SUBDIR_RELATED_CHECKS}}` | Per-subdirectory values derived from Q2/Q3 | `agents-subdir.md.tmpl` (one render per generated subdir) |
| `{{GROUP_ID}}` / `{{ARTIFACT_ID}}` / `{{VERSION}}` / `{{PACKAGE}}` / `{{CHECKSTYLE_FAILS_ON_ERROR}}` | Java-specific constants: `GROUP_ID=com.example`, `ARTIFACT_ID={{PROJECT_NAME}}`, `VERSION=0.1.0-SNAPSHOT`, `PACKAGE=com.example.{{lowercase PROJECT_NAME}}`, `CHECKSTYLE_FAILS_ON_ERROR=true` (advisory mode → `false`) | `tests-java/pom.xml.tmpl`, `tests-java/src/test/java/FirstTest.java.tmpl` |
| `{{FEATURE_NAME}}` | User input (asked inline when SDD is selected): the human-readable name of the feature the spec describes, e.g., "User Authentication". Falls back to the spec filename's slug title-cased if the user does not provide one. | `specs/template.md` (the H1 of the generated spec) |

### Substitution semantics

- All substitutions are plain string replacement (no Mustache logic, no
  conditionals). Templates that need branching on Q-state must use multiple
  files (e.g., separate `tests-<lang>/` directories) rather than `{{#if}}`.
- The renderer is a single `sed` pass per placeholder; substitution order does
  not matter because no placeholder's expansion contains another placeholder.
- Placeholders not in this table are a bug — either remove them from the
  template or add them here.

---

## Output path computation

Given an answer set (Q1-Q8), the set of files written into the user's project
is computed as follows. `summary-format.md` enumerates exactly this set before
the user confirms.

**Always written (regardless of answers):**
- `AGENTS.md` (rendered from `agents-root.md.tmpl`)
- `TASKS.md` (from `tasks-md.tmpl`)
- `state/iteration.md` (from `state-iteration.tmpl`)
- `.opencode/config.json` (from `opencode-config.json.tmpl`)
- `README.md` (snippet appended from `readme-section.tmpl`)
- `.gitignore` (lines appended from `gitignore.tmpl`)

**Conditionally written (per answers):**
- Per Q2 methodology → that methodology's scaffolding directory (see Q2 table)
- Per Q4 selected → corresponding `scripts/check-*.sh` (and hooks/CI if 检查点)
- Per Q3 ≠ Non-code → `tests-{{Q3}}/` scaffolding (only if Q2 ∈ {TDD, Hybrid with TDD})
- Per Q5 (only if Q4 includes 卡死检测) → `scripts/check-stuck.sh`
- Per Q7 = 生成 → `concepts/01-06*.md` (6 files)
- Per Q4 includes 熵扫描 → `state/entropy-log.md`

**Backup rule (spec §5.6):** if any output path already exists in the project
on first generation, the existing file is renamed to `<path>.bak` before the
new file is written. On re-runs (idempotency mode), `AGENTS.md`, `scripts/*.sh`,
and `.opencode/config.json` are overwritten; `TASKS.md`, `state/iteration.md`,
README user-sections, and `.gitignore` user-lines are preserved.
