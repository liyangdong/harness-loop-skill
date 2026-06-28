# 在任意项目里使用 harness-loop skill

这份指南面向**用 AI agent 跑长任务、想给项目加一层约束系统**的工程师。读完你能：

- 用 harness-loop skill 在自己项目里生成完整的 AGENTS.md + 检查脚本 + 脚手架
- 让任意 agents.md 兼容的 agent（Claude Code、opencode、Codex CLI、Cursor、Gemini CLI 等）在约束下自主迭代
- 知道每天怎么用、卡住了怎么自救

---

## 1. 它解决什么问题

默认情况下 agent 行为很灵活，但灵活 = 不可预测：

- agent 凭直觉改代码，常常不跑测试就提交
- 项目约定散在 Slack / Notion / 老员工脑子里，agent 看不到
- 长任务跑到第 5 轮已经偏离目标，没人发现
- AGENTS.md 越写越胖，挤占 agent 上下文

**harness-loop skill** 通过 7 题向导生成一整套约束系统，把上面这些问题钉死：

- 三种 AGENTS.md 布局可选（map-mode / knowledge-map / quick-nav）
- 机械化检查 C1-C7（数量一致 / 引用对齐 / 测试通过 / 完成信号 / 熵扫描 / 子目录约定 / 分层架构）
- 双重门控（本地 pre-commit + CI workflow 多门控管线）
- 完成信号 / 检查点 / 卡死检测（防止无限循环）

约束一旦落地，**任何读 AGENTS.md 的 agent 都会在轨道里跑**。

---

## 2. 前置条件

| 必需 | 验证命令 | 备注 |
|---|---|---|
| Claude Code（用来跑 skill 向导） | `claude --version` | 唯一硬依赖 |
| 任意 agents.md 兼容 agent（运行时） | — | Claude Code / opencode / Codex CLI / Cursor / Gemini CLI 等都行 |
| Git | `git --version` | |
| Bash | `bash --version` | Git Bash on Windows 即可 |
| 项目对应的工具链（如果选了"外部验证"） | 视语言而定 | Java→Maven、Python→pytest、Node→vitest、Go→go test |

> **为什么 Claude Code 是硬依赖，但运行时 agent 可选？**
> harness-loop skill 是 **Claude Code 的 skill**（用 Markdown + 模板写的向导）。它生成的约束系统**任何 agents.md 兼容工具都能读**。
>
> 工作流：用 Claude Code 跑一次 skill 生成约束 → 用你喜欢的 agent 跑日常长任务。

---

## 3. 快速开始（5 分钟）

### 3.1 把 skill 装到你的项目

如果是从 GitHub clone 的本仓库：

```bash
cd /path/to/your-project
cp -r /path/to/harness-loop-skill/.claude/skills/harness-loop .claude/skills/
```

新项目：

```bash
mkdir my-project && cd my-project
git init
cp -r /path/to/harness-loop-skill/.claude/skills/harness-loop .claude/skills/
```

### 3.2 触发 skill

在项目根目录启动 Claude Code，输入任一触发词：

```
搭个 harness
建 loop
约束 agent 行为
生成 AGENTS.md
```

Claude 会读 `.claude/skills/harness-loop/SKILL.md`，启动 7 题向导。

### 3.3 走完 7 题向导

每题都给推荐默认。下面是一个 Java + TDD 项目的典型回答：

| Q | 问题 | 推荐答 |
|---|---|---|
| Q1 | 项目类型？ | 应用代码 |
| Q2 | 方法论？ | TDD |
| Q3 | 语言？ | Java（Maven + JUnit 5） |
| Q4 | 验证机制？（多选） | 外部验证 + 检查点 + 架构约束 |
| Q5 | 卡死阈值？ | 3（仅当 Q4 选了卡死检测才问） |
| Q6 | 学习档案目录？ | 生成 |
| Q7 | 严格度？ | strict |

向导答完后会打印配置摘要 + 即将创建的文件清单，等你按 `Y` 确认。

### 3.4 启用 pre-commit hook

```bash
git config core.hooksPath .githooks
```

从这一刻起，任何违反约束的 commit 都会被 pre-commit 拦截。

