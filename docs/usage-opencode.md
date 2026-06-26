# 在 opencode 项目里使用 harness-loop skill

这份指南面向**用 opencode 跑长任务、想给项目加一层约束系统**的工程师。读完你能：

- 用 harness-loop skill 在自己项目里生成完整的 AGENTS.md + 检查脚本 + 脚手架
- 让 opencode 在生成的约束下自主迭代直到任务完成
- 知道每天怎么用、卡住了怎么自救

---

## 1. 它解决什么问题

opencode 默认行为很灵活，但灵活 = 不可预测：

- agent 凭直觉改代码，常常不跑测试就提交
- 项目约定散在 Slack / Notion / 老员工脑子里，agent 看不到
- 长任务跑到第 5 轮已经偏离目标，没人发现
- AGENTS.md 越写越胖，挤占 agent 上下文

**harness-loop skill** 通过 8 题向导生成一整套约束系统，把上面这些问题钉死：

- 地图式 AGENTS.md（~100 行入口 + 子目录渐进式披露）
- 机械化检查（C1-C6：数量一致 / 引用对齐 / 测试通过 / 完成信号 / 熵扫描 / 子目录约定）
- 双重门控（本地 pre-commit + CI workflow）
- 完成信号 / 检查点 / 卡死检测（防止无限循环）

约束一旦落地，**opencode 读 AGENTS.md 后就会在轨道里跑**。

---

## 2. 前置条件

| 必需 | 版本 | 验证命令 |
|---|---|---|
| opencode | ≥ 0.x | `opencode --version` |
| Claude Code（用来跑 skill） | 任意 | `claude --version` |
| Git | 任意 | `git --version` |
| Bash | 任意 | `bash --version` |
| Java + Maven（如果用 Java 示例） | JDK 21+ / Maven 3.8+ | `mvn -version` |

> **为什么需要两个 agent 工具？**
> harness-loop skill 是 **Claude Code 的 skill**（用 Markdown + 模板写的向导）。它生成的约束系统**任何 agents.md 兼容工具都能读**——包括 opencode。
>
> 工作流：用 Claude Code 跑一次 skill 生成约束 → 切到 opencode 跑日常长任务。

---

## 3. 快速开始（5 分钟）

### 3.1 把 skill 装到你的项目

如果你的项目已有 `.claude/skills/` 目录，直接复制：

```bash
cd /path/to/your/project
cp -r /path/to/harness-loop-skill/.claude/skills/harness-loop .claude/skills/
```

如果是新项目：

```bash
mkdir my-project && cd my-project
git init
# 把 skill 复制进来
cp -r /path/to/harness-loop-skill/.claude/skills/harness-loop .claude/skills/
```

### 3.2 触发 skill

在项目根目录启动 Claude Code，输入任一触发词：

```
搭个 harness
建 loop
约束 agent 行为
生成 AGENTS.md
设置 opencode 约束
```

Claude 会读 `.claude/skills/harness-loop/SKILL.md`，启动 8 题向导。

### 3.3 走完 8 题向导

每题都给推荐默认（第一项）。下面是一个 Java + TDD 项目的典型回答：

| Q | 问题 | 推荐答 |
|---|---|---|
| Q1 | 项目类型？ | 应用代码 |
| Q2 | 方法论？ | TDD |
| Q3 | 语言？ | Java（Maven + JUnit 5） |
| Q4 | 验证机制？（多选） | 外部验证 + 检查点 |
| Q5 | 卡死阈值？ | 3（仅在 Q4 选了卡死检测才问） |
| Q6 | opencode 模型 ID？ | `claude-sonnet-4-6` |
| Q7 | 生成学习档案目录？ | 生成 |
| Q8 | 严格度？ | strict |

向导答完后会打印配置摘要 + 即将创建的文件清单，等你按 `Y` 确认。

### 3.4 启用 pre-commit hook

```bash
git config core.hooksPath .githooks
```

从这一刻起，任何违反约束的 commit 都会被 pre-commit 拦截。

### 3.5 启动 opencode

```bash
opencode
```

opencode 会自动读 `AGENTS.md` + `.opencode/config.json`，进入约束循环：

1. 读根 `AGENTS.md`（项目使命 + 6 大概念 + Ralph 信条 + 工作循环）
2. 看 `TASKS.md` 找当前子任务
3. 进入相关子目录时按需加载该目录的 `AGENTS.md`
4. 提交时 pre-commit 拦截非零退出的检查
5. 完成后输出 `<promise>DONE</promise>` 触发完成信号

