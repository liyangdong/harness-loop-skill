## Ralph 6 信条

The six tenets that shape day-to-day agent work in this repo. Read them as operating
principles, not slogans — each one maps to a concrete practice on the right.

| 信条 | 含义 | 在本项目的应用 |
|---|---|---|
| Fresh Context Is Reliability | 每轮迭代重新读仓库 | agent 不依赖会话内存，所有状态写文件（`state/iteration.md`） |
| Backpressure Over Prescription | 不规定怎么做，门控拒绝坏结果 | `check-*.sh` 拒绝非零退出，但不指挥如何修复 |
| The Plan Is Disposable | 重新生成的成本只是 planning loop | 失败的尝试可丢弃，`state/` 是真相而非会话历史 |
| Disk Is State, Git Is Memory | 文件是交接机制 | `TASKS.md` + `state/iteration.md` 持久化进度，commit 记录历史 |
| Steer With Signals, Not Scripts | 加路标，不加脚本 | `AGENTS.md` 描述目标与约束，不写命令序列 |
| Let Ralph Ralph | 坐在循环上，不坐在循环里 | 用户监督而非微管理，让 loop 自己跑完 |

### Day-to-day meaning

These tenets resolve the most common judgment calls an agent faces:

- **"Should I remember X from earlier?"** — No. Re-read `state/iteration.md`. (Tenet 1)
- **"The check failed, what do I do?"** — The check tells you the file and the fix in
  its stderr. Apply the fix; do not look for a hidden "right way". (Tenet 2)
- **"This approach feels wrong, should I salvage it?"** — Discard and regenerate. Disk
  state survives; session state does not. (Tenet 3)
- **"Where do I record progress?"** — Write to disk (`TASKS.md`, `state/`). Do not rely
  on the human remembering. (Tenet 4)
- **"Should I add a new step to the loop?"** — Only if it adds a signal (a check, a
  log). Do not add steps that prescribe *how* to do the work. (Tenet 5)
- **"Should I wait for human input?"** — Only at configured checkpoints. Otherwise keep
  the loop running; the human watches, you do not block on them. (Tenet 6)

### References

- Concepts 01-06 — concrete practices that follow from these tenets
- `state/iteration.md`, `TASKS.md`, `state/entropy-log.md` — the on-disk state surface
- deusyu/harness-engineering — source of the tenet framing