### 3.5 启动 agent

用任何 agents.md 兼容的 agent：

```bash
# Claude Code
claude

# 或 opencode
opencode

# 或 Codex CLI
codex
```

agent 会自动读 `AGENTS.md`，进入约束循环：

1. 读根 `AGENTS.md`（项目使命 + 工作循环 + 子目录索引）
2. 看 `TASKS.md` 找当前子任务
3. 进入相关子目录时按需加载该目录的 `AGENTS.md`
4. 提交时 pre-commit 拦截非零退出的检查
5. 完成后输出 `<promise>DONE</promise>` 触发完成信号

---

## 4. 7 题向导详解

### Q1：项目类型

| 选项 | 默认检查栈 | 适用场景 |
|---|---|---|
| 应用代码 | C1-C7 全开 | 有 src/tests 的标准项目 |
| 库 / SDK | 强开 C1/C2/C5 | 对外暴露 API，强调版本和文档 |
| 文档 / 学习档案 | 强开 C1/C2/C5/C6，跳 C3 | 文档为主的项目 |
| 混合型 | 全开，分层配置 | 应用 + 文档共存 |

### Q2：方法论

| 方法论 | 工作循环 | 配套目录 |
|---|---|---|
| TDD | 红-绿-重构 | `tests/`（按 Q3 语言） |
| SDD | spec → 实现 | `docs/specs/` |
| BDD | Gherkin 场景先行 | `features/` |
| DDD | 普适语言 + 建模 | `docs/domain/` |
| RDD | README 先行 | `docs/readme-first.md` |
| Plain | 无强制方法论 | （无） |
| Hybrid | 多选叠加 | 多个目录共存（按优先级 SDD>TDD>BDD>DDD>RDD） |

### Q3：语言

决定 `check-tests.sh` 里的测试/lint/类型检查命令：

- **Python**：`pytest tests/` + `ruff check .` + `mypy src/`
- **Node**：`vitest run` + `eslint .` + `tsc --noEmit`
- **Go**：`go test ./...` + `golangci-lint run` + `gofmt -l .`
- **Java**（推荐）：`mvn -q test` + `mvn -q checkstyle:check` + `mvn -q compile`
- **多语言**：按子目录检测
- **非代码**：跳过 C3

### Q4：验证机制（多选，至少一个）

| 选项 | 生成的脚本 | 干什么 |
|---|---|---|
| 完成信号 | `check-promise.sh` | grep `<promise>DONE</promise>` 标记完成 |
| 外部验证 | `check-tests.sh` | 跑测试 / lint / typecheck |
| 检查点 | `check-consistency.sh` + pre-commit + CI | 仓库一致性 + 双重门控 |
| 熵扫描 | `check-entropy.sh` | 检测 TODO 累积、大文件、重复声明 |
| 卡死检测 | `check-stuck.sh` | 对比最近 K 轮 state，无进展则终止 |
| 架构约束 | `check-architecture.sh` | 分层依赖方向检查（advisory 模式） |

### Q5：卡死阈值

只有 Q4 选了"卡死检测"才问。默认 3 轮——连续 3 轮 `state/iteration.md` 的 `progress_signature` 字段无变化，loop 终止。

### Q6：学习档案目录

- **生成**：把 6 大概念笔记复制到 `concepts/`，项目也成为可学习档案
- **不生成**：只产出工程相关文件

### Q7：严格度

- **strict**（默认）：任何检查失败 exit 1，pre-commit 阻断 commit，CI 阻断 merge
- **advisory**：检查失败仅 stderr 警告，exit 0，不阻断

新项目用 strict；老项目首次接入用 advisory，等清理完再切 strict。

---

## 5. 三种 AGENTS.md 布局

通过 `answers.json` 里的 `PROJECT_LAYOUT` 字段切换（不在向导里，按需配置）：

| 布局 | 风格 | 适合 |
|---|---|---|
| **A** (默认，map-mode) | 6 大概念 + Ralph 信条 + 子目录索引 | skill / 学习档案 / 文档项目 |
| **B** (knowledge-map) | 项目简介 + 技术栈 + 项目结构图 + 知识地图导航 + 条约 + 约束 + loop | 应用 / 库项目（中文社区主流） |
| **C** (quick-nav) | 极简根 + 快速导航表 + 硬性规则 + 详细 docs/ 结构 | 生产代码库 + 团队协作 |