---

## 4. 8 题向导详解

### Q1：项目类型

| 选项 | 默认检查栈 | 适用场景 |
|---|---|---|
| 应用代码 | C1-C6 全开 | 有 src/tests 的标准项目 |
| 库 / SDK | 强开 C1/C2/C5 | 对外暴露 API，强调版本和文档 |
| 文档 / 学习档案 | 强开 C1/C2/C5/C6，跳 C3 | 类似本仓库这种文档为主的项目 |
| 混合型 | 全开，分层配置 | 应用 + 文档共存 |

### Q2：方法论

决定根 `AGENTS.md` 的"工作循环"段 + 配套目录：

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
| 检查点 | `check-consistency.sh` + `.githooks/pre-commit` + `.github/workflows/consistency.yml` | 仓库一致性 + 双重门控 |
| 熵扫描 | `check-entropy.sh` | 检测 TODO 累积、大文件、重复声明 |
| 卡死检测 | `check-stuck.sh` | 对比最近 K 轮 state，无进展则终止 |

### Q5：卡死阈值

只有 Q4 选了"卡死检测"才问。默认 3 轮——连续 3 轮 `state/iteration.md` 的 `progress_signature` 字段无变化，loop 终止。

### Q6：opencode 模型 ID

自由文本。常见选项：

- `claude-sonnet-4-6`（推荐默认，平衡能力和成本）
- `claude-haiku-4-5`（省钱，简单任务够用）
- `claude-opus-4-7`（重型任务，1M 上下文）
- 任何 opencode 支持的其他模型 ID

写入 `.opencode/config.json` 的 `model` 字段。

### Q7：学习档案目录

- **生成**：把 harness-engineering 的 6 大概念笔记复制到 `concepts/`，项目也成为可学习档案
- **不生成**：只产出工程相关文件，`concepts/` 不创建

### Q8：严格度

- **strict**（默认）：任何检查失败 exit 1，pre-commit 阻断 commit，CI 阻断 merge
- **advisory**：检查失败仅 stderr 警告，exit 0，不阻断

新项目用 strict；老项目首次接入用 advisory，等清理完再切 strict。

---

## 5. 生成了什么

以 Java + TDD + strict 为例，生成后的项目结构：

```
your-project/
├── AGENTS.md                       # ~100 行地图式入口
├── TASKS.md                        # 任务看板
├── README.md                       # 追加 "How AI works" 段
├── .gitignore                      # 追加 harness-loop 段
├── state/
│   ├── iteration.md                # 当前轮次 / 上次进展 / 阻塞点
│   ├── entropy-log.md              # 熵日志
│   └── AGENTS.md                   # state/ 目录的局部约定
├── scripts/
│   ├── check-tests.sh              # 跑 mvn test + checkstyle + compile
│   ├── check-consistency.sh        # C1/C2/C6 一致性
│   └── AGENTS.md                   # scripts/ 目录的局部约定
├── .githooks/
│   └── pre-commit                  # 本地门控
├── .github/workflows/
│   └── consistency.yml             # CI 门控
├── .opencode/
│   └── config.json                 # opencode 项目配置
├── docs/
│   ├── AGENTS.md                   # docs/ 目录的局部约定
│   └── specs/                      # （仅 SDD/Hybrid 才有）
├── tests/                          # （仅 TDD/Hybrid 才有）
│   ├── AGENTS.md
│   ├── pom.xml
│   └── src/test/java/FirstTest.java
├── concepts/                       # （仅 Q7=生成 才有）
│   ├── AGENTS.md
│   ├── 01-repo-as-truth.md
│   ├── 02-map-not-manual.md
│   ├── 03-mechanical-enforcement.md
│   ├── 04-agent-readability.md
│   ├── 05-throughput-merges.md
│   └── 06-entropy-gc.md
```

**关键文件分工**：

| 文件 | 谁读 | 干什么 |
|---|---|---|
| `AGENTS.md`（根） | opencode 启动时 | 项目使命 + 工作循环 + 子目录索引 |
| 子目录 `AGENTS.md` | opencode 进入子目录时 | 局部规则（渐进式披露） |
| `TASKS.md` | opencode 每轮 | 当前子任务清单 |
| `state/iteration.md` | opencode 每轮 | 持久化进度（卡死检测也读这个） |
| `scripts/check-*.sh` | pre-commit + CI | 机械化验证 |
| `.opencode/config.json` | opencode 启动时 | 模型 + 工具白名单 + loop 配置 |

