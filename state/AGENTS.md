# state/

On-disk loop state surface. The agent's short-term memory, rebuilt from
disk each iteration (never from session history).

## 本目录约定

- `iteration.md` — current iteration number, max_iterations, progress_signature,
  progress log table, blockers, recovery steps. Read by `check-stuck.sh`,
  `check-consistency.sh`, and the agent itself at iteration start.
- `entropy-log.md` — append-only ledger of pattern drift found by
  `check-entropy.sh`. Each row: Date, Issue, Location, Severity, Status.
- `transcript*`, `*.log`, `last-output.txt` — runtime artifacts (gitignored,
  not committed).

## 与根 AGENTS.md 的关系

继承根 AGENTS.md 的 6 大概念（特别是 Concept 01: Repo as Truth 和 Concept 04:
Disk Is State, Git Is Memory）。本文件只补充本目录特有规则。

## 验证

本目录相关的检查：
- `scripts/check-consistency.sh` — reads `state/iteration.md` to determine
  methodology (drives C6); verifies the file exists and is parseable.
- `scripts/check-stuck.sh` (if Q4 includes 卡死检测) — reads
  `progress_signature` history from front matter for stuck detection.
