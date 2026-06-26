# Harness-Loop Skill 设计文档

- **日期**：2026-06-27
- **状态**：Draft（待用户审阅）
- **作者**：Claude（经与用户交互式 brainstorming 产出）
- **落地路径**：`<project>/.claude/skills/harness-loop/`

---

## 1. 问题陈述

### 1.1 背景

工程师用 opencode（开源 AI 编码 agent）跑长任务时，常遇到：
- agent 行为飘忽，不符合项目约定
- 长任务跑着跑着偏离目标，没有可机械验证的"完成"判定
- 项目约束散落在 Slack / 文档 / 脑子里，对 agent 不可见
- 没有渐进式加载机制，AGENTS.md 越写越胖，挤占 agent 上下文

### 1.2 目标

构建一个 **项目级 skill `harness-loop`**，通过交互式向导在任意项目里快速生成一套**对齐 harness-engineering 范式**的约束系统：

- **产出**：`AGENTS.md`（地图式入口）+ 子目录级 `AGENTS.md` + 机械化检查脚本 + 配套骨架文件
- **运行时**：复用 opencode 已有能力，**不重新实现 LLM 循环**
- **方法论模板**：TDD / SDD / BDD / DDD / RDD / Plain / Hybrid，按需注入
- **核心范式**：地图而非手册、机械化执行、仓库即真相、熵管理（对齐 deusyu/harness-engineering）

### 1.3 非目标

- ❌ 不写 SDK 直调的 agent harness 代码
- ❌ 不写包装 opencode CLI 的 bash loop
- ❌ 不实现 Stop hook 模式（ralph-loop 插件已覆盖）
- ❌ 不内嵌 LLM 调用逻辑
- ❌ 不打包为 marketplace plugin
- ❌ 不做 i18n（中文为主，术语保留英文）

---

## 2. 设计原则

来自 harness-engineering 的 6 大概念 + Ralph 6 信条，全部默认注入根 AGENTS.md：

### 2.1 6 大概念

| # | 概念 | 一句话 |
|---|---|---|
| 1 | 仓库即记录系统 | 不在仓库里的东西，对 agent 不存在 |
| 2 | 地图而非手册 | AGENTS.md 是 ~100 行的入口索引，不是百科 |
| 3 | 机械化执行 | 文档会腐烂，lint 规则不会 |
| 4 | 智能体可读性 | 优先为 agent 推理能力优化 |
| 5 | 吞吐量改变合并理念 | 纠错成本低，等待成本高 |
| 6 | 熵管理 = 垃圾回收 | 技术债是高息贷款 |

### 2.2 Ralph 6 信条

| 信条 | 映射 |
|---|---|
| Fresh Context Is Reliability | 每轮迭代重新读仓库 |
| Backpressure Over Prescription | 不规定怎么做，但门控拒绝坏结果 |
| The Plan Is Disposable | 重新生成的成本只是 planning loop |
| Disk Is State, Git Is Memory | 文件是交接机制 |
| Steer With Signals, Not Scripts | 加路标，不加脚本 |
| Let Ralph Ralph | 坐在循环上，不坐在循环里 |

---

## 3. 架构总览

### 3.1 Skill 形态

- **位置**：`<project>/.claude/skills/harness-loop/`（项目级）
- **形态**：交互式向导 + 内嵌模板，零外部依赖
- **触发条件**（SKILL.md description）：用户表达"搭 harness"、"建 loop"、"让任务自动跑"、"约束 agent 行为"等意图时

### 3.2 高层流程

```
用户说"搭个 harness" → skill 触发
  → AskUserQuestion × 8（任务/方法论/语言/验证/卡死阈值/模型/学习档案/严格度）
  → 读 wizard/decision-tree.md 把答案转模板路径
  → 渐进式加载用到的模板片段
  → 拼装 + Write 到项目目录
  → 打印配置摘要 + 等待 Y/n 确认
```

### 3.3 核心约束

- **不替用户做决策**：所有运行时/验证机制由向导问出来
- **生成产物可直接运行**：用户跑 `./scripts/check-tests.sh` 就能验证
- **Windows-friendly**：脚本默认 bash（Git Bash on Windows），避免 PowerShell 强依赖
- **幂等**：重跑向导会覆盖规则文件，保留 `TASKS.md` / `state/` / 用户自定义段