---

## 6. 日常工作流（用 opencode）

### 6.1 拆解任务

打开 `TASKS.md`，把当前要做的 epic 拆成 3-7 个可检查的子任务：

```markdown
## Current epic

实现用户登录功能

## Subtasks

- [ ] 写 User.login() 的失败测试
- [ ] 实现密码哈希校验
- [ ] 写 JWT 签发逻辑
- [ ] 集成测试：登录 → 拿 token → 访问受保护路由
```

提交这个 `TASKS.md`。

### 6.2 启动 opencode loop

```bash
opencode
```

opencode 会：

1. 读 `AGENTS.md` 知道用 TDD + Java + strict
2. 读 `TASKS.md` 找第一个未完成的子任务
3. 进入 `tests/`，加载 `tests/AGENTS.md` 知道测试约定
4. 写失败测试 → 跑 `mvn test` 看它失败 → 写最小实现 → 再跑看它通过
5. 通过后把 `state/iteration.md` 的 `progress_signature` 字段更新（防卡死检测）
6. 提交时 pre-commit 跑 `check-tests.sh` + `check-consistency.sh`，全绿才允许 commit
7. 子任务全部完成后，输出 `<promise>DONE</promise>` 触发完成信号

### 6.3 监督而不是微管理

**Ralph 信条**："坐在循环上，不坐在循环里。"

- ✅ 看 `state/iteration.md` 知道当前在第几轮、上次进展是什么
- ✅ 看 git log 知道 agent 改了什么
- ✅ 看 PR review 知道代码质量
- ❌ 不要每分钟打断 agent 问"需要帮忙吗"
- ❌ 不要替 agent 写代码——让它写完再 review

### 6.4 卡住时怎么办

如果 `check-stuck.sh` 报"连续 3 轮无进展"：

1. 看 `state/iteration.md` 的 Blockers 段——agent 应该已经写下阻塞点
2. 看 git log——agent 在改什么？
3. 决策：
   - **任务不可达成** → 在 `TASKS.md` 把子任务移到 Blocked，添加新可达成子任务
   - **思路错了** → 修改 `TASKS.md` 描述，让 agent 重读
   - **环境问题**（依赖装不上、API 不通）→ 自己解决，然后让 agent 继续
   - **agent 跑偏** → 强制终止，回滚到上一个绿测试的 commit，重启 loop

### 6.5 完成判定

完成信号机制：

- 所有子任务在 `TASKS.md` 标记 `[x]`
- 所有 `check-*.sh` 通过（exit 0）
- opencode 在最后一轮输出 `<promise>DONE</promise>`
- `check-promise.sh` 检测到信号，loop 正常退出

---

## 7. 修改 / 扩展

### 7.1 重跑向导

任何时候都可以重新触发 skill（说"重搭 harness"）。重跑时：

- **覆盖**：`AGENTS.md`、所有 `scripts/*.sh`、`.opencode/config.json`、方法论目录的 `AGENTS.md`
- **保留**：`TASKS.md`（你的任务清单）、`state/iteration.md`（运行历史）、`README.md` 的非生成段
- **首次覆盖前**：检测到同名文件存在会备份成 `.bak`

### 7.2 加新方法论

例如要加 Property-Based Testing：

1. 在 `.claude/skills/harness-loop/templates/methodologies/` 加 `pbt.md`
2. 在 `wizard/decision-tree.md` 的 Q2 表格加一行
3. 在 `wizard/questions.md` 的 Q2 选项加一个
4. 在 `templates/scaffolding/methodology-dirs/` 加配套目录
5. 重跑 L1 验证：`bash .claude/skills/harness-loop/scripts/check-skill.sh`

### 7.3 加新检查层

例如要加 C7（覆盖率门槛）：

1. 在 `.claude/skills/harness-loop/templates/checks/` 加 `check-coverage.sh.tmpl`
2. 在 `wizard/decision-tree.md` 加 Q4 表格行 + 占位符映射
3. 在 `wizard/questions.md` 的 Q4 加选项
4. 在 `templates/checks/AGENTS.md` 文档化新检查

### 7.4 切换 strict / advisory

