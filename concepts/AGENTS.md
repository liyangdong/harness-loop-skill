# concepts/

Learning archive of the 6 core concepts that shape this project's harness-loop
constraint system. Verbatim copies of the skill's `templates/concepts/` files,
exported so other agents reading this repo can learn the same operating model.

## 本目录约定

- 6 files: `01-repo-as-truth.md` through `06-entropy-gc.md`.
- Each file is a standalone markdown fragment (heading + 30-80 lines).
- Do not edit these files locally — they are skill exports. To evolve the
  concepts, edit `.claude/skills/harness-loop/templates/concepts/` and re-run
  the wizard's Q7=生成 action.
- The root `AGENTS.md` concatenates all 6 as its "6 大概念" section.

## 与根 AGENTS.md 的关系

继承根 AGENTS.md 的所有规则。本目录是参考材料，不引入新规则。

## 验证

本目录相关的检查：
- `scripts/check-consistency.sh` — C1 may verify concept counts declared in
  README/AGENTS.md against this directory (if any numeric declaration exists).