---

## 4. 向导问题流

skill 触发后用 8 个 AskUserQuestion 收集决策。前 4 题必问，后 4 题按答案动态出现。

### Q1. 项目类型

决定 AGENTS.md 使命段 + 默认检查栈。

- A. **应用代码项目**（src/tests，跑 test+lint+typecheck）—— 默认 C1-C6 全开
- B. **库 / SDK 项目**（对外暴露 API）—— 强开 C1/C2/C5
- C. **文档 / 学习档案项目** —— 强开 C1/C2/C5/C6，跳过 C3
- D. **混合型** —— 全开，分层配置

### Q2. 方法论

决定注入哪个工作循环到 AGENTS.md + 配套目录。

- A. **TDD** → `tests/` + 失败测试样例
- B. **SDD** → `docs/specs/` + spec 模板
- C. **BDD** → `features/` + Gherkin 样例
- D. **DDD** → `docs/domain/` + 通用语言词汇表
- E. **RDD** → `docs/readme-first.md`
- F. **Plain** → 无方法论目录
- G. **Hybrid** → 见 §5.3 的 Hybrid 组合规则（不是 multiSelect，而是一个元选项）

### Q3. 项目语言/技术栈

决定 C3 测试命令和 lint 工具。

- A. Python（`pytest` + `ruff` + `mypy`）
- B. Node.js / TypeScript（`vitest`/`jest` + `eslint` + `tsc`）
- C. Go（`go test` + `golangci-lint` + `gofmt`）
- **D. Java（Maven + JUnit 5 + Checkstyle）** ← 推荐默认
- E. 多语言（按子目录配置）
- F. 非代码项目（跳过 C3）

> Rust / Kotlin / C# 等语言暂不支持，见 §9 后续扩展。

### Q4. 验证机制（multiSelect，至少一个）

- A. **完成信号** → `check-promise.sh` + AGENTS.md 段落
- B. **外部验证** → `check-tests.sh`（命令来自 Q3）
- C. **检查点** → `check-consistency.sh` + `.githooks/pre-commit` + `.github/workflows/consistency.yml`
- D. **熵扫描** → `check-entropy.sh` + `state/entropy-log.md`
- E. **卡死检测** → `check-stuck.sh`（对比 `state/iteration.md` 进展字段）

### Q5. 卡死阈值

仅当 Q4 选了 E 才问。

- "连续多少轮无进展后终止？" 默认 3 轮

### Q6. opencode 模型 ID

- 自由文本输入模型 ID（推荐 `claude-sonnet-4-6`），写入 `.opencode/config.json`

### Q7. 学习档案（可选）

- A. **生成**：把 6 大概念笔记模板复制到 `concepts/`，本项目也成为可学习档案
- B. **不生成**：只产出工程相关文件

### Q8. 严格程度

- **strict**（默认）：任何检查失败 exit 1，阻断 commit/merge
- **advisory**：只警告 exit 0

### 配置摘要 + 确认

所有问题答完后，skill 打印一行摘要：

```
📋 即将生成：
  • AGENTS.md（地图式入口，~100 行，TDD + 6 大概念 + Ralph 信条）
  • scripts/check-tests.sh / check-promise.sh / check-stuck.sh
  • .githooks/pre-commit + .github/workflows/consistency.yml
  • tests/（Java：JUnit 5 + Maven 样例）+ tests/AGENTS.md
  • .opencode/config.json（claude-sonnet-4-6）
  • TASKS.md / state/iteration.md / state/entropy-log.md
  • README.md 追加 "How AI works on this repo" 段
  • .gitignore 追加 state/transcript* 等
继续？(Y/n)
```

用户确认后才开始写文件。

---

## 5. 生成内容结构

### 5.1 根层（所有配置都生成）