**布局 A**（map-mode）的 AGENTS.md：
```
# ProjectName
mission one-liner
## 6 大概念
## Ralph 信条
## 工作循环
## 子目录索引
## 机械化检查
## 当前任务
## 严格度
```

**布局 B**（knowledge-map，来自 AGENTS-referrence.md）：
```
# ProjectName
项目简介
技术栈
项目结构图
知识地图导航
  架构
  条约（开发规范 / 门禁检查规范 / 安全规范 / 测试规范 [单元/集成/E2E]）
  工具知识（通用工具 / 外部集成）
  功能知识（功能模块 / 知识和代码索引）
约束限制
loop
```

**布局 C**（quick-nav，来自 cnblogs 最佳实践）：
```
# ProjectName
## 项目简介
## 快速导航
| 你想做什么 | 去哪里看 |
|---|---|
| 了解系统架构 | docs/architecture/overview.md |
| 了解编码规范 | docs/conventions/README.md |
...
## 硬性规则（必须遵守，CI 会验证）
## 提交规范
```
配套生成完整 `docs/` 结构（architecture/conventions/design/plans/reference）。

---

## 6. 生成了什么

以 Java + TDD + strict + 布局 C 为例：

```
your-project/
├── AGENTS.md                       # 极简入口 + 快速导航 + 硬性规则
├── TASKS.md                        # 任务看板
├── README.md                       # 追加 "How AI works" 段
├── .gitignore                      # 追加 harness-loop 段
├── state/
│   ├── iteration.md                # 当前轮次 / 上次进展 / 阻塞点
│   ├── entropy-log.md              # 熵日志（Q4 选了熵扫描）
│   └── AGENTS.md
├── scripts/
│   ├── check-tests.sh              # 跑 mvn test + checkstyle + compile
│   ├── check-consistency.sh        # C1/C2/C6 一致性
│   ├── check-architecture.sh       # C7 分层架构（Q4 选了架构约束）
│   └── AGENTS.md
├── .githooks/
│   └── pre-commit                  # 本地门控
├── .github/workflows/
│   └── consistency.yml             # CI 多门控（type-check / lint / tests / coverage / architecture / file-size / consistency / doc-freshness）
├── docs/                           # 布局 C 才有完整结构
│   ├── AGENTS.md
│   ├── phase-roadmap.md            # 3 阶段落地路线
│   ├── architecture/{overview,boundaries,data-flow}.md
│   ├── conventions/{README,naming,error-handling,testing,logging}.md
│   ├── design/feature-template.md  # 带 Status 字段
│   ├── plans/{current-sprint,backlog}.md
│   └── specs/                      # 仅 SDD/Hybrid
├── tests/                          # 仅 TDD/Hybrid
│   ├── AGENTS.md
│   ├── pom.xml
│   └── src/test/java/FirstTest.java
└── concepts/                       # 仅 Q6=生成
    └── 01-06*.md + AGENTS.md
```

---

## 7. 日常工作流

### 7.1 拆解任务

打开 `TASKS.md`，把当前 epic 拆成 3-7 个可检查的子任务：

```markdown
## Current epic
实现用户登录功能

## Subtasks
- [ ] 写 User.login() 的失败测试
- [ ] 实现密码哈希校验
- [ ] 写 JWT 签发逻辑
- [ ] 集成测试：登录 → 拿 token → 访问受保护路由
```

### 7.2 启动 agent loop

```bash
# 任选一个 agents.md 兼容 agent
claude  # 或 opencode / codex / cursor
```

agent 会：

1. 读 `AGENTS.md` 知道用 TDD + Java + strict
2. 读 `TASKS.md` 找第一个未完成的子任务
3. 进入 `tests/`，加载 `tests/AGENTS.md` 知道测试约定
4. 写失败测试 → 跑 `mvn test` 看它失败 → 写最小实现 → 再跑看它通过
5. 通过后更新 `state/iteration.md` 的 `progress_signature` 字段（防卡死检测）
6. 提交时 pre-commit 跑 `check-tests.sh` + `check-consistency.sh`，全绿才允许 commit
7. 子任务全部完成后，输出 `<promise>DONE</promise>` 触发完成信号

