# scripts/

Mechanical enforcement scripts. One file per concern, composed by
`.githooks/pre-commit`. Docs rot, lint rules don't (Concept 03).

## 约定

- One concern per file: `check-tests.sh`, `check-consistency.sh`,
  `check-promise.sh`, `check-entropy.sh`, `check-stuck.sh`. Each is a
  standalone executable that exits non-zero on failure.
- **No mega-`check-all.sh`.** A single failure in a combined script hides
  which check broke; separate files localize blame.
- Checks must be deterministic: same repo state → same exit code. No
  network calls, no `date`-relative logic, no reading uncommitted state.
- The `pre-commit` hook calls **every** `check-*.sh` in this directory
  automatically — adding a new check is just dropping a new file in.
  Same for `.github/workflows/consistency.yml` on push/PR.

## 错误格式

Every check that finds a violation prints, per finding:

```
❌ <check-id> <one-line description>
   修复: <one-line fix instruction>
```

- `❌` (red cross) marks a real failure. `⚠️` marks an advisory warning
  (advisory mode only — see root AGENTS.md `## 严格度`).
- `修复:` (Chinese for "fix:") precedes a single concrete action — file
  path to edit, value to set, command to run. No prose, no "consider..."
- Exit non-zero only after all findings are printed, so the developer sees
  the full list in one pass.

## 严格度 vs 建议度

- **strict** (default): any `❌` failure exits non-zero, blocks the commit,
  fails the PR check. The developer must fix or explicitly downgrade.
- **advisory**: failures print `⚠️` and exit 0. The commit proceeds; the
  warning is the only signal. Use for migration windows only.

The mode is set once at generation (Q8) and applies to every check
uniformly — do not mix modes per script.

## 添加新检查

1. Write `scripts/check-<concern>.sh`. Follow the error format above.
2. Make it executable (`chmod +x`).
3. Done — `pre-commit` and `consistency.yml` pick it up automatically on
   the next run because they glob `scripts/check-*.sh`. No registration.
4. If the check introduces a new state file (e.g., a new ledger under
   `state/`), document it in `state/AGENTS.md` in the same commit.

## 与根 AGENTS.md 的关系

继承根 AGENTS.md 的 6 大概念（特别是 Concept 03: Mechanical Enforcement 和
Concept 06: Entropy GC）。本文件只补充本目录特有规则。

## 验证

- `.githooks/pre-commit` — calls every `check-*.sh` in this directory when
  controlled paths are staged.
- `.github/workflows/consistency.yml` — mirrors `pre-commit` on push/PR.
- `scripts/check-consistency.sh` — C6 verifies `scripts/AGENTS.md` exists.