不需要重跑向导。直接编辑每个 `scripts/check-*.sh` 顶部的 `STRICT="strict"` 改成 `STRICT="advisory"`（反之亦然）。提交时 CI 也会跟着切换。

更优雅的做法：把 `STRICT` 改成读环境变量：

```bash
STRICT="${HARNESS_STRICT_MODE:-strict}"
```

然后 `HARNESS_STRICT_MODE=advisory git commit ...` 临时绕过。

---

## 8. 故障排查

### 8.1 pre-commit 不触发

```bash
# 检查 hooksPath 配置
git config --get core.hooksPath
# 应该输出 .githooks

# 如果没有，重新设置
git config core.hooksPath .githooks

# 验证 hook 可执行
ls -la .githooks/pre-commit
# 应该有 x 权限；如果没有：
chmod +x .githooks/pre-commit
```

### 8.2 check-tests.sh 报 "command not found"

`mvn` / `pytest` / `vitest` / `go` 不在 PATH。先在终端手动跑确认能跑：

```bash
mvn -version
which pytest
```

如果项目语言和当前 PATH 不匹配，重跑 skill 选 Q3 时改一下。

### 8.3 opencode 没读 AGENTS.md

确认 `.opencode/config.json` 的 `instruction_file` 字段：

```json
{
  "instruction_file": "AGENTS.md",
  ...
}
```

确认 AGENTS.md 在项目根（不在子目录）。

### 8.4 check-consistency.sh 报 C2 false positive

如果你有 3 层及以上深度的目录带 AGENTS.md（如 `.claude/skills/harness-loop/AGENTS.md`），确保用的是 issue 001 修复后的版本（commit `a6908c6` 之后）。验证：

```bash
grep -E '\(\[A-Za-z0-9_\.\-\]+/\)' scripts/check-consistency.sh
# 应该看到 + 量词，不是 {1,2}
```

### 8.5 Windows 上 bash 脚本报错

确保用 Git Bash（不是 WSL bash，也不是 cmd）。验证：

```bash
echo $SHELL
# 应该输出 /usr/bin/bash 或类似

which bash
# 应该指向 Git 安装目录下的 bin/bash.exe
```

### 8.6 L2 / L3 显示 "warning-only"

需要 `scripts/run-with-answers.sh` 已实现。本仓库 v0.1.0 之后版本应该都有。验证：

```bash
ls .claude/skills/harness-loop/scripts/run-with-answers.sh
bash .claude/skills/harness-loop/scripts/check-examples.sh
# 应该看到实际 diff 输出，不是 warning
```

---

## 9. 命令速查

```bash
# 触发 skill（在 Claude Code 里）
搭个 harness

# 启用 pre-commit hook（一次性）
git config core.hooksPath .githooks

# 手动跑检查
bash scripts/check-tests.sh
bash scripts/check-consistency.sh
bash scripts/check-promise.sh state/last-output.txt
bash scripts/check-entropy.sh
bash scripts/check-stuck.sh

# 跑 skill 自身的 L1/L2/L3 验证
bash .claude/skills/harness-loop/scripts/check-skill.sh
bash .claude/skills/harness-loop/scripts/check-examples.sh
bash .claude/skills/harness-loop/scripts/check-bootstrap.sh

# 非交互式生成（用于 CI 或脚本）
bash .claude/skills/harness-loop/scripts/run-with-answers.sh answers.json /tmp/output

# 启动 opencode（在项目根）
opencode

# 临时绕过 pre-commit（不推荐）
git commit --no-verify -m "..."
```

---

## 10. 设计哲学（给深度读者）

这套约束系统对齐 [deusyu/harness-engineering](https://github.com/deusyu/harness-engineering) 总结的 6 大概念和 [snarktank/ralph](https://github.com/snarktank/ralph) 的 6 条信条。简而言之：

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

---

## 11. 下一步

- **看示例**：`.claude/skills/harness-loop/examples/java-tdd/` 是完整生成结果，可以直接当参考
- **看设计**：`docs/superpowers/specs/2026-06-27-harness-loop-skill-design.md` 是完整 spec
- **看代码**：`.claude/skills/harness-loop/templates/` 是所有模板的源
- **提 issue**：[github.com/liyangdong/harness-loop-skill/issues](https://github.com/liyangdong/harness-loop-skill/issues)

祝你跑得开心，agent 在轨道里干活。