```
<project>/
├── AGENTS.md                       # ~100 行：项目导航 + 6 大概念 + Ralph 信条 + 子目录索引
├── TASKS.md                        # 任务看板（每轮更新）
├── state/
│   ├── iteration.md                # 当前轮次 / 上次进展 / 阻塞点
│   └── entropy-log.md              # 熵日志：累积偏差 + 质量评分
├── scripts/
│   ├── AGENTS.md                   # 脚本用途说明
│   ├── check-consistency.sh        # C1/C2/C6 数量 + 引用一致性
│   ├── check-tests.sh              # C3 test + lint + typecheck
│   ├── check-promise.sh            # C4 完成信号（可选）
│   ├── check-entropy.sh            # C5 熵扫描（可选）
│   └── check-stuck.sh              # 卡死检测（可选）
├── .githooks/
│   └── pre-commit                  # 本地 hook
├── .github/workflows/
│   └── consistency.yml             # CI 兜底
├── .opencode/
│   └── config.json                 # opencode 项目配置
├── README.md                       # 已存在则追加段，不存在则创建
└── .gitignore                      # 追加 state/transcript* 等
```

### 5.2 根 AGENTS.md 布局（~100 行）

```
1. 项目使命（1-3 行）
2. 6 大概念声明（各 1 行）
3. Ralph 6 信条（各 1 行）
4. 子目录索引（指向每个子目录的 AGENTS.md）
5. 机械化检查入口（指向 scripts/check-*.sh）
6. 工作循环（来自 Q2 方法论模板）
7. 当前活跃任务（指向 TASKS.md）
8. 严格度声明（strict / advisory）
```

### 5.3 方法论层（按 Q2 选择生成）

| 方法论 | 生成的目录 | 内容 |
|---|---|---|
| TDD | `tests/` + `tests/AGENTS.md` | 失败测试样例（按 Q3 语言） |
| SDD | `docs/specs/` + `docs/specs/AGENTS.md` + `template.md` | spec 写作规范 |
| BDD | `features/` + `features/AGENTS.md` + `example.feature` | Gherkin 样例 |
| DDD | `docs/domain/` + `docs/domain/AGENTS.md` + `ubiquitous-language.md` | 通用语言词汇表 |
| RDD | `docs/readme-first.md` | 先写 README 的方法说明 |
| Plain | 无方法论目录 | AGENTS.md 只放项目约定 |
| Hybrid | 多个方法论目录叠加 | 见 §5.3.1 Hybrid 组合规则 |

#### 5.3.1 Hybrid 组合规则

当 Q2 选 Hybrid 时，skill 让用户在 Q2 后追加一题（多选）："勾选要叠加的方法论"。组合规则：

1. **目录共存**：每个被选中的方法论都生成自己的目录（如 SDD+TDD → `docs/specs/` + `tests/`）
2. **AGENTS.md 段落顺序**：根 AGENTS.md 的"工作循环"段按"先 spec / 后实现"排序（SDD 类先于 TDD 类）
3. **冲突解决原则**：当两个方法论的规则冲突时（如 SDD 说"先写 spec 才能写代码"，RDD 说"先写 README"），按以下优先级：
   - SDD > TDD > BDD > DDD > RDD
   - 理由：越靠近"做什么"的越优先于"怎么做"
4. **方法论间引用**：根 AGENTS.md 显式声明组合关系，例如"SDD 产出 spec 后，TDD 接管实现"

### 5.4 验证层（按 Q4 选择叠加）

每个机制对应一个 `scripts/check-*.sh` 脚本。所有检查脚本统一行为：

- **strict 模式**：失败 exit 1，阻断 commit/merge
- **advisory 模式**：失败 exit 0，仅 stderr 警告
- **lint 报错内嵌修复指令**（harness-engineering 核心要求）：

```
❌ C1 不一致：README 声明"12 篇翻译"，但 works/*-translation.md 只有 11 个
   修复：检查 works/ 下哪个文件缺了，或在 README 里更新计数为 11
```

### 5.5 文件之间的引用关系

```
AGENTS.md
  ├─ 指向 → scripts/check-*.sh
  ├─ 指向 → TASKS.md
  ├─ 指向 → state/iteration.md
  ├─ 引用 → docs/specs/ 或 tests/（按方法论）
  └─ 声明 → 完成信号、卡死阈值、迭代上限、严格度

.opencode/config.json
  └─ 指向 → AGENTS.md

README.md "How AI works on this repo" 段
  └─ 解释 → AGENTS.md / TASKS.md / scripts/ 的存在
```

### 5.6 幂等性约束

重跑向导时：

