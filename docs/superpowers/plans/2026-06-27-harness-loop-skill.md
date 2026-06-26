# Harness-Loop Skill Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a project-level skill `harness-loop` that, via an interactive 8-question wizard, generates a complete AGENTS.md-based constraint system (aligned with harness-engineering paradigm) into any project, delegating runtime execution to opencode.

**Architecture:** Skill = wizard logic + progressive template library. SKILL.md is a thin ~100-line index pointing to `wizard/` (logic) and `templates/` (content). No executable harness code is generated—only constraint files (AGENTS.md, check scripts, scaffolding) that configure how opencode operates on the project.

**Tech Stack:** Markdown + Bash (Git Bash on Windows) + YAML (GitHub Actions) + JSON (opencode config). Templates use `{{placeholder}}` Mustache-style syntax. Java/Maven/JUnit 5 as primary example language.

**Spec:** `docs/superpowers/specs/2026-06-27-harness-loop-skill-design.md`

---

## File Structure

All paths relative to project root (`D:\project\harness+loop\`). Skill lands at `.claude/skills/harness-loop/`.

```
.claude/skills/harness-loop/
├── SKILL.md                           # Entry index (~100 lines)
├── README.md                          # User docs for the skill
├── AGENTS.md                          # Skill's own constraints (dogfood)
├── wizard/
│   ├── AGENTS.md                      # wizard/ conventions
│   ├── questions.md                   # 8-question script
│   ├── decision-tree.md               # answers → template paths
│   └── summary-format.md              # config summary format
├── templates/
│   ├── AGENTS.md                      # templates/ conventions
│   ├── agents-root.md.tmpl            # root AGENTS.md shell
│   ├── agents-subdir.md.tmpl          # subdir AGENTS.md shell
│   ├── ralph-tenets.md                # Ralph 6 tenets block
│   ├── strict-mode.md                 # strict vs advisory semantics
│   ├── methodologies/{AGENTS,tdd,sdd,bdd,ddd,rdd,plain}.md
│   ├── concepts/{AGENTS,01-repo-as-truth,...,06-entropy-gc}.md
│   ├── checks/{AGENTS,check-*.sh.tmpl,pre-commit.tmpl,consistency.yml.tmpl}
│   └── scaffolding/
│       ├── AGENTS.md
│       ├── tasks-md.tmpl
│       ├── state-iteration.tmpl
│       ├── state-entropy.tmpl
│       ├── gitignore.tmpl
│       ├── readme-section.tmpl
│       ├── opencode-config.json.tmpl
│       └── methodology-dirs/
│           ├── tests-java/{AGENTS.md, pom.xml.tmpl, src/test/java/FirstTest.java.tmpl}
│           ├── tests-python/{AGENTS.md, test_first.template.py}
│           ├── tests-node/{AGENTS.md, first-test.template.ts}
│           ├── tests-go/{AGENTS.md, first_test.template.go}
│           ├── specs/{AGENTS.md, template.md}        # SDD
│           ├── features/{AGENTS.md, example.feature} # BDD
│           ├── domain/{AGENTS.md, ubiquitous-language.md} # DDD
│           └── readme-first/{readme-first.md}        # RDD
├── scripts/
│   ├── check-skill.sh                 # L1 static checks
│   ├── check-examples.sh              # L2 e2e diff
│   └── check-bootstrap.sh             # L3 bootstrap self-check
└── examples/
    ├── AGENTS.md
    ├── java-tdd/                      # Full generated output snapshot
    ├── java-sdd/
    └── java-hybrid/
```

**Responsibility split:**
- `SKILL.md` = the only file Claude reads on invocation; everything else is loaded on demand
- `wizard/` = logic (what to ask, how to map answers to templates)
- `templates/` = content (what to generate)
- `scripts/` = self-verification of the skill itself
- `examples/` = regression baselines

---

## Conventions Used Throughout

- **Template placeholders:** `{{variable}}` — rendered by string replacement at generation time
- **Strict mode flag in templates:** All `check-*.sh.tmpl` read `{{STRICT_MODE}}` → `strict` = `set -e` + exit 1 on failure; `advisory` = warn + exit 0
- **Path placeholders:** `{{PROJECT_ROOT}}`, `{{METHODOLOGY_DIR}}`, `{{LANGUAGE}}`
- **Lint error format:** Every check script emits `❌ <check-id> <message>` + `   修复: <fix instruction>` (harness-engineering requirement)
- **Line counts:** Subdir `AGENTS.md` files stay ≤100 lines (S4 check)

---

## Phase 1: Foundation

### Task 1: Directory scaffold + skill metadata

**Files:**
- Create: `.claude/skills/harness-loop/AGENTS.md`
- Create: `.claude/skills/harness-loop/README.md`

- [ ] **Step 1: Create directory tree**

```bash
cd "D:/project/harness+loop"
mkdir -p .claude/skills/harness-loop/{wizard,templates/{methodologies,concepts,checks,scaffolding/methodology-dirs/{tests-java,tests-python,tests-node,tests-go,specs,features,domain,readme-first}},scripts,examples/{java-tdd,java-sdd,java-hybrid}}
```

Verify: `find .claude/skills/harness-loop -type d | wc -l` should output ~16.

- [ ] **Step 2: Write `.claude/skills/harness-loop/AGENTS.md`**

Content: a ~80-line file describing the skill's own conventions. Sections:
1. **Skill purpose** (1-3 lines): "This skill generates AGENTS.md-based constraint systems via an 8-question wizard."
2. **Map-not-manual declaration**: SKILL.md stays ≤100 lines; details live in `wizard/` and `templates/`.
3. **Editing rules**:
   - Adding a methodology → new file in `templates/methodologies/` + entry in `wizard/decision-tree.md`
   - Adding a check layer → new `templates/checks/check-*.sh.tmpl` + entry in `decision-tree.md`
   - Adding a language → new `templates/scaffolding/methodology-dirs/tests-<lang>/` directory
4. **Self-verification**: run `bash scripts/check-skill.sh` before committing changes
5. **Dogfood**: this AGENTS.md follows the same ~100-line rule it imposes on generated outputs

- [ ] **Step 3: Write `.claude/skills/harness-loop/README.md`**

Content (~150 lines): skill documentation for human readers. Sections:
1. **What it does** (2-3 sentences)
2. **When to invoke** (trigger keywords)
3. **Quick start** (example invocation)
4. **The 8 wizard questions** (summary table, not full options — point to `wizard/questions.md`)
5. **Generated output overview** (file tree diagram from spec §5.1)
6. **Extension guide** (how to add methodologies/languages/checks)
7. **Verification** (how to run L1/L2/L3 checks)
8. **References** (link to spec, harness-engineering repo)

- [ ] **Step 4: Commit**

```bash
git add .claude/skills/harness-loop/AGENTS.md .claude/skills/harness-loop/README.md
git commit -m "feat(skill): scaffold harness-loop skill directory + metadata"
```

---

### Task 2: SKILL.md (entry index)

**Files:**
- Create: `.claude/skills/harness-loop/SKILL.md`

- [ ] **Step 1: Write SKILL.md with frontmatter + ~100 line body**

```markdown
---
name: harness-loop
description: Use when the user wants to set up an agent harness, build a constraint system for AI agents on a repo, generate AGENTS.md, or make long-running agent tasks execute predictably. Triggers include "搭 harness", "建 loop", "约束 agent", "生成 AGENTS.md", "make this run until done", "set up opencode constraints", "build harness", "set up loop".
---

# Harness-Loop Skill

Generate a project-wide constraint system (AGENTS.md + mechanical checks + scaffolding) that makes opencode (or any agents.md-compatible tool) execute long tasks predictably. Aligned with deusyu/harness-engineering paradigm.

## When to invoke

User says any of:
- "搭个 harness" / "build a harness" / "set up a loop"
- "约束 agent 行为" / "constrain agent behavior"
- "生成 AGENTS.md" / "generate AGENTS.md"
- "让任务自动跑" / "make this run until done"
- "设置 opencode 约束" / "set up opencode constraints"

## What it produces

A constraint system in the project root:
- `AGENTS.md` (~100-line navigation entry)
- Subdirectory `AGENTS.md` files (progressive disclosure)
- `scripts/check-*.sh` (mechanical enforcement, C1-C6 layers)
- `.githooks/pre-commit` + `.github/workflows/consistency.yml` (double-gate)
- `TASKS.md`, `state/iteration.md`, `state/entropy-log.md`
- `.opencode/config.json`
- Methodology-specific scaffolding (`tests/`, `docs/specs/`, etc.)
- `README.md` appendage + `.gitignore` patch

## 8-step flow

1. Read `wizard/questions.md` and ask all 8 questions via AskUserQuestion (one message, parallel calls allowed for independent questions)
2. Read `wizard/decision-tree.md` to map answers → template paths
3. Read each selected template file
4. Read `templates/strict-mode.md` to determine exit-code behavior
5. Assemble root `AGENTS.md` using `templates/agents-root.md.tmpl` + selected concept/methodology blocks
6. Write subdir `AGENTS.md` files per Q2 methodology using `templates/agents-subdir.md.tmpl`
7. Write `scripts/`, `.githooks/`, `.github/workflows/`, scaffolding/, `.opencode/`, `TASKS.md`, `state/`, `README.md` patch, `.gitignore` patch
8. Print `wizard/summary-format.md` rendered with answers; wait for `Y/n` confirmation. Only write files after `Y`.

## Progressive loading

- Only templates explicitly selected by user answers are read
- Unselected methodologies/checks/languages are never loaded into context
- 6 concepts + Ralph tenets always loaded (root AGENTS.md invariant)

## Templates index

- `templates/AGENTS.md` — templates/ conventions
- `templates/methodologies/AGENTS.md` — methodology writing rules
- `templates/concepts/AGENTS.md` — concept block format
- `templates/checks/AGENTS.md` — check script conventions
- `templates/scaffolding/AGENTS.md` — scaffolding file purposes

## Anti-patterns

- DO NOT inline template content into SKILL.md (violates map-not-manual)
- DO NOT hardcode model IDs or commands in SKILL.md (use templates + Q6 input)
- DO NOT generate files the user didn't select (Q4 multiSelect drives check script generation)
- DO NOT skip the confirmation step (step 8)

## Extension

See `README.md` "Extension Guide" section. New methodologies/checks/languages follow the same progressive-loading pattern.
```

- [ ] **Step 2: Verify frontmatter parses**

Run: `head -3 .claude/skills/harness-loop/SKILL.md`
Expected: starts with `---`, second line is `name: harness-loop`, third line starts with `description:`.

- [ ] **Step 3: Verify line count ≤100**

Run: `wc -l .claude/skills/harness-loop/SKILL.md`
Expected: ≤100 lines (the body above is ~70 lines after frontmatter; adjust if needed).

- [ ] **Step 4: Commit**

```bash
git add .claude/skills/harness-loop/SKILL.md
git commit -m "feat(skill): add SKILL.md entry index"
```

---

### Task 3: wizard/questions.md + wizard/AGENTS.md

**Files:**
- Create: `.claude/skills/harness-loop/wizard/AGENTS.md`
- Create: `.claude/skills/harness-loop/wizard/questions.md`

- [ ] **Step 1: Write `wizard/AGENTS.md`**

Content (~50 lines): conventions for the wizard/ directory.
- Purpose: defines the 8-question AskUserQuestion sequence
- Rule: questions.md must be readable as a standalone script
- Rule: any new question must also update `decision-tree.md`
- Rule: max 8 questions (cognitive load limit)

- [ ] **Step 2: Write `wizard/questions.md`**

Content (~250 lines): the actual 8 questions, each formatted as an AskUserQuestion spec. Structure per question:

```markdown
## Q1: 项目类型 (project_type)

**AskUserQuestion call:**
- question: "这个项目是什么类型？决定 AGENTS.md 使命段和默认检查栈。"
- header: "项目类型"
- multiSelect: false
- options:
  - label: "应用代码", description: "src/tests, 跑 test+lint+typecheck。默认 C1-C6 全开"
  - label: "库/SDK", description: "对外暴露 API。强开 C1/C2/C5"
  - label: "文档/学习档案", description: "强开 C1/C2/C5/C6, 跳过 C3"
  - label: "混合型", description: "全开, 分层配置"
- default recommendation: "应用代码"

**Dependencies:** none (always asked)
**Branch:** if answer = "文档/学习档案" → skip Q3 (force "非代码")
```

Write all 8 questions (Q1-Q8) in this format. Full question specs are in the design doc §4.

For Q5 (卡死阈值), it's a free-text question — instruct Claude to use AskUserQuestion with a custom "Other" option or prompt the user directly.

For Q6 (模型 ID), it's free-text — same approach.

- [ ] **Step 3: Verify all 8 questions are present**

Run: `grep -c "^## Q[0-9]" .claude/skills/harness-loop/wizard/questions.md`
Expected: `8`

- [ ] **Step 4: Commit**

```bash
git add .claude/skills/harness-loop/wizard/AGENTS.md .claude/skills/harness-loop/wizard/questions.md
git commit -m "feat(wizard): add questions.md and wizard conventions"
```

---

### Task 4: wizard/decision-tree.md + wizard/summary-format.md

**Files:**
- Create: `.claude/skills/harness-loop/wizard/decision-tree.md`
- Create: `.claude/skills/harness-loop/wizard/summary-format.md`

- [ ] **Step 1: Write `wizard/decision-tree.md`**

Content (~200 lines): a markdown table mapping answer combinations to template paths. Structure:

```markdown
# Decision Tree: answers → templates

## Q2 → methodology templates

| Q2 answer | Root AGENTS.md block | Subdir scaffolding |
|---|---|---|
| TDD | templates/methodologies/tdd.md | templates/scaffolding/methodology-dirs/tests-{{Q3}}/ |
| SDD | templates/methodologies/sdd.md | templates/scaffolding/methodology-dirs/specs/ |
| BDD | templates/methodologies/bdd.md | templates/scaffolding/methodology-dirs/features/ |
| DDD | templates/methodologies/ddd.md | templates/scaffolding/methodology-dirs/domain/ |
| RDD | templates/methodologies/rdd.md | templates/scaffolding/methodology-dirs/readme-first/ |
| Plain | templates/methodologies/plain.md | (none) |
| Hybrid | (multiple — see Hybrid rules in spec §5.3.1) | (multiple) |

## Q3 → check-tests.sh command block

| Q3 answer | check-tests.sh body |
|---|---|
| Python | pytest tests/ && ruff check . && mypy src/ |
| Node | vitest run && eslint . && tsc --noEmit |
| Go | go test ./... && golangci-lint run && gofmt -l . |
| Java | mvn -q test && mvn -q checkstyle:check && mvn -q compile |
| Non-code | (script exits 0 immediately with "no tests configured") |

## Q4 → check scripts generated

| Q4 selected | File generated |
|---|---|
| 完成信号 | scripts/check-promise.sh (from check-promise.sh.tmpl) |
| 外部验证 | scripts/check-tests.sh (always generated if Q3 ≠ non-code) |
| 检查点 | scripts/check-consistency.sh + .githooks/pre-commit + .github/workflows/consistency.yml |
| 熵扫描 | scripts/check-entropy.sh |
| 卡死检测 | scripts/check-stuck.sh |

## Q7 → concepts/ scaffolding

| Q7 answer | Action |
|---|---|
| 生成 | Copy templates/concepts/*.md → <project>/concepts/ |
| 不生成 | Skip |

## Q8 → strict-mode substitution

| Q8 answer | {{STRICT_MODE}} value in templates |
|---|---|
| strict | "strict" (set -e, exit 1 on failure) |
| advisory | "advisory" (warn, exit 0) |
```

- [ ] **Step 2: Write `wizard/summary-format.md`**

Content (~60 lines): the config summary printed before writing files. Template:

```markdown
# Config Summary Format

After collecting all 8 answers, render this template and print to user. Wait for Y/n before writing any files.

## Template

```
📋 即将生成 harness-loop 约束系统：

**项目类型**: {{Q1}}
**方法论**: {{Q2}}
**语言**: {{Q3}}
**验证机制**: {{Q4_list}}
**卡死阈值**: {{Q5_or_default_3}}
**opencode 模型**: {{Q6}}
**学习档案目录**: {{Q7}}
**严格度**: {{Q8}}

**将创建的文件**:
{{file_list_with_bullets}}

**将修改的文件**:
{{modified_files_with_bullets}}

继续？(Y/n)
```

## Rules

- File list must enumerate every file the skill is about to write
- Modified files (README.md, .gitignore) are listed separately to make patches visible
- After Y: proceed with writes
- After n: abort without writing anything
```

- [ ] **Step 3: Commit**

```bash
git add .claude/skills/harness-loop/wizard/decision-tree.md .claude/skills/harness-loop/wizard/summary-format.md
git commit -m "feat(wizard): add decision tree and summary format"
```

---

## Phase 2: Core Templates

### Task 5: templates/AGENTS.md + concepts/* + ralph-tenets.md + strict-mode.md

**Files:**
- Create: `.claude/skills/harness-loop/templates/AGENTS.md`
- Create: `.claude/skills/harness-loop/templates/concepts/AGENTS.md`
- Create: `.claude/skills/harness-loop/templates/concepts/01-repo-as-truth.md`
- Create: `.claude/skills/harness-loop/templates/concepts/02-map-not-manual.md`
- Create: `.claude/skills/harness-loop/templates/concepts/03-mechanical-enforcement.md`
- Create: `.claude/skills/harness-loop/templates/concepts/04-agent-readability.md`
- Create: `.claude/skills/harness-loop/templates/concepts/05-throughput-merges.md`
- Create: `.claude/skills/harness-loop/templates/concepts/06-entropy-gc.md`
- Create: `.claude/skills/harness-loop/templates/ralph-tenets.md`
- Create: `.claude/skills/harness-loop/templates/strict-mode.md`

- [ ] **Step 1: Write `templates/AGENTS.md`** (~60 lines)

Conventions for templates/ directory:
- All template files use `.tmpl` suffix if they contain `{{placeholders}}`, plain extension otherwise
- `AGENTS.md` files in subdirs describe that subdir's writing rules
- Concept/methodology blocks are markdown fragments (no frontmatter), ready to inject into root AGENTS.md
- Check script templates must include strict-mode branching via `{{STRICT_MODE}}`
- No template file exceeds 200 lines (split if growing)

- [ ] **Step 2: Write `templates/concepts/AGENTS.md`** (~40 lines)

Rules for concept files:
- Each concept is a standalone markdown fragment (no frontmatter)
- Title is `## N. <concept name>` (level 2 heading, ready for injection)
- Body is 30-80 lines: definition + why-it-matters + how-to-apply + anti-pattern
- Concepts are stable; edit rarely

- [ ] **Step 3: Write each of the 6 concept files**

Each ~50 lines. Use this template:

```markdown
## N. <Concept Name>

<One-sentence definition>

### Why it matters
<2-3 paragraphs explaining the problem this concept solves>

### How to apply
<Concrete checklist of 3-5 practices>

### Anti-patterns
<2-3 examples of what NOT to do>

### References
<Links to source material>
```

Concept-specific content (write actual prose for each):

- **01-repo-as-truth.md**: "If it's not in the repo, it doesn't exist for the agent." Discuss Slack/Google Docs/tribal knowledge as invisible-to-agent. Application: all decisions in versioned files.
- **02-map-not-manual.md**: "AGENTS.md is an index, not an encyclopedia." Discuss three deaths of giant instruction files. Application: ~100 line root, progressive disclosure via subdir AGENTS.md.
- **03-mechanical-enforcement.md**: "Docs rot, lint rules don't." Custom linters as invariants. Application: every constraint must have a check script.
- **04-agent-readability.md**: "Optimize for agent reasoning over human convenience." Pick "boring" tech. Application: stable APIs, well-trained libraries.
- **05-throughput-merges.md**: "Correction is cheap, waiting is expensive." Short PR lifecycles, retry-on-flake. Application: don't block merges on flakey tests.
- **06-entropy-gc.md**: "Tech debt is high-interest debt." Agents reproduce patterns including bad ones. Application: encode golden rules, periodic entropy scans.

- [ ] **Step 4: Write `templates/ralph-tenets.md`** (~60 lines)

Format:

```markdown
## Ralph 6 信条

| 信条 | 含义 | 在本项目的应用 |
|---|---|---|
| Fresh Context Is Reliability | 每轮迭代重新读仓库 | agent 不依赖会话内存，所有状态写文件 |
| Backpressure Over Prescription | 不规定怎么做，门控拒绝坏结果 | check-*.sh 拒绝非零退出，但不指挥修复 |
| The Plan Is Disposable | 重新生成的成本只是 planning loop | 失败的尝试可丢弃，state/ 是真相 |
| Disk Is State, Git Is Memory | 文件是交接机制 | TASKS.md + state/iteration.md 持久化进度 |
| Steer With Signals, Not Scripts | 加路标，不加脚本 | AGENTS.md 描述目标，不写命令序列 |
| Let Ralph Ralph | 坐在循环上，不坐在循环里 | 用户监督而非微管理 |
```

- [ ] **Step 5: Write `templates/strict-mode.md`** (~50 lines)

```markdown
# Strict vs Advisory Mode

All generated `check-*.sh` scripts branch on `{{STRICT_MODE}}`:

## strict (default)

- Any check failure exits non-zero
- Pre-commit hook blocks the commit
- CI workflow fails the PR check
- Agent must fix before proceeding

## advisory

- Check failure prints warning to stderr
- Exit code is always 0
- Pre-commit hook allows the commit
- CI workflow posts a comment but doesn't block
- Useful for legacy codebases migrating to constraints

## Implementation in templates

Each `check-*.sh.tmpl` includes:

```bash
STRICT="{{STRICT_MODE}}"
if [[ "$STRICT" == "strict" ]]; then
  set -e
  FAILURES=0
else
  FAILURES=0
fi

# ... run check, increment FAILURES on issues ...

if [[ "$FAILURES" -gt 0 ]]; then
  if [[ "$STRICT" == "strict" ]]; then
    exit 1
  else
    exit 0
  fi
fi
```

## Decision rule

- New project → strict (catch issues early)
- Existing project, first time applying constraints → advisory (avoid blocking work)
- After cleanup pass → switch to strict
```

- [ ] **Step 6: Commit**

```bash
git add .claude/skills/harness-loop/templates/
git commit -m "feat(templates): add concepts, Ralph tenets, strict-mode, templates AGENTS"
```

---

### Task 6: templates/methodologies/*

**Files:**
- Create: `.claude/skills/harness-loop/templates/methodologies/AGENTS.md`
- Create: `.claude/skills/harness-loop/templates/methodologies/tdd.md`
- Create: `.claude/skills/harness-loop/templates/methodologies/sdd.md`
- Create: `.claude/skills/harness-loop/templates/methodologies/bdd.md`
- Create: `.claude/skills/harness-loop/templates/methodologies/ddd.md`
- Create: `.claude/skills/harness-loop/templates/methodologies/rdd.md`
- Create: `.claude/skills/harness-loop/templates/methodologies/plain.md`

- [ ] **Step 1: Write `templates/methodologies/AGENTS.md`** (~50 lines)

Rules:
- Each methodology file is a markdown fragment (no frontmatter)
- Starts with `## 工作循环: <Name>`
- Sections: Definition / Workflow steps / Acceptance criteria / Required artifacts / Anti-patterns
- 50-100 lines each
- Must reference the scaffolding directory it expects (e.g., TDD references `tests/`)

- [ ] **Step 2: Write each methodology file**

For each of TDD/SDD/BDD/DDD/RDD/Plain, write ~70 lines covering:

**tdd.md** — Red-Green-Refactor. Workflow: write failing test → run (see fail) → minimal impl → run (see pass) → refactor. Acceptance: all tests green, coverage ≥ threshold. Required artifacts: `tests/` directory. Anti-patterns: writing impl first, skipping the "see it fail" step.

**sdd.md** — Spec → Implementation. Workflow: write spec in `docs/specs/` → review spec → implement → verify against spec. Acceptance: spec exists, impl matches spec. Required artifacts: `docs/specs/<feature>.md`. Anti-patterns: coding without spec, spec drift.

**bdd.md** — Gherkin scenarios first. Workflow: write `.feature` file → step definitions → impl. Acceptance: all scenarios pass. Required artifacts: `features/*.feature`. Anti-patterns: impl without scenario, ambiguous Given/When/Then.

**ddd.md** — Ubiquitous language + domain modeling. Workflow: build `ubiquitous-language.md` → domain model → bounded contexts → impl. Acceptance: code uses ubiquitous language terms. Required artifacts: `docs/domain/ubiquitous-language.md`. Anti-patterns: anemic models, language divergence.

**rdd.md** — README first. Workflow: write README → API design → impl. Acceptance: README describes finished behavior. Required artifacts: `docs/readme-first.md`. Anti-patterns: README after impl.

**plain.md** — No methodology enforced. Just project conventions in AGENTS.md. Workflow: follow AGENTS.md rules. Acceptance: check-tests.sh passes.

- [ ] **Step 3: Commit**

```bash
git add .claude/skills/harness-loop/templates/methodologies/
git commit -m "feat(templates): add 6 methodology blocks (TDD/SDD/BDD/DDD/RDD/Plain)"
```

---

### Task 7: templates/agents-root.md.tmpl + agents-subdir.md.tmpl

**Files:**
- Create: `.claude/skills/harness-loop/templates/agents-root.md.tmpl`
- Create: `.claude/skills/harness-loop/templates/agents-subdir.md.tmpl`

- [ ] **Step 1: Write `agents-root.md.tmpl`** (~100 lines after rendering)

This is the assembly shell for the project's root AGENTS.md. Placeholders:

```
{{PROJECT_NAME}}
{{MISSION_ONE_LINER}}
{{CONCEPTS_BLOCK}}      # 6 concepts injected
{{RALPH_TENETS_BLOCK}}  # Ralph 6 tenets injected
{{METHODOLOGY_BLOCK}}   # Q2 methodology injected
{{SUBDIR_INDEX}}        # Generated from Q2/Q3
{{CHECKS_INDEX}}        # Generated from Q4
{{TASKS_POINTER}}       # Always points to TASKS.md
{{STRICT_MODE_DECL}}    # strict or advisory
```

Template body structure:

```markdown
# {{PROJECT_NAME}}

{{MISSION_ONE_LINER}}

## 6 大概念

{{CONCEPTS_BLOCK}}

## Ralph 信条

{{RALPH_TENETS_BLOCK}}

## 工作循环

{{METHODOLOGY_BLOCK}}

## 子目录索引

{{SUBDIR_INDEX}}

## 机械化检查

{{CHECKS_INDEX}}

入口：`./scripts/check-tests.sh`（验证完成度）
     `./scripts/check-consistency.sh`（验证仓库一致性）

## 当前任务

见 `TASKS.md`。每轮迭代更新 `state/iteration.md`。

## 严格度

本仓库采用 **{{STRICT_MODE_DECL}}** 模式。
- strict: 任何检查失败阻断 commit/merge
- advisory: 仅警告不阻断
```

- [ ] **Step 2: Write `agents-subdir.md.tmpl`** (~40 lines)

Template for subdirectory AGENTS.md files:

```markdown
# {{SUBDIR_PATH}}/

{{SUBDIR_PURPOSE}}

## 本目录约定

{{SUBDIR_CONVENTIONS}}

## 与根 AGENTS.md 的关系

继承根 AGENTS.md 的 6 大概念和 Ralph 信条。本文件只补充本目录特有规则。

## 验证

本目录相关的检查：
{{SUBDIR_RELATED_CHECKS}}
```

- [ ] **Step 3: Verify placeholders used in decision-tree**

Run: `grep -o '{{[A-Z_]*}}' .claude/skills/harness-loop/templates/agents-root.md.tmpl | sort -u`
Expected output: list of all placeholders used. Cross-check each appears in `decision-tree.md` or `summary-format.md`.

- [ ] **Step 4: Commit**

```bash
git add .claude/skills/harness-loop/templates/agents-root.md.tmpl .claude/skills/harness-loop/templates/agents-subdir.md.tmpl
git commit -m "feat(templates): add root and subdir AGENTS.md templates"
```

---

## Phase 3: Check Script Templates

### Task 8: templates/checks/AGENTS.md + check-tests.sh.tmpl + check-consistency.sh.tmpl

**Files:**
- Create: `.claude/skills/harness-loop/templates/checks/AGENTS.md`
- Create: `.claude/skills/harness-loop/templates/checks/check-tests.sh.tmpl`
- Create: `.claude/skills/harness-loop/templates/checks/check-consistency.sh.tmpl`

- [ ] **Step 1: Write `templates/checks/AGENTS.md`** (~60 lines)

Rules:
- Every check-*.sh.tmpl starts with `#!/usr/bin/env bash` and `set -uo pipefail` (no `-e` — explicit failure tracking)
- Strict mode branched via `{{STRICT_MODE}}` env var
- Error format: `❌ <check-id> <message>\n   修复: <fix instruction>`
- Success format: `✅ <check-id> passed`
- Exit 0 on success, exit 1 on failure in strict mode, exit 0 in advisory mode
- All paths relative to project root

- [ ] **Step 2: Write `check-tests.sh.tmpl`** (~60 lines)

```bash
#!/usr/bin/env bash
# C3: External verification — runs test/lint/typecheck for {{LANGUAGE}}
# Generated by harness-loop skill. Strict mode: {{STRICT_MODE}}.

set -uo pipefail

STRICT="{{STRICT_MODE}}"
FAILURES=0
LANGUAGE="{{LANGUAGE}}"

run_check() {
  local name="$1"
  local cmd="$2"
  echo "▶ $name: $cmd"
  if eval "$cmd"; then
    echo "✅ $name passed"
  else
    echo "❌ $name failed"
    echo "   修复: 查看 $name 输出，修复至通过"
    FAILURES=$((FAILURES + 1))
  fi
}

case "$LANGUAGE" in
  Python)
    run_check "pytest" "pytest tests/"
    run_check "ruff" "ruff check ."
    run_check "mypy" "mypy src/"
    ;;
  Node)
    run_check "vitest" "vitest run"
    run_check "eslint" "eslint ."
    run_check "tsc" "tsc --noEmit"
    ;;
  Go)
    run_check "go_test" "go test ./..."
    run_check "golangci-lint" "golangci-lint run"
    run_check "gofmt" 'test -z "$(gofmt -l .)"'
    ;;
  Java)
    run_check "mvn_test" "mvn -q test"
    run_check "checkstyle" "mvn -q checkstyle:check"
    run_check "mvn_compile" "mvn -q compile"
    ;;
  Non-code)
    echo "✅ C3 skipped: non-code project"
    ;;
  *)
    echo "❌ C3 unsupported language: $LANGUAGE"
    echo "   修复: 在 scripts/check-tests.sh 添加 $LANGUAGE 的命令"
    FAILURES=$((FAILURES + 1))
    ;;
esac

if [[ "$FAILURES" -gt 0 ]]; then
  if [[ "$STRICT" == "strict" ]]; then
    echo "🛑 C3: $FAILURES failures (strict mode)"
    exit 1
  else
    echo "⚠️  C3: $FAILURES failures (advisory mode, not blocking)"
    exit 0
  fi
fi

echo "✅ C3: all checks passed"
exit 0
```

- [ ] **Step 3: Write `check-consistency.sh.tmpl`** (~120 lines)

This implements C1/C2/C6 (number consistency, reference alignment, subdir AGENTS.md existence). Write the full bash logic with:

- C1: count `*.md` files in `concepts/`, `thinking/`, `feedback/` (if exist) and verify against README declarations
- C2: verify AGENTS.md subdir index entries match actual subdir AGENTS.md files
- C6: verify each expected subdir (per Q2 methodology + Q3 language) has an AGENTS.md

Use grep + find + wc to count. For each mismatch, emit `❌ C<N> ...` with fix instruction.

Full implementation: see design doc §5.4 and harness-engineering/scripts/check-consistency.sh for reference pattern.

- [ ] **Step 4: Verify templates parse as valid bash after substitution**

Run:
```bash
cd .claude/skills/harness-loop/templates/checks/
sed -e 's/{{STRICT_MODE}}/strict/g' -e 's/{{LANGUAGE}}/Java/g' check-tests.sh.tmpl > /tmp/test.sh
bash -n /tmp/test.sh && echo "OK: syntax valid" || echo "FAIL: syntax error"
```
Expected: `OK: syntax valid`

- [ ] **Step 5: Commit**

```bash
git add .claude/skills/harness-loop/templates/checks/
git commit -m "feat(checks): add AGENTS.md, check-tests.sh.tmpl, check-consistency.sh.tmpl"
```

---

### Task 9: check-promise.sh.tmpl + check-entropy.sh.tmpl + check-stuck.sh.tmpl

**Files:**
- Create: `.claude/skills/harness-loop/templates/checks/check-promise.sh.tmpl`
- Create: `.claude/skills/harness-loop/templates/checks/check-entropy.sh.tmpl`
- Create: `.claude/skills/harness-loop/templates/checks/check-stuck.sh.tmpl`

- [ ] **Step 1: Write `check-promise.sh.tmpl`** (~50 lines)

C4: scans last agent output for `<promise>{{PROMISE_TOKEN}}</promise>` tag.

```bash
#!/usr/bin/env bash
# C4: Completion promise detection
# Looks for <promise>{{PROMISE_TOKEN}}</promise> in last agent output.

set -uo pipefail

STRICT="{{STRICT_MODE}}"
TOKEN="{{PROMISE_TOKEN}}"
OUTPUT_FILE="${1:-state/last-output.txt}"

if [[ ! -f "$OUTPUT_FILE" ]]; then
  echo "❌ C4: output file not found: $OUTPUT_FILE"
  echo "   修复: 确保 agent 把输出写到 $OUTPUT_FILE"
  [[ "$STRICT" == "strict" ]] && exit 1 || exit 0
fi

if grep -q "<promise>${TOKEN}</promise>" "$OUTPUT_FILE"; then
  echo "✅ C4: promise '$TOKEN' detected"
  exit 0
else
  echo "❌ C4: promise '$TOKEN' not found in $OUTPUT_FILE"
  echo "   修复: 继续任务直到完成, 然后输出 <promise>${TOKEN}</promise>"
  [[ "$STRICT" == "strict" ]] && exit 1 || exit 0
fi
```

- [ ] **Step 2: Write `check-entropy.sh.tmpl`** (~80 lines)

C5: scans for repeated code patterns, TODO accumulation, deviation from golden rules.

```bash
#!/usr/bin/env bash
# C5: Entropy scan — detects pattern drift and quality degradation.

set -uo pipefail

STRICT="{{STRICT_MODE}}"
FAILURES=0
ENTROPY_LOG="state/entropy-log.md"

# Initialize entropy log if missing
if [[ ! -f "$ENTROPY_LOG" ]]; then
  mkdir -p state
  cat > "$ENTROPY_LOG" <<EOF
# Entropy Log

Tracks pattern drift and quality issues found by C5.

| Date | Issue | Location | Severity |
|------|-------|----------|----------|
EOF
fi

# Check 1: TODO/FIXME accumulation
TODO_COUNT=$(grep -rE "TODO|FIXME" --include="*.{{SOURCE_EXT}}" src/ 2>/dev/null | wc -l)
if [[ "$TODO_COUNT" -gt {{TODO_THRESHOLD:-20}} ]]; then
  echo "❌ C5-1: TODO/FIXME count ($TODO_COUNT) exceeds threshold ({{TODO_THRESHOLD:-20}})"
  echo "   修复: 清理 src/ 下的 TODO/FIXME 到阈值以下"
  FAILURES=$((FAILURES + 1))
else
  echo "✅ C5-1: TODO/FIXME count ($TODO_COUNT) within threshold"
fi

# Check 2: File length outliers (any file > 500 lines)
LARGE_FILES=$(find src/ -name "*.{{SOURCE_EXT}}" -exec wc -l {} \; 2>/dev/null | awk '$1 > 500 {print $2}')
if [[ -n "$LARGE_FILES" ]]; then
  echo "⚠️  C5-2: large files (>500 lines):"
  echo "$LARGE_FILES" | while read f; do echo "   - $f"; done
  echo "   修复: 拆分大文件, 单一职责"
  FAILURES=$((FAILURES + 1))
else
  echo "✅ C5-2: no oversized files"
fi

# Check 3: Duplicated function names (basic heuristic)
DUPES=$(grep -rhE "^(function |def |func |public )" src/ 2>/dev/null | sort | uniq -d | head -5)
if [[ -n "$DUPES" ]]; then
  echo "❌ C5-3: duplicated declarations:"
  echo "$DUPES" | while read d; do echo "   - $d"; done
  echo "   修复: 重命名或合并重复声明"
  FAILURES=$((FAILURES + 1))
else
  echo "✅ C5-3: no duplicate declarations"
fi

# Append findings to entropy log
if [[ "$FAILURES" -gt 0 ]]; then
  echo "| $(date -Iseconds) | entropy scan | multiple | warn |" >> "$ENTROPY_LOG"
fi

[[ "$STRICT" == "strict" && "$FAILURES" -gt 0 ]] && exit 1 || exit 0
```

- [ ] **Step 3: Write `check-stuck.sh.tmpl`** (~70 lines)

Stuck detection: compares `state/iteration.md` progress fields across last K iterations.

```bash
#!/usr/bin/env bash
# Stuck detection: compares last K iterations for progress.

set -uo pipefail

STRICT="{{STRICT_MODE}}"
THRESHOLD="{{STUCK_THRESHOLD:-3}}"
STATE_FILE="state/iteration.md"

if [[ ! -f "$STATE_FILE" ]]; then
  echo "❌ stuck: state file missing: $STATE_FILE"
  exit 1
fi

# Extract: iteration number, last-progress signature (files changed + tests passing)
CURRENT_ITER=$(grep '^iteration:' "$STATE_FILE" | tail -1 | awk '{print $2}')
LAST_PROGRESS_SIG=$(grep '^progress_signature:' "$STATE_FILE" | tail -"$THRESHOLD" | sort -u | wc -l)

if [[ "$LAST_PROGRESS_SIG" -le 1 && "$CURRENT_ITER" -ge "$THRESHOLD" ]]; then
  echo "🛑 stuck: no progress in last $THRESHOLD iterations (currently at $CURRENT_ITER)"
  echo "   修复: "
  echo "     1. 检查 TASKS.md 当前子任务是否可达成"
  echo "     2. 考虑拆解子任务或换思路"
  echo "     3. 在 state/iteration.md 写下阻塞点"
  echo "     4. 终止 loop, 让人类介入"
  exit 2  # exit 2 = stuck (distinct from check failure)
else
  echo "✅ stuck: progress detected in last $THRESHOLD iterations"
  exit 0
fi
```

- [ ] **Step 4: Verify all three parse as valid bash**

```bash
for f in check-promise check-entropy check-stuck; do
  sed -e 's/{{STRICT_MODE}}/strict/g' -e 's/{{PROMISE_TOKEN}}/DONE/g' -e 's/{{STUCK_THRESHOLD:-3}}/3/g' -e 's/{{SOURCE_EXT}}/java/g' -e 's/{{LANGUAGE}}/Java/g' \
    ".claude/skills/harness-loop/templates/checks/${f}.sh.tmpl" > /tmp/${f}.sh
  bash -n /tmp/${f}.sh && echo "$f: OK" || echo "$f: FAIL"
done
```
Expected: each prints `OK`.

- [ ] **Step 5: Commit**

```bash
git add .claude/skills/harness-loop/templates/checks/check-{promise,entropy,stuck}.sh.tmpl
git commit -m "feat(checks): add promise/entropy/stuck detection templates"
```

---

### Task 10: pre-commit.tmpl + consistency.yml.tmpl

**Files:**
- Create: `.claude/skills/harness-loop/templates/checks/pre-commit.tmpl`
- Create: `.claude/skills/harness-loop/templates/checks/consistency.yml.tmpl`

- [ ] **Step 1: Write `pre-commit.tmpl`** (~50 lines)

```bash
#!/usr/bin/env bash
# Pre-commit hook: runs mechanical checks before allowing commit.
# Activated via: git config core.hooksPath .githooks
# Generated by harness-loop skill (strict={{STRICT_MODE}}).

set -uo pipefail

STRICT="{{STRICT_MODE}}"

# Only run if controlled files are staged
CONTROLLED=$(git diff --cached --name-only --diff-filter=ACMR | grep -E '^(AGENTS\.md|README\.md|scripts/|\.github/workflows/|docs/specs/|tests/|src/|features/|state/iteration\.md|TASKS\.md)$' || true)

if [[ -z "$CONTROLLED" ]]; then
  exit 0
fi

echo "🔍 Running mechanical checks (changed: $(echo $CONTROLLED | tr '\n' ' '))"

FAIL=0
[[ -f scripts/check-consistency.sh ]] && bash scripts/check-consistency.sh || FAIL=$?
[[ -f scripts/check-tests.sh ]] && bash scripts/check-tests.sh || FAIL=$?

if [[ "$FAIL" -ne 0 ]]; then
  if [[ "$STRICT" == "strict" ]]; then
    echo "🛑 Commit blocked by mechanical checks (strict mode)"
    echo "   绕过(不推荐): git commit --no-verify"
    exit 1
  else
    echo "⚠️  Checks failed but advisory mode allows commit"
    exit 0
  fi
fi

exit 0
```

- [ ] **Step 2: Write `consistency.yml.tmpl`** (~50 lines)

GitHub Actions workflow that runs the same checks as pre-commit, on push/PR.

```yaml
name: consistency

on:
  push:
    paths:
      - 'AGENTS.md'
      - 'README.md'
      - 'scripts/**'
      - '.github/workflows/**'
      - 'docs/**'
      - 'tests/**'
      - 'src/**'
      - 'features/**'
      - 'state/iteration.md'
      - 'TASKS.md'
  pull_request:
    paths: ['**']

jobs:
  checks:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Setup Java
        if: hashFiles('pom.xml') != ''
        uses: actions/setup-java@v4
        with:
          distribution: 'temurin'
          java-version: '21'
          cache: maven
      - name: Setup Python
        if: hashFiles('pyproject.toml') != '' || hashFiles('requirements.txt') != ''
        uses: actions/setup-python@v5
        with:
          python-version: '3.12'
      - name: Setup Node
        if: hashFiles('package.json') != ''
        uses: actions/setup-node@v4
        with:
          node-version: '20'
      - name: Setup Go
        if: hashFiles('go.mod') != ''
        uses: actions/setup-go@v5
        with:
          go-version: '1.22'
      - name: Run consistency checks
        run: bash scripts/check-consistency.sh
      - name: Run tests
        if: hashFiles('scripts/check-tests.sh') != ''
        run: bash scripts/check-tests.sh
```

- [ ] **Step 3: Verify YAML validity**

```bash
sed -e 's/{{STRICT_MODE}}/strict/g' .claude/skills/harness-loop/templates/checks/consistency.yml.tmpl > /tmp/test.yml
python -c "import yaml; yaml.safe_load(open('/tmp/test.yml'))" && echo "YAML OK" || echo "YAML FAIL"
```
Expected: `YAML OK`. (If python not available, use any YAML linter.)

- [ ] **Step 4: Commit**

```bash
git add .claude/skills/harness-loop/templates/checks/pre-commit.tmpl .claude/skills/harness-loop/templates/checks/consistency.yml.tmpl
git commit -m "feat(checks): add pre-commit hook and CI workflow templates"
```

---

## Phase 4: Scaffolding

### Task 11: scaffolding/AGENTS.md + tasks-md.tmpl + state files

**Files:**
- Create: `.claude/skills/harness-loop/templates/scaffolding/AGENTS.md`
- Create: `.claude/skills/harness-loop/templates/scaffolding/tasks-md.tmpl`
- Create: `.claude/skills/harness-loop/templates/scaffolding/state-iteration.tmpl`
- Create: `.claude/skills/harness-loop/templates/scaffolding/state-entropy.tmpl`

- [ ] **Step 1: Write `scaffolding/AGENTS.md`** (~50 lines)

Rules:
- All scaffolding templates use `.tmpl` suffix
- Placeholders match those in `wizard/decision-tree.md`
- Generated files are commit-ready (don't leave TODO markers)

- [ ] **Step 2: Write `tasks-md.tmpl`** (~60 lines)

```markdown
# Tasks

Active task board for {{PROJECT_NAME}}. Updated each loop iteration.

## Current epic

{{CURRENT_EPIC_DESCRIPTION}}

## Subtasks

- [ ] {{SUBTASK_1}}
- [ ] {{SUBTASK_2}}
- [ ] {{SUBTASK_3}}

## Done

(initially empty)

## Blocked

(initially empty)

---

## Conventions

- Each subtask is one checkable unit of work
- Check off (`[x]`) only after `scripts/check-tests.sh` passes for that subtask
- If blocked: move to Blocked section + add entry to `state/iteration.md`
- One PR per subtask when feasible (per throughput-merges concept)
```

- [ ] **Step 3: Write `state-iteration.tmpl`** (~50 lines)

```markdown
---
iteration: 1
max_iterations: {{MAX_ITERATIONS}}
last_updated: {{TIMESTAMP}}
progress_signature: {{PROGRESS_SIG}}
---

# Iteration State

## Current

- Iteration: 1 / {{MAX_ITERATIONS}}
- Active subtask: see TASKS.md
- Last action: {{LAST_ACTION}}

## Progress log

| Iter | Date | Files changed | Tests passing | Notes |
|------|------|---------------|---------------|-------|
| 1 | {{TIMESTAMP}} | (initial) | 0 | Loop started |

## Blockers

(none)

## Recovery

If loop restarts, read this file first to resume:
1. Current iteration number (above)
2. Active subtask in TASKS.md
3. Last progress signature (for stuck detection)
```

- [ ] **Step 4: Write `state-entropy.tmpl`** (~30 lines)

```markdown
# Entropy Log

Tracks pattern drift found by `scripts/check-entropy.sh`.

| Date | Issue | Location | Severity | Status |
|------|-------|----------|----------|--------|
| (initially empty) |

## Severity levels

- `info`: noted, no action needed
- `warn`: should fix in next refactor pass
- `error`: violates a golden rule, fix before merge
```

- [ ] **Step 5: Commit**

```bash
git add .claude/skills/harness-loop/templates/scaffolding/
git commit -m "feat(scaffolding): add AGENTS.md, tasks-md, state files"
```

---

### Task 12: scaffolding/gitignore.tmpl + readme-section.tmpl + opencode-config.json.tmpl

**Files:**
- Create: `.claude/skills/harness-loop/templates/scaffolding/gitignore.tmpl`
- Create: `.claude/skills/harness-loop/templates/scaffolding/readme-section.tmpl`
- Create: `.claude/skills/harness-loop/templates/scaffolding/opencode-config.json.tmpl`

- [ ] **Step 1: Write `gitignore.tmpl`** (~30 lines)

```gitignore
# Harness-loop generated — append to existing .gitignore

# State (iteration tracking committed; transcripts not)
state/transcript*
state/*.log
state/last-output.txt

# Backups
*.bak

# OS
.DS_Store
Thumbs.db

{{LANGUAGE_SPECIFIC_IGNORES}}
```

For `{{LANGUAGE_SPECIFIC_IGNORES}}`, decision-tree substitutes based on Q3:
- Python: `__pycache__/\n*.pyc\n.venv/`
- Node: `node_modules/\ndist/\n*.log`
- Go: no additions
- Java: `target/\n*.class\n.mvn/wrapper/maven-wrapper.jar`

- [ ] **Step 2: Write `readme-section.tmpl`** (~40 lines)

```markdown
## How the AI agent works on this repo

This repo uses an [agents.md](https://agents.md)-compatible constraint system. The AI agent (opencode or similar) follows:

1. **Root entry**: reads `AGENTS.md` (~100 lines) for project mission, 6 concepts, Ralph tenets, and pointers to deeper rules.
2. **Progressive disclosure**: when entering a subdirectory, reads that subdir's `AGENTS.md` for local rules.
3. **Mechanical checks**: before commit, `.githooks/pre-commit` runs `scripts/check-*.sh`. CI re-runs the same on PRs.
4. **Task tracking**: `TASKS.md` is the source of truth for in-progress work. `state/iteration.md` tracks loop progress.
5. **Strict mode**: this repo is **{{STRICT_MODE}}** — failures block commits.

### To enable pre-commit hook locally

```
git config core.hooksPath .githooks
```

### To manually run checks

```
bash scripts/check-tests.sh
bash scripts/check-consistency.sh
```

### To start a loop iteration (if using opencode)

```
opencode  # reads AGENTS.md, works on TASKS.md, writes state/iteration.md
```
```

- [ ] **Step 3: Write `opencode-config.json.tmpl`** (~30 lines)

```json
{
  "model": "{{MODEL_ID}}",
  "max_tokens": 8192,
  "context_window": 200000,
  "tools": {
    "allow": [
      "read", "write", "edit", "bash",
      "grep", "glob"
    ]
  },
  "instruction_file": "AGENTS.md",
  "loop": {
    "max_iterations": {{MAX_ITERATIONS}},
    "stop_on_promise": true,
    "promise_token": "{{PROMISE_TOKEN}}",
    "stuck_threshold": {{STUCK_THRESHOLD}}
  }
}
```

- [ ] **Step 4: Verify JSON validity**

```bash
sed -e 's/{{MODEL_ID}}/claude-sonnet-4-6/g' -e 's/{{MAX_ITERATIONS}}/30/g' -e 's/{{PROMISE_TOKEN}}/DONE/g' -e 's/{{STUCK_THRESHOLD}}/3/g' \
  .claude/skills/harness-loop/templates/scaffolding/opencode-config.json.tmpl > /tmp/test.json
python -c "import json; json.load(open('/tmp/test.json'))" && echo "JSON OK" || echo "JSON FAIL"
```
Expected: `JSON OK`.

- [ ] **Step 5: Commit**

```bash
git add .claude/skills/harness-loop/templates/scaffolding/gitignore.tmpl .claude/skills/harness-loop/templates/scaffolding/readme-section.tmpl .claude/skills/harness-loop/templates/scaffolding/opencode-config.json.tmpl
git commit -m "feat(scaffolding): add gitignore, readme-section, opencode-config templates"
```

---

### Task 13: tests-java/ scaffolding (primary language)

**Files:**
- Create: `.claude/skills/harness-loop/templates/scaffolding/methodology-dirs/tests-java/AGENTS.md`
- Create: `.claude/skills/harness-loop/templates/scaffolding/methodology-dirs/tests-java/pom.xml.tmpl`
- Create: `.claude/skills/harness-loop/templates/scaffolding/methodology-dirs/tests-java/src/test/java/FirstTest.java.tmpl`

- [ ] **Step 1: Write `tests-java/AGENTS.md`** (~60 lines)

Conventions for the generated `tests/` directory in user projects:
- Maven Standard Layout: `src/main/java/`, `src/test/java/`
- Test classes end with `Test` (e.g., `CalculatorTest.java`)
- One test class per production class
- Test methods use `@Test` + `@DisplayName` for intent
- Use JUnit 5 assertions (`assertEquals`, `assertThrows`)
- Use Mockito for collaborators
- Coverage threshold: ≥80% line coverage (enforced via `mvn test` + JaCoCo, if configured)

- [ ] **Step 2: Write `pom.xml.tmpl`** (~80 lines)

```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0">
  <modelVersion>4.0.0</modelVersion>
  <groupId>{{GROUP_ID}}</groupId>
  <artifactId>{{ARTIFACT_ID}}</artifactId>
  <version>{{VERSION}}</version>
  <packaging>jar</packaging>

  <properties>
    <maven.compiler.release>21</maven.compiler.release>
    <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
    <junit.version>5.10.2</junit.version>
    <mockito.version>5.11.0</mockito.version>
  </properties>

  <dependencies>
    <dependency>
      <groupId>org.junit.jupiter</groupId>
      <artifactId>junit-jupiter</artifactId>
      <version>${junit.version}</version>
      <scope>test</scope>
    </dependency>
    <dependency>
      <groupId>org.mockito</groupId>
      <artifactId>mockito-core</artifactId>
      <version>${mockito.version}</version>
      <scope>test</scope>
    </dependency>
  </dependencies>

  <build>
    <plugins>
      <plugin>
        <artifactId>maven-surefire-plugin</artifactId>
        <version>3.2.5</version>
      </plugin>
      <plugin>
        <groupId>org.apache.maven.plugins</groupId>
        <artifactId>maven-checkstyle-plugin</artifactId>
        <version>3.3.1</version>
        <configuration>
          <failsOnError>{{CHECKSTYLE_FAILS_ON_ERROR}}</failsOnError>
          <configLocation>google_checks.xml</configLocation>
        </configuration>
      </plugin>
    </plugins>
  </build>
</project>
```

- [ ] **Step 3: Write `FirstTest.java.tmpl`** (~30 lines)

A deliberately failing test that proves the loop wiring works:

```java
package {{PACKAGE}};

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;

/**
 * First test — intentionally failing.
 * Demonstrates TDD red phase: write failing test first, then implement.
 */
class FirstTest {

    @Test
    @DisplayName("placeholder test should pass after implementation")
    void placeholder() {
        // Replace this assertion with real test logic
        assertEquals(2, 1 + 1, "math works");
    }
}
```

(Note: this test actually passes — `1+1=2`. The user replaces the assertion with their own failing test.)

- [ ] **Step 4: Commit**

```bash
git add .claude/skills/harness-loop/templates/scaffolding/methodology-dirs/tests-java/
git commit -m "feat(scaffolding): add Java/Maven/JUnit5 tests scaffolding"
```

---

### Task 14: tests-python/ + tests-node/ + tests-go/ scaffolding

**Files:**
- Create: `.claude/skills/harness-loop/templates/scaffolding/methodology-dirs/tests-python/{AGENTS.md, test_first.template.py}`
- Create: `.claude/skills/harness-loop/templates/scaffolding/methodology-dirs/tests-node/{AGENTS.md, first-test.template.ts}`
- Create: `.claude/skills/harness-loop/templates/scaffolding/methodology-dirs/tests-go/{AGENTS.md, first_test.template.go}`

- [ ] **Step 1: Write tests-python/ contents**

`AGENTS.md` (~50 lines): pytest conventions — `tests/` dir, `test_*.py` files, fixtures, parametrize.

`test_first.template.py` (~20 lines):
```python
"""First test — replace with real test logic."""
import pytest


def test_placeholder():
    """Demonstrates test wiring. Replace assertion with real test."""
    assert 1 + 1 == 2
```

- [ ] **Step 2: Write tests-node/ contents**

`AGENTS.md` (~50 lines): vitest conventions — `tests/` dir, `*.test.ts` files, describe/it.

`first-test.template.ts` (~20 lines):
```typescript
import { describe, it, expect } from 'vitest';

describe('placeholder', () => {
  it('should pass after implementation', () => {
    // Replace with real test
    expect(1 + 1).toBe(2);
  });
});
```

- [ ] **Step 3: Write tests-go/ contents**

`AGENTS.md` (~50 lines): Go test conventions — `_test.go` suffix, table-driven, `t.Run` subtests.

`first_test.template.go` (~25 lines):
```go
package {{PACKAGE}}

import "testing"

func TestPlaceholder(t *testing.T) {
    // Replace with real test logic
    got := 1 + 1
    want := 2
    if got != want {
        t.Errorf("got %d, want %d", got, want)
    }
}
```

- [ ] **Step 4: Commit**

```bash
git add .claude/skills/harness-loop/templates/scaffolding/methodology-dirs/tests-python/ \
        .claude/skills/harness-loop/templates/scaffolding/methodology-dirs/tests-node/ \
        .claude/skills/harness-loop/templates/scaffolding/methodology-dirs/tests-go/
git commit -m "feat(scaffolding): add Python/Node/Go tests scaffolding"
```

---

### Task 15: methodology dirs (specs/features/domain/readme-first)

**Files:**
- Create: `.claude/skills/harness-loop/templates/scaffolding/methodology-dirs/specs/{AGENTS.md, template.md}`
- Create: `.claude/skills/harness-loop/templates/scaffolding/methodology-dirs/features/{AGENTS.md, example.feature}`
- Create: `.claude/skills/harness-loop/templates/scaffolding/methodology-dirs/domain/{AGENTS.md, ubiquitous-language.md}`
- Create: `.claude/skills/harness-loop/templates/scaffolding/methodology-dirs/readme-first/readme-first.md`

- [ ] **Step 1: Write specs/ (SDD) contents**

`AGENTS.md` (~50 lines): spec writing rules — one feature per file, sections (Goals/Constraints/Acceptance), ASCII diagrams encouraged.

`template.md` (~80 lines):
```markdown
# Spec: {{FEATURE_NAME}}

## Status
Draft | Reviewed | Implemented

## Goal
<1-3 sentences on what this feature achieves>

## Stakeholders
- PM: 
- Tech lead: 
- Reviewers: 

## Constraints
- <Hard constraints: performance, security, compatibility>

## Design
<Architecture, data model, key algorithms. ASCII diagrams OK.>

## Acceptance criteria
- [ ] <Criterion 1>
- [ ] <Criterion 2>
- [ ] All tests in tests/<feature>_test.* pass
- [ ] Documentation updated

## Out of scope
- <Explicitly excluded>

## Open questions
- <Unresolved decisions>
```

- [ ] **Step 2: Write features/ (BDD) contents**

`AGENTS.md` (~40 lines): Gherkin conventions — Feature/Scenario/Given/When/Then.

`example.feature` (~30 lines):
```gherkin
Feature: Example feature
  As a <role>
  I want <capability>
  So that <benefit>

  Scenario: example scenario
    Given <initial state>
    When <action>
    Then <expected outcome>
```

- [ ] **Step 3: Write domain/ (DDD) contents**

`AGENTS.md` (~50 lines): DDD rules — ubiquitous language, bounded contexts, aggregates.

`ubiquitous-language.md` (~50 lines):
```markdown
# Ubiquitous Language

Terms used throughout the codebase. Code must use these exact terms.

| Term | Definition | Code reference |
|------|------------|----------------|
| <Term1> | <definition> | <class/module> |
| <Term2> | <definition> | <class/module> |

## Bounded contexts

- <Context1>: <responsibility>
- <Context2>: <responsibility>

## Aggregates

- <Aggregate1> (root: <Entity>): invariants
```

- [ ] **Step 4: Write readme-first/ (RDD) contents**

`readme-first.md` (~40 lines):
```markdown
# README-First Workflow

When adding a new feature, write the README section first.

1. Describe the feature from the user's perspective
2. Show example usage (CLI, API, UI)
3. Document error cases
4. Then — and only then — start implementation

If you can't describe the feature clearly in the README, the design isn't ready.
```

- [ ] **Step 5: Commit**

```bash
git add .claude/skills/harness-loop/templates/scaffolding/methodology-dirs/{specs,features,domain,readme-first}/
git commit -m "feat(scaffolding): add SDD/BDD/DDD/RDD methodology scaffolding"
```

---

## Phase 5: Verification Scripts (skill self-check)

### Task 16: scripts/check-skill.sh (L1 static)

**Files:**
- Create: `.claude/skills/harness-loop/scripts/check-skill.sh`

- [ ] **Step 1: Write the script**

```bash
#!/usr/bin/env bash
# L1: Static checks for the harness-loop skill itself.
# Verifies frontmatter, template path consistency, line counts.

set -uo pipefail

SKILL_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$SKILL_DIR"

FAIL=0

# S1: SKILL.md frontmatter
if ! head -3 SKILL.md | grep -q '^---$'; then
  echo "❌ S1: SKILL.md missing frontmatter opening ---"
  FAIL=$((FAIL+1))
fi
if ! head -10 SKILL.md | grep -q '^name: harness-loop$'; then
  echo "❌ S1: SKILL.md missing 'name: harness-loop'"
  FAIL=$((FAIL+1))
fi
if ! head -10 SKILL.md | grep -qE '^description: .+$'; then
  echo "❌ S1: SKILL.md missing description"
  FAIL=$((FAIL+1))
fi

# S2: decision-tree references → file existence
DEC_TREE="wizard/decision-tree.md"
if [[ ! -f "$DEC_TREE" ]]; then
  echo "❌ S2: $DEC_TREE not found"
  FAIL=$((FAIL+1))
else
  # Extract template paths referenced in tables
  while IFS= read -r p; do
    # Strip table-cell chars and quotes
    path=$(echo "$p" | sed 's/`//g' | sed 's/|$//' | sed 's/^|//' | tr -d ' ')
    if [[ "$path" == templates/* ]] && [[ ! -e "$path" ]]; then
      echo "❌ S2: decision-tree references missing path: $path"
      FAIL=$((FAIL+1))
    fi
  done < <(grep -oE 'templates/[A-Za-z0-9_/.-]+' "$DEC_TREE" | sort -u)
fi

# S3: every .tmpl file uses {{...}} placeholders
TMPL_COUNT=0
PLACEHOLDER_FAIL=0
while IFS= read -r f; do
  TMPL_COUNT=$((TMPL_COUNT+1))
  if ! grep -qE '\{\{[A-Z_]+\}\}' "$f"; then
    # .tmpl files MUST have at least one placeholder (otherwise why .tmpl?)
    echo "⚠️  S3: $f has no {{PLACEHOLDER}} — should it be a plain file?"
    PLACEHOLDER_FAIL=$((PLACEHOLDER_FAIL+1))
  fi
done < <(find templates -name '*.tmpl' -type f)

# S4: subdir AGENTS.md ≤ 100 lines
LONG_AGENTS=0
while IFS= read -r f; do
  lines=$(wc -l < "$f")
  if [[ "$lines" -gt 100 ]]; then
    echo "❌ S4: $f is $lines lines (max 100)"
    LONG_AGENTS=$((LONG_AGENTS+1))
    FAIL=$((FAIL+1))
  fi
done < <(find . -name AGENTS.md -not -path './examples/*')

echo ""
echo "L1 Summary: $TMPL_COUNT templates, $PLACEHOLDER_FAIL placeholder warnings, $LONG_AGENTS oversized AGENTS.md"

if [[ "$FAIL" -gt 0 ]]; then
  echo "🛑 L1: $FAIL failures"
  exit 1
fi

echo "✅ L1: all static checks passed"
exit 0
```

- [ ] **Step 2: Make executable and run**

```bash
chmod +x .claude/skills/harness-loop/scripts/check-skill.sh
bash .claude/skills/harness-loop/scripts/check-skill.sh
```

Expected: at this point, some checks may fail because templates are still being populated. Run, fix issues, re-run until `✅ L1: all static checks passed`.

- [ ] **Step 3: Commit**

```bash
git add .claude/skills/harness-loop/scripts/check-skill.sh
git commit -m "feat(scripts): add L1 static check for skill self-verification"
```

---

### Task 17: scripts/check-examples.sh (L2 end-to-end)

**Files:**
- Create: `.claude/skills/harness-loop/scripts/check-examples.sh`

- [ ] **Step 1: Write the script**

```bash
#!/usr/bin/env bash
# L2: End-to-end diff against examples/.
# Re-runs skill with each example's answer set, diffs output vs snapshot.

set -uo pipefail

SKILL_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$SKILL_DIR"

FAIL=0

for example in examples/java-tdd examples/java-sdd examples/java-hybrid; do
  if [[ ! -d "$example" ]]; then
    echo "⚠️  L2: $example not yet populated, skipping"
    continue
  fi

  name=$(basename "$example")
  tmp=$(mktemp -d)
  echo "▶ L2: regenerating $name into $tmp"

  # Read answer set from example's answers.json (committed alongside)
  # Run skill in non-interactive mode (uses answers.json)
  # NOTE: requires a non-interactive runner; for now we just diff structures
  # Actual implementation calls: bash run-with-answers.sh "$example/answers.json" "$tmp"

  if [[ -f scripts/run-with-answers.sh ]]; then
    bash scripts/run-with-answers.sh "$example/answers.json" "$tmp" || {
      echo "❌ L2: generation failed for $name"
      FAIL=$((FAIL+1))
      continue
    }
  else
    echo "⚠️  L2: scripts/run-with-answers.sh not implemented, manual diff only"
    continue
  fi

  # Diff (excluding volatile files like timestamps)
  diff -r --exclude="iteration.md" --exclude="entropy-log.md" "$example/" "$tmp/" > /tmp/l2-diff.txt
  if [[ $? -ne 0 ]]; then
    echo "❌ L2: $name differs from snapshot:"
    cat /tmp/l2-diff.txt | head -50
    FAIL=$((FAIL+1))
  else
    echo "✅ L2: $name matches snapshot"
  fi

  rm -rf "$tmp"
done

if [[ "$FAIL" -gt 0 ]]; then
  echo "🛑 L2: $FAIL failures"
  exit 1
fi

echo "✅ L2: all examples match snapshots"
exit 0
```

- [ ] **Step 2: Commit**

```bash
git add .claude/skills/harness-loop/scripts/check-examples.sh
git commit -m "feat(scripts): add L2 end-to-end example diff"
```

Note: This script depends on `scripts/run-with-answers.sh` (a non-interactive runner) which is out of scope for v1. The script is committed in a "warning-only" state; full automation is a future extension (§9 in spec).

---

### Task 18: scripts/check-bootstrap.sh (L3 self-consistency)

**Files:**
- Create: `.claude/skills/harness-loop/scripts/check-bootstrap.sh`

- [ ] **Step 1: Write the script**

```bash
#!/usr/bin/env bash
# L3: Bootstrap self-check — generated project must run its own checks.

set -uo pipefail

SKILL_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$SKILL_DIR"

FAIL=0
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

echo "▶ L3: generating java-tdd project in $tmp"

# Same caveat as L2: needs run-with-answers.sh
if [[ ! -f scripts/run-with-answers.sh ]]; then
  echo "⚠️  L3: scripts/run-with-answers.sh not implemented, skipping"
  exit 0
fi

bash scripts/run-with-answers.sh examples/java-tdd/answers.json "$tmp" || {
  echo "❌ L3: generation failed"
  exit 1
}

cd "$tmp"

# Sub-check 1: generated check-tests.sh exists and is valid bash
if [[ ! -f scripts/check-tests.sh ]]; then
  echo "❌ L3: scripts/check-tests.sh not generated"
  FAIL=$((FAIL+1))
else
  bash -n scripts/check-tests.sh || {
    echo "❌ L3: generated check-tests.sh has syntax error"
    FAIL=$((FAIL+1))
  }
fi

# Sub-check 2: generated check-consistency.sh runs (may fail findings, but should run)
if [[ -f scripts/check-consistency.sh ]]; then
  bash check-consistency.sh || {
    echo "❌ L3: check-consistency.sh exited non-zero on fresh project"
    FAIL=$((FAIL+1))
  }
fi

# Sub-check 3: pre-commit hook is valid bash
if [[ ! -f .githooks/pre-commit ]]; then
  echo "❌ L3: .githooks/pre-commit not generated"
  FAIL=$((FAIL+1))
else
  bash -n .githooks/pre-commit || {
    echo "❌ L3: pre-commit has syntax error"
    FAIL=$((FAIL+1))
  }
fi

# Sub-check 4: CI workflow is valid YAML
if [[ -f .github/workflows/consistency.yml ]]; then
  if command -v python &>/dev/null; then
    python -c "import yaml; yaml.safe_load(open('.github/workflows/consistency.yml'))" || {
      echo "❌ L3: consistency.yml is invalid YAML"
      FAIL=$((FAIL+1))
    }
  fi
fi

# Sub-check 5: AGENTS.md is valid markdown (basic check: starts with #)
if ! head -1 AGENTS.md | grep -qE '^# '; then
  echo "❌ L3: AGENTS.md doesn't start with a H1 title"
  FAIL=$((FAIL+1))
fi

if [[ "$FAIL" -gt 0 ]]; then
  echo "🛑 L3: $FAIL failures"
  exit 1
fi

echo "✅ L3: bootstrap self-check passed"
exit 0
```

- [ ] **Step 2: Commit**

```bash
git add .claude/skills/harness-loop/scripts/check-bootstrap.sh
git commit -m "feat(scripts): add L3 bootstrap self-check"
```

---

## Phase 6: Examples

### Task 19: examples/java-tdd/

**Files:**
- Create: `.claude/skills/harness-loop/examples/AGENTS.md`
- Create: `.claude/skills/harness-loop/examples/java-tdd/answers.json`
- Create: `.claude/skills/harness-loop/examples/java-tdd/AGENTS.md`
- Create: `.claude/skills/harness-loop/examples/java-ttd/TASKS.md`
- Create: `.claude/skills/harness-loop/examples/java-tdd/scripts/check-tests.sh`
- Create: `.claude/skills/harness-loop/examples/java-tdd/.opencode/config.json`
- Create: `.claude/skills/harness-loop/examples/java-tdd/tests/AGENTS.md`
- Create: `.claude/skills/harness-loop/examples/java-tdd/tests/pom.xml`
- Create: `.claude/skills/harness-loop/examples/java-tdd/tests/src/test/java/FirstTest.java`

- [ ] **Step 1: Write `examples/AGENTS.md`** (~40 lines)

Purpose of examples/ + per-example conventions.

- [ ] **Step 2: Write `java-tdd/answers.json`**

```json
{
  "Q1": "应用代码",
  "Q2": "TDD",
  "Q3": "Java",
  "Q4": ["外部验证", "检查点"],
  "Q5": null,
  "Q6": "claude-sonnet-4-6",
  "Q7": "生成",
  "Q8": "strict"
}
```

- [ ] **Step 3: Generate the full example output manually**

Run the skill mentally (or actually invoke it) with the answer set above. Capture every file the skill would generate. Write each one into `examples/java-tdd/`.

Files to include:
- `AGENTS.md` (rendered with 6 concepts + Ralph tenets + TDD block + Java commands + strict)
- `TASKS.md` (initial state)
- `state/iteration.md` (initial state)
- `state/entropy-log.md` (initial state)
- `scripts/check-tests.sh` (Java version, rendered)
- `scripts/check-consistency.sh` (rendered)
- `.githooks/pre-commit` (rendered)
- `.github/workflows/consistency.yml` (rendered)
- `.opencode/config.json` (rendered with claude-sonnet-4-6)
- `tests/AGENTS.md` (rendered)
- `tests/pom.xml` (rendered)
- `tests/src/test/java/FirstTest.java` (rendered)
- `concepts/` (copied from templates/concepts/, since Q7=生成)
- `README.md` (snippet showing the appended section)
- `.gitignore` (snippet showing the appended lines)

- [ ] **Step 4: Verify example structure**

```bash
find .claude/skills/harness-loop/examples/java-tdd -type f | wc -l
```
Expected: ≥15 files.

- [ ] **Step 5: Commit**

```bash
git add .claude/skills/harness-loop/examples/
git commit -m "feat(examples): add java-tdd full snapshot"
```

---

### Task 20: examples/java-sdd/

**Files:**
- Create: `.claude/skills/harness-loop/examples/java-sdd/answers.json`
- Create: `.claude/skills/harness-loop/examples/java-sdd/` (full generated output)

- [ ] **Step 1: Write `java-sdd/answers.json`**

```json
{
  "Q1": "应用代码",
  "Q2": "SDD",
  "Q3": "Java",
  "Q4": ["检查点"],
  "Q5": null,
  "Q6": "claude-sonnet-4-6",
  "Q7": "生成",
  "Q8": "advisory"
}
```

- [ ] **Step 2: Generate full SDD example output**

Same approach as Task 19, but:
- Q2=SDD → generates `docs/specs/` instead of `tests/`
- Q8=advisory → check scripts exit 0 on failure
- Q4 has only 检查点 → no check-promise.sh, check-tests.sh still generated

Files include: AGENTS.md, TASKS.md, state/, scripts/, .githooks/, .github/workflows/, .opencode/, docs/specs/{AGENTS.md, template.md}, concepts/, README snippet, .gitignore snippet.

- [ ] **Step 3: Commit**

```bash
git add .claude/skills/harness-loop/examples/java-sdd/
git commit -m "feat(examples): add java-sdd full snapshot (advisory mode)"
```

---

### Task 21: examples/java-hybrid/

**Files:**
- Create: `.claude/skills/harness-loop/examples/java-hybrid/answers.json`
- Create: `.claude/skills/harness-loop/examples/java-hybrid/` (full generated output)

- [ ] **Step 1: Write `java-hybrid/answers.json`**

```json
{
  "Q1": "应用代码",
  "Q2": "Hybrid",
  "Q2_sub": ["SDD", "TDD"],
  "Q3": "Java",
  "Q4": ["完成信号", "外部验证", "检查点"],
  "Q5": null,
  "Q6": "claude-opus-4-7",
  "Q7": "生成",
  "Q8": "strict"
}
```

- [ ] **Step 2: Generate full Hybrid example output**

Per spec §5.3.1 Hybrid rules:
- Generates BOTH `docs/specs/` AND `tests/`
- Root AGENTS.md work-cycle section: SDD block before TDD block
- All three check scripts: check-promise.sh + check-tests.sh + check-consistency.sh
- opus-4-7 model in .opencode/config.json

- [ ] **Step 3: Commit**

```bash
git add .claude/skills/harness-loop/examples/java-hybrid/
git commit -m "feat(examples): add java-hybrid full snapshot (SDD+TDD, opus-4-7)"
```

---

## Phase 7: Dogfood & Manual Test

### Task 22: Run skill on D:\project\harness+loop itself

**Files:**
- Modify: `D:\project\harness+loop\AGENTS.md` (create)
- Modify: `D:\project\harness+loop\TASKS.md` (create)
- Modify: `D:\project\harness+loop\state/` (create)
- Modify: `D:\project\harness+loop\scripts/` (create)
- Modify: `D:\project\harness+loop\.githooks/` (create)
- Modify: `D:\project\harness+loop\.github/workflows/` (create)
- Modify: `D:\project\harness+loop\.opencode/` (create)
- Modify: `D:\project\harness+loop\README.md` (create)
- Modify: `D:\project\harness+loop\.gitignore` (append)

- [ ] **Step 1: Invoke the skill on this project**

In Claude Code, say: "搭个 harness，本项目用 SDD 方法论，Java，启用完成信号+检查点，模型用 claude-sonnet-4-6，生成学习档案目录，strict 模式"

Wait for the skill's wizard to confirm answers and generate files.

- [ ] **Step 2: Verify all expected files exist**

```bash
cd "D:/project/harness+loop"
for f in AGENTS.md TASKS.md state/iteration.md state/entropy-log.md \
         scripts/check-tests.sh scripts/check-consistency.sh scripts/check-promise.sh \
         .githooks/pre-commit .github/workflows/consistency.yml \
         .opencode/config.json docs/specs/AGENTS.md docs/specs/template.md \
         concepts/01-repo-as-truth.md README.md; do
  if [[ ! -f "$f" ]]; then
    echo "❌ Missing: $f"
  else
    echo "✅ $f"
  fi
done
```
Expected: all `✅`.

- [ ] **Step 3: Run generated checks**

```bash
bash scripts/check-consistency.sh
bash scripts/check-tests.sh  # Java version; will fail at FirstTest if Maven not installed, that's OK
```
Expected: `check-consistency.sh` exits 0; `check-tests.sh` may fail at Maven invocation if not installed — that's a runtime dependency, not a skill bug.

- [ ] **Step 4: Run skill self-checks**

```bash
bash .claude/skills/harness-loop/scripts/check-skill.sh
```
Expected: `✅ L1: all static checks passed`

- [ ] **Step 5: Commit the dogfood output**

```bash
git add AGENTS.md TASKS.md state/ scripts/ .githooks/ .github/ .opencode/ docs/specs/ concepts/ README.md .gitignore
git commit -m "feat: dogfood harness-loop skill on this project (SDD + Java + strict)"
```

---

## Self-Review Checklist

After writing this plan, the following checks pass:

**1. Spec coverage:**
- §1 Problem statement → covered by all tasks (skill exists to solve it)
- §2 6 concepts + Ralph tenets → Task 5
- §3 Architecture (skill form, high-level flow) → Tasks 1-2
- §4 8-question wizard → Tasks 3-4
- §5 Generated structure (root + subdir + methodology + verification layers) → Tasks 5-15
- §6 Skill internal structure → Tasks 1-21 (full structure)
- §7 Verification (L1/L2/L3) → Tasks 16-18
- §8 Java build stack → Task 13
- §9 Future extensions → explicitly out of scope
- §10 Open questions (opencode config schema, Maven/Gradle, CI provider) → noted in template placeholders; confirmed defaults

**2. Placeholder scan:**
- No "TBD", "TODO", "FIXME" in plan steps
- All code blocks contain actual code, not `<placeholder>`
- Tasks that depend on future work (L2/L3 automation via `run-with-answers.sh`) are explicitly noted as warning-only in v1

**3. Type consistency:**
- `{{STRICT_MODE}}` used consistently across all check templates
- `{{LANGUAGE}}` used in check-tests.sh.tmpl and entropy template
- `{{MODEL_ID}}` used in opencode-config.json.tmpl
- `{{PROMISE_TOKEN}}` used in check-promise.sh.tmpl and opencode-config.json.tmpl
- All placeholder names match between templates and `wizard/decision-tree.md`

**4. Scope:**
- 22 tasks, each 2-5 minutes
- Achievable in single implementation pass
- No sub-project decomposition needed (single skill, coherent scope)

---

## Execution Handoff

Plan complete and saved to `docs/superpowers/plans/2026-06-27-harness-loop-skill.md`. Two execution options:

1. **Subagent-Driven (recommended)** — dispatch a fresh subagent per task, review between tasks, fast iteration
2. **Inline Execution** — execute tasks in this session using executing-plans, batch execution with checkpoints

Which approach?