### 7.3 监督而不是微管理

**Ralph 信条**："坐在循环上，不坐在循环里。"

- ✅ 看 `state/iteration.md` 知道当前在第几轮、上次进展是什么
- ✅ 看 git log 知道 agent 改了什么
- ✅ 看 PR review 知道代码质量
- ❌ 不要每分钟打断 agent 问"需要帮忙吗"
- ❌ 不要替 agent 写代码——让它写完再 review

### 7.4 卡住时怎么办

如果 `check-stuck.sh` 报"连续 3 轮无进展"：

1. 看 `state/iteration.md` 的 Blockers 段——agent 应该已经写下阻塞点
2. 看 git log——agent 在改什么？
3. 决策：
   - **任务不可达成** → 在 `TASKS.md` 把子任务移到 Blocked
   - **思路错了** → 修改 `TASKS.md` 描述，让 agent 重读
   - **环境问题** → 自己解决，让 agent 继续
   - **agent 跑偏** → 强制终止，回滚到上一个绿测试的 commit，重启 loop

### 7.5 完成判定

完成信号机制：

- 所有子任务在 `TASKS.md` 标记 `[x]`
- 所有 `check-*.sh` 通过（exit 0）
- agent 在最后一轮输出 `<promise>DONE</promise>`
- `check-promise.sh` 检测到信号，loop 正常退出

---

## 8. 修改 / 扩展

### 8.1 重跑向导

任何时候都可以重新触发 skill（说"重搭 harness"）。重跑时：

- **覆盖**：`AGENTS.md`、所有 `scripts/*.sh`、方法论目录的 `AGENTS.md`
- **保留**：`TASKS.md`（任务清单）、`state/iteration.md`（运行历史）、`README.md` 的非生成段
- **首次覆盖前**：检测到同名文件存在会备份成 `.bak`

### 8.2 切换 AGENTS.md 布局

在 `answers.json` 加 `PROJECT_LAYOUT` 字段（A/B/C），重跑 `scripts/run-with-answers.sh`。

### 8.3 切换 strict / advisory

不需要重跑向导。直接编辑每个 `scripts/check-*.sh` 顶部的 `STRICT="strict"` 改成 `STRICT="advisory"`。

更优雅：把 `STRICT` 改成读环境变量：
```bash
STRICT="${HARNESS_LOOP_STRICT_MODE:-strict}"
```
然后 `HARNESS_LOOP_STRICT_MODE=advisory git commit ...` 临时绕过。

### 8.4 加新方法论 / 检查层 / 语言

见 `.claude/skills/harness-loop/README.md` 的"Extension Guide"。

---

## 9. 故障排查

### 9.1 pre-commit 不触发

```bash
git config --get core.hooksPath     # 应输出 .githooks
git config core.hooksPath .githooks  # 设置
chmod +x .githooks/pre-commit        # 确保 hook 可执行
```

### 9.2 check-tests.sh 报 "command not found"

`mvn` / `pytest` / `vitest` / `go` 不在 PATH。先手动验证 `mvn -version` 等。

### 9.3 agent 没读 AGENTS.md

- 确认 AGENTS.md 在项目根（不在子目录）
- Claude Code、opencode、Codex CLI、Cursor 等默认读项目根的 AGENTS.md / CLAUDE.md
- 如果是其他 agent，查它的文档关于 instruction file 的配置

### 9.4 check-architecture.sh advisory 模式警告过多

分层架构检查默认 advisory。如果是新接入项目，预期会有违规——这是设计如此，让你看到现状。等清理完后可改 `scripts/check-architecture.sh` 顶部的 `ARCH_STRICT` 字段。

### 9.5 Windows 上 bash 脚本报错

确保用 Git Bash（不是 WSL bash，也不是 cmd）：
```bash
echo $SHELL  # /usr/bin/bash 或类似
which bash   # Git 安装目录下的 bin/bash.exe
```