- **覆盖**：`AGENTS.md`、`scripts/*.sh`、`.opencode/config.json`、方法论目录的 `AGENTS.md`
- **保留**：`TASKS.md`、`state/iteration.md`、`README.md` 的非生成段、`.gitignore` 的非生成行
- **首次生成时**：检测到同名文件存在就先备份成 `.bak`，再覆盖

---

## 6. Skill 内部结构

skill 自身也遵守"地图而非手册"——SKILL.md 是入口索引，不堆实现细节。

### 6.1 目录布局

```
.claude/skills/harness-loop/
├── SKILL.md                           # 入口：description + 触发条件 + 流程索引
├── README.md                          # skill 文档（怎么用、怎么扩展）
├── AGENTS.md                          # skill 自身的 AGENTS.md（dogfood）
│
├── wizard/                            # 向导逻辑
│   ├── AGENTS.md
│   ├── questions.md                   # 8 个问题的完整脚本
│   ├── decision-tree.md               # 答案 → 模板路径映射
│   └── summary-format.md              # 配置摘要格式
│
├── templates/                         # 渐进式加载的模板库
│   ├── AGENTS.md
│   ├── agents-root.md.tmpl            # 根 AGENTS.md 拼装壳
│   ├── agents-subdir.md.tmpl          # 子目录 AGENTS.md 拼装壳
│   ├── ralph-tenets.md                # Ralph 6 信条段
│   ├── strict-mode.md                 # strict vs advisory 行为说明
│   │
│   ├── methodologies/
│   │   ├── AGENTS.md
│   │   ├── tdd.md
│   │   ├── sdd.md
│   │   ├── bdd.md
│   │   ├── ddd.md
│   │   ├── rdd.md
│   │   └── plain.md
│   │
│   ├── concepts/                      # 6 大概念段
│   │   ├── AGENTS.md
│   │   ├── 01-repo-as-truth.md
│   │   ├── 02-map-not-manual.md
│   │   ├── 03-mechanical-enforcement.md
│   │   ├── 04-agent-readability.md
│   │   ├── 05-throughput-merges.md
│   │   └── 06-entropy-gc.md
│   │
│   ├── checks/                        # 检查脚本模板
│   │   ├── AGENTS.md
│   │   ├── check-consistency.sh.tmpl
│   │   ├── check-tests.sh.tmpl
│   │   ├── check-promise.sh.tmpl
│   │   ├── check-entropy.sh.tmpl
│   │   ├── check-stuck.sh.tmpl
│   │   ├── pre-commit.tmpl
│   │   └── consistency.yml.tmpl
│   │
│   └── scaffolding/                   # 配套骨架
│       ├── AGENTS.md
│       ├── tasks-md.tmpl
│       ├── state-iteration.tmpl
│       ├── state-entropy.tmpl
│       ├── gitignore.tmpl
│       ├── readme-section.tmpl
│       ├── opencode-config.json.tmpl
│       └── methodology-dirs/
│           ├── tests-python/
│           │   ├── AGENTS.md
│           │   └── test_first.template.py
│           ├── tests-node/
│           │   ├── AGENTS.md
│           │   └── first-test.template.ts
│           ├── tests-go/
│           │   ├── AGENTS.md
│           │   └── first_test.template.go
│           ├── tests-java/
│           │   ├── AGENTS.md
│           │   ├── pom.xml.tmpl
│           │   └── src/test/java/FirstTest.java.tmpl
│           ├── specs/                 # SDD
│           │   ├── AGENTS.md
│           │   └── template.md
│           ├── features/              # BDD
│           │   ├── AGENTS.md
│           │   └── example.feature
│           ├── domain/                # DDD
│           │   ├── AGENTS.md
│           │   └── ubiquitous-language.md
│           └── readme-first/          # RDD
│               └── readme-first.md
│
├── scripts/                           # skill 自身的校验脚本
│   ├── check-skill.sh                 # L1 静态校验
│   ├── check-examples.sh              # L2 端到端 diff
│   └── check-bootstrap.sh             # L3 自洽校验
│
└── examples/                          # 端到端示例（Java 统一）
    ├── AGENTS.md
    ├── java-tdd/
    ├── java-sdd/
    └── java-hybrid/
```

### 6.2 SKILL.md 的 ~100 行结构

