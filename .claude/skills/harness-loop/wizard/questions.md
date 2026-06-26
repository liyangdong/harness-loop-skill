# wizard/questions.md — the 8-question AskUserQuestion script

> This file is the standalone script for the harness-loop wizard. Read top to bottom,
> execute Q1→Q8 in order. Each block contains everything needed to call AskUserQuestion
> (or to handle the free-text variants Q5/Q6). Answers feed `decision-tree.md`.
>
> Parallel calls allowed for independent questions per SKILL.md step 1; the dependency
> notes below state exactly when one question gates another.

---

## Q1: 项目类型 (project_type)

**AskUserQuestion call:**
- question: "这个项目是什么类型？决定 AGENTS.md 使命段和默认检查栈。"
- header: "项目类型"
- multiSelect: false
- options:
  - label: "应用代码项目", description: "src/tests 结构，跑 test + lint + typecheck。默认 C1-C6 全开。"
  - label: "库 / SDK 项目", description: "对外暴露 API。强开 C1/C2/C5（一致性 / 完成信号 / 熵扫描）。"
  - label: "文档 / 学习档案项目", description: "以内容产出为主。强开 C1/C2/C5/C6，跳过 C3 测试层。"
  - label: "混合型", description: "应用代码 + 文档并存。全开，分层配置各子目录。"
- recommended default: "应用代码项目"

**Dependencies:** always asked (Q1 is the entry question)
**Branch:** affects which check layers are on by default; downstream Q3 may recommend 非代码 when project_type = 文档 / 学习档案

---

## Q2: 方法论 (methodology)

**AskUserQuestion call:**
- question: "采用哪种开发方法论？决定注入到 AGENTS.md 的工作循环和配套目录。"
- header: "方法论"
- multiSelect: false
- options:
  - label: "TDD", description: "测试驱动。生成 tests/ + 失败测试样例（语言来自 Q3）。"
  - label: "SDD", description: "Spec 驱动。生成 docs/specs/ + spec 模板。"
  - label: "BDD", description: "行为驱动。生成 features/ + Gherkin 样例。"
  - label: "DDD", description: "领域驱动。生成 docs/domain/ + 通用语言词汇表。"
  - label: "RDD", description: "README 驱动。生成 docs/readme-first.md。"
  - label: "Plain", description: "无方法论目录。AGENTS.md 只放项目约定。"
  - label: "Hybrid", description: "多方法论叠加。选后会追加一题让用户勾选要组合的方法论（见 decision-tree.md §Hybrid）。"
- recommended default: "TDD"

**Dependencies:** always asked
**Branch:** when answer = Hybrid, immediately follow up with a multi-select question asking which of {TDD, SDD, BDD, DDD, RDD} to combine; combination rules and AGENTS.md ordering live in decision-tree.md (§5.3.1 of the spec)

---

## Q3: 项目语言/技术栈 (language)

**AskUserQuestion call:**
- question: "项目用什么语言/技术栈？决定 C3 测试命令和 lint 工具。"
- header: "技术栈"
- multiSelect: false
- options:
  - label: "Python", description: "pytest + ruff + mypy。"
  - label: "Node.js / TypeScript", description: "vitest 或 jest + eslint + tsc。"
  - label: "Go", description: "go test + golangci-lint + gofmt。"
  - label: "Java", description: "Maven + JUnit 5 + Checkstyle + Mockito。默认推荐。"
  - label: "多语言", description: "按子目录分别配置测试命令。"
  - label: "非代码项目", description: "跳过 C3 测试层。适用于纯文档 / 学习档案。"
- recommended default: "Java"

**Dependencies:** always asked; if Q1 = 文档 / 学习档案项目, recommend highlighting 非代码项目 here
**Branch:** answer drives `check-tests.sh` template selection (templates/scaffolding/methodology-dirs/tests-<lang>/); 非代码 → no tests directory generated. Note: Rust / Kotlin / Scala / C# / Ruby are not yet supported — see spec §9.

---

## Q4: 验证机制 (verification_mechanisms)

**AskUserQuestion call:**
- question: "启用哪些验证机制？可多选，至少选一个。每个机制对应一个 scripts/check-*.sh。"
- header: "验证机制"
- multiSelect: true
- options:
  - label: "完成信号", description: "check-promise.sh：检测 LLM 输出 <promise>DONE</promise> token。AGENTS.md 增加完成声明段。"
  - label: "外部验证", description: "check-tests.sh：跑 Q3 决定的 test + lint + typecheck 命令。"
  - label: "检查点", description: "check-consistency.sh + .githooks/pre-commit + .github/workflows/consistency.yml。本地 + CI 双重门控。"
  - label: "熵扫描", description: "check-entropy.sh + state/entropy-log.md。周期性扫描累积偏差。"
  - label: "卡死检测", description: "check-stuck.sh：对比 state/iteration.md 进展字段，连续 K 轮无进展即终止。会触发 Q5。"