### 9.6 L2 / L3 显示 "warning-only"

需要 `scripts/run-with-answers.sh` 已实现。本仓库 v0.1.0 之后都有：
```bash
ls .claude/skills/harness-loop/scripts/run-with-answers.sh
bash .claude/skills/harness-loop/scripts/check-examples.sh
```

---

## 10. 命令速查

```bash
# 触发 skill（在 Claude Code 里）
搭个 harness

# 启用 pre-commit hook（一次性）
git config core.hooksPath .githooks

# 手动跑检查
bash scripts/check-tests.sh
bash scripts/check-consistency.sh
bash scripts/check-architecture.sh     # 仅当 Q4 选了架构约束
bash scripts/check-promise.sh state/last-output.txt
bash scripts/check-entropy.sh
bash scripts/check-stuck.sh

# 跑 skill 自身的 L1/L2/L3 验证
bash .claude/skills/harness-loop/scripts/check-skill.sh
bash .claude/skills/harness-loop/scripts/check-examples.sh
bash .claude/skills/harness-loop/scripts/check-bootstrap.sh

# 非交互式生成（用于 CI 或脚本）
bash .claude/skills/harness-loop/scripts/run-with-answers.sh answers.json /tmp/output

# 启动 agent（任选）
claude  # 或 opencode / codex / cursor

# 临时绕过 pre-commit（不推荐）
git commit --no-verify -m "..."
```

---

## 11. 设计哲学（给深度读者）

这套约束系统对齐 [deusyu/harness-engineering](https://github.com/deusyu/harness-engineering) 总结的 6 大概念和 [snarktank/ralph](https://github.com/snarktank/ralph) 的 6 条信条。

### 6 大概念

1. **仓库即记录系统** —— 不在仓库的东西对 agent 不存在
2. **地图而非手册** —— AGENTS.md 是入口索引，不是百科全书
3. **机械化执行** —— 文档会腐烂，lint 规则不会
4. **智能体可读性** —— 选"无聊"技术，方便 agent 推理
5. **吞吐量改变合并理念** —— 纠错成本低，等待成本高
6. **熵管理 = 垃圾回收** —— 技术债是高息贷款

### Ralph 6 信条

| 信条 | 在本系统的体现 |
|---|---|
| Fresh Context Is Reliability | agent 不依赖会话内存，所有状态写文件 |
| Backpressure Over Prescription | `check-*.sh` 拒绝非零退出，但不指挥修复 |
| The Plan Is Disposable | 失败尝试可丢弃，`state/` 是真相 |
| Disk Is State, Git Is Memory | `TASKS.md` + `state/iteration.md` 持久化进度 |
| Steer With Signals, Not Scripts | `AGENTS.md` 描述目标，不写命令序列 |
| Let Ralph Ralph | 用户监督而非微管理 |

### 3 阶段落地路线（见 `docs/phase-roadmap.md`）

```
Phase 1: 信息层（1-2 天）
  - AGENTS.md 地图模式 / 知识地图 / 快速导航（任选布局）
  - docs/ 结构化目录
  - 设计文档模板

Phase 2: 约束层（3-5 天）
  - 分层架构 lint
  - CI 多门控管线
  - 错误信息含修复指令（❌/✅/📖 或 ASCII 等价）

Phase 3: 自动化层（1-2 周，可选）
  - Git worktree 隔离验证
  - 后台清理 agent
  - 可观测性堆栈
```

---

## 12. 下一步

- **看示例**：`.claude/skills/harness-loop/examples/java-tdd/` 是完整生成结果，可以直接当参考
- **看设计**：`docs/superpowers/specs/2026-06-27-harness-loop-skill-design.md` 是完整 spec
- **看代码**：`.claude/skills/harness-loop/templates/` 是所有模板的源
- **看落地路线**：`docs/phase-roadmap.md` 解释 3 阶段渐进式接入
- **提 issue**：[github.com/liyangdong/harness-loop-skill/issues](https://github.com/liyangdong/harness-loop-skill/issues)

祝你跑得开心，agent 在轨道里干活。