```markdown
---
name: harness-loop
description: <触发条件>
---

# Harness-Loop Skill

## 何时触发
<触发关键词列表>

## 向导流程
本 skill 通过 8 个 AskUserQuestion 收集决策，按答案加载模板生成项目约束。
完整问题脚本见 wizard/questions.md，决策树见 wizard/decision-tree.md。

## 渐进式加载原则
- 只读用户选中的方法论模板，未选的不加载
- 检查脚本按 Q4 (multiSelect) 加载
- 6 大概念 + Ralph 信条默认全注入根 AGENTS.md

## 8 步流程
1. 读 wizard/questions.md 按序问 8 题
2. 读 wizard/decision-tree.md 把答案转模板路径
3. 读用到的每个模板，按 strict-mode.md 决定 exit code 行为
4. 拼装根 AGENTS.md（agents-root.md.tmpl + 注入段）
5. 写子目录 AGENTS.md（按 Q2 方法论）
6. 写 scripts/ + .githooks/ + .github/workflows/
7. 写配套文件（TASKS.md / state/ / .opencode/ / README 段 / .gitignore）
8. 打印 wizard/summary-format.md 的摘要 + 等待 Y/n 确认

## 模板索引
- 方法论模板：templates/methodologies/AGENTS.md
- 概念模板：templates/concepts/AGENTS.md
- 检查脚本：templates/checks/AGENTS.md
- 配套骨架：templates/scaffolding/AGENTS.md

## 扩展指南
新增方法论 / 新增检查层 / 新增语言支持 → 见 README.md 的"扩展"段

## 反模式（不要做）
- 不要把所有规则写进 SKILL.md（违反"地图而非手册"）
- 不要在 skill 里硬编码模型名 / 命令（用模板）
- 不要生成用户没选的检查脚本
```

### 6.3 关键设计决策

1. **SKILL.md 不直接写模板内容**：所有模板片段在 `templates/` 下独立维护，SKILL.md 只描述"怎么用"。避免"巨型指令文件三死因"。
2. **每个 templates/ 子目录有自己的 AGENTS.md**：解释该子目录的写作约定。
3. **`examples/` 是端到端测试基线**：skill 自我验证时比对生成结果和 examples/。
4. **wizard/ 和 templates/ 分离**：wizard 是"逻辑"，templates 是"内容"。改问题流不动模板，改模板不动问题流。
5. **skill dogfood 自身**：`.claude/skills/harness-loop/AGENTS.md` 让 opencode 改进 skill 时也走同一套约束。

---

## 7. 验证方案

### 7.1 L1 静态校验（`scripts/check-skill.sh`）

skill 加载时跑：

- **S1**: SKILL.md frontmatter 合法（`name`/`description` 字段存在且非空）
- **S2**: `wizard/decision-tree.md` 里引用的所有模板路径实际存在
- **S3**: `templates/` 下每个 `*.tmpl` 文件都用 `{{...}}` 占位符且都被 decision-tree 引用过
- **S4**: 每个子目录的 AGENTS.md 存在且不超过 100 行（自我约束）

### 7.2 L2 端到端示例（`scripts/check-examples.sh`）

三个完整示例作为基线快照，全部 Java：

| 示例 | Q1 | Q2 | Q3 | Q4 | Q6 | Q7 | Q8 |
|---|---|---|---|---|---|---|---|
| `java-tdd` | 应用 | TDD | Java | B,C | sonnet-4-6 | 生成 | strict |
| `java-sdd` | 应用 | SDD | Java | C | sonnet-4-6 | 生成 | advisory |
| `java-hybrid` | 应用 | SDD+TDD | Java | A,B,C | opus-4-7 | 生成 | strict |

校验脚本：

1. 跑 skill 在临时目录里以示例答案生成产物
2. diff 临时产物 vs `examples/<name>/`
3. 任何差异报错并打印 unified diff

设计理由：三个示例同语言、不同方法论，聚焦对比方法论差异而非语言差异。

### 7.3 L3 生成产物自洽（`scripts/check-bootstrap.sh`）

最严苛的校验：**生成的项目本身要能跑它自己的检查**。