- recommended default: ["完成信号", "外部验证", "检查点"]

**Dependencies:** always asked; multiSelect requires at least one option
**Branch:** if 卡死检测 ∈ selected, proceed to Q5; otherwise skip Q5 and use default stuck threshold of 3 (informational only, no check-stuck.sh generated unless 卡死检测 was selected)

---

## Q5: 卡死阈值 (stuck_threshold)

> Free-text input. AskUserQuestion does not have a native free-text mode, so we present
> common defaults as options plus an "Other (custom)" escape hatch. If the user picks
> Other, follow up with a plain text reply request and use the parsed integer.

**AskUserQuestion call:**
- question: "连续多少轮无进展后终止任务？（卡死阈值，仅当 Q4 选了卡死检测才问）"
- header: "卡死阈值"
- multiSelect: false
- options:
  - label: "2 轮", description: "激进。适合短迭代、高成本任务。"
  - label: "3 轮", description: "默认推荐。平衡误判与成本。"
  - label: "5 轮", description: "保守。适合需要多轮探索的复杂任务。"
  - label: "Other (custom)", description: "输入自定义整数（用户回复一个数字，Claude 解析后写入 check-stuck.sh）。"
- recommended default: "3 轮"

**Dependencies:** ONLY asked if Q4 includes 卡死检测. Otherwise skip entirely and do not generate check-stuck.sh.
**Branch:** the chosen integer is baked into `scripts/check-stuck.sh` as the comparison threshold against state/iteration.md's progress field

---

## Q6: opencode 模型 ID (model_id)

> Free-text input. Same options-plus-Other pattern as Q5. The user can paste any
> opencode-supported model ID; we surface the common ones for convenience.

**AskUserQuestion call:**
- question: "opencode 用哪个模型？模型 ID 会写入 .opencode/config.json。"
- header: "模型 ID"
- multiSelect: false
- options:
  - label: "claude-sonnet-4-6", description: "默认推荐。平衡能力与成本，适合大多数 harness 任务。"
  - label: "claude-opus-4-7", description: "最强推理。适合复杂架构 / Hybrid 方法论。"
  - label: "claude-haiku-4-5", description: "最快最便宜。适合轻量 lint 类任务。"
  - label: "Other (custom)", description: "输入自定义模型 ID（用户回复字符串，Claude 原样写入 config.json）。"
- recommended default: "claude-sonnet-4-6"

**Dependencies:** always asked
**Branch:** the chosen string is written verbatim to .opencode/config.json's model field; no further branching

---

## Q7: 学习档案 (learning_archive)

**AskUserQuestion call:**
- question: "是否生成本项目的学习档案？会把 6 大概念笔记模板复制到 concepts/，让本项目也成为可被 agent 学习的档案。"
- header: "学习档案"
- multiSelect: false
- options:
  - label: "生成", description: "复制 templates/concepts/ 下 6 大概念笔记到项目 concepts/。本项目成为可学习档案。"
  - label: "不生成", description: "只产出工程相关文件（AGENTS.md / scripts / state 等），不复制 concepts/。"
- recommended default: "生成"

**Dependencies:** always asked
**Branch:** 生成 → create concepts/ directory with 6 concept notes; 不生成 → skip concepts/ entirely

---

## Q8: 严格程度 (strictness)

**AskUserQuestion call:**
- question: "检查脚本失败时的行为？strict 会阻断 commit/merge，advisory 只警告。"
- header: "严格度"
- multiSelect: false
- options:
  - label: "strict", description: "任何 check-*.sh 失败 exit 1，阻断 commit 和 merge。默认推荐，最大化机械化约束。"
  - label: "advisory", description: "失败 exit 0，仅 stderr 警告。适合试运行期或不想阻断流程的项目。"
- recommended default: "strict"

**Dependencies:** always asked; this is the final question
**Branch:** answer is passed to templates/strict-mode.md and controls exit codes of every generated check-*.sh; advisory mode also relaxes .githooks/pre-commit to warn-only

---

## Post-question step

After Q8 is answered, render `wizard/summary-format.md` with all 8 answers and print the
configuration summary. Wait for explicit `Y` confirmation before writing any files
(SKILL.md step 8). On `n` or abort, discard all collected answers and exit cleanly.
