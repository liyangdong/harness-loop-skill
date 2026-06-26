# docs/specs/

Spec-driven development directory. One spec per feature or significant change.

## 本目录约定

- One feature per `.md` file. Filename = feature slug (e.g., `user-auth.md`).
- Required sections in every spec, in order: Status, Goal, Stakeholders,
  Constraints, Design, Acceptance criteria, Out of scope, Open questions.
- A spec missing any required section is `Draft` and cannot be promoted to
  `Reviewed` until all eight are present and non-placeholder.
- Spec before implementation: a spec at `Status: Reviewed` MUST exist before
  implementation begins on the corresponding feature.
- Spec changes require a new commit (no amends/squashes away — spec history
  is the point of versioning).
- ASCII diagrams preferred over images (diff cleanly, searchable).
- Status vocabulary is controlled: `Draft` | `Reviewed` | `Implemented`.

## 与根 AGENTS.md 的关系

继承根 AGENTS.md 的 6 大概念和 Ralph 信条。本文件只补充本目录特有规则。

## 验证

本目录相关的检查：
- `scripts/check-consistency.sh` — C2 verifies `docs/specs/` mentioned in root
  AGENTS.md has an AGENTS.md (this file).