1. 在临时目录跑 skill 生成 `java-tdd` 配置的项目骨架
2. 进入临时项目，运行 `scripts/check-tests.sh`（应该能 exit 非零 = 脚本能跑）
3. 运行 `scripts/check-consistency.sh`（应该 exit 0，新项目 state/iteration.md 字段齐全）
4. 验证 `.githooks/pre-commit` 和 `.github/workflows/consistency.yml` 是合法 bash / YAML

### 7.4 完成标准

skill 自身开发的"完成"标准（也是 writing-plans 实现时的验收门槛）：

- [ ] L1 通过：所有模板路径一致，frontmatter 合法
- [ ] L2 通过：3 个 Java 示例 diff 全零
- [ ] L3 通过：生成的项目能跑自己的 check 脚本
- [ ] 手动跑一遍：在 `D:\project\harness+loop` 这个空项目里实跑 skill，得到一份可用的 AGENTS.md + 配套
- [ ] README.md 写完：skill 的使用说明 + 扩展指南

---

## 8. Java 构建栈细节

由于示例统一用 Java，明确以下默认：

| 维度 | 选择 | 备注 |
|---|---|---|
| 构建工具 | Maven | `pom.xml`，若用户主诉 Gradle 可换 |
| 测试框架 | JUnit 5 | `org.junit.jupiter:junit-jupiter` |
| Mock | Mockito | `org.mockito:mockito-core` |
| Lint | Checkstyle | `mvn checkstyle:check` |
| 编译 | `mvn compile` | 作为 typecheck 替代 |
| 项目布局 | Maven Standard | `src/main/java/`, `src/test/java/` |

`check-tests.sh`（Java 版）的默认命令：

```bash
mvn -q test
mvn -q checkstyle:check
mvn -q compile
```

---

## 9. 后续可扩展（不在本次范围）

- 新方法论模板：Type-Driven、Contract-Driven、Property-Based
- 新语言支持：Rust、Kotlin、Scala、C#、Ruby
- 用户级 skill 副本：跨项目复用时再讨论
- Gradle 支持：若用户主诉，新增 `gradle/` 子目录模板
- Marketplace plugin 打包：如果要发布到 opencode 社区

---

## 10. 开放问题

实现阶段需要确认：

1. **opencode 的 config.json schema**：当前假设支持 `model` / `tools` / `contextWindow` 字段。实现时需查 opencode 文档确认实际字段名。
2. **opencode 是否支持子目录 AGENTS.md 自动加载**：当前设计假设支持（类似 Claude Code 的 CLAUDE.md inheritance）。若不支持，需要降级为根 AGENTS.md 包含所有规则。
3. **Maven vs Gradle**：当前默认 Maven。若主要用户群体偏好 Gradle，需要切换或支持双模板。
4. **CI provider**：当前默认 GitHub Actions（`.github/workflows/`）。若主要用 GitLab CI / Jenkins，需要新增模板。

---

## 11. 参考资料

- [deusyu/harness-engineering](https://github.com/deusyu/harness-engineering) — 中文学习档案，本 skill 主要参考
- OpenAI《Harness Engineering: Harnessing Codex in an Agent-First World》（2026-02）— 范式原始来源，URL 实现时填入
- [snarktank/ralph](https://github.com/snarktank/ralph) — Ralph 循环原版
- [ralph-orchestrator](https://github.com/mikeyobrien/ralph-orchestrator) — Rust 进化版
- Claude Code 的 `loop` 内置 skill 和 `ralph-loop` plugin — 本仓库环境内已有的相关实现

---

## 附录 A：术语表

| 术语 | 含义 |
|---|---|
| Harness | 围绕 LLM 的执行环境与约束系统（不限于代码） |
| Loop | agent 在一个任务上反复迭代直到完成的运行模式 |
| AGENTS.md | opencode 读的项目级指令文件（等价于 Claude Code 的 CLAUDE.md） |
| 机械化检查 | 自定义 lint + 结构测试，agent 可自我纠正 |
| 渐进式披露 | 入口文件薄，深层细节按需加载 |
| 熵管理 | 周期性扫描偏差、发起重构 PR 的后台任务 |
| 完成信号 | LLM 输出特定 token（如 `<promise>DONE</promise>`）表示任务完成 |
| 卡死检测 | 连续 K 轮无进展即提前终止 |
