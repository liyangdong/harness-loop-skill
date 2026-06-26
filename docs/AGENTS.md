# docs/

Documentation hub. Project-level docs live here; methodology-specific
subdirectories have their own AGENTS.md files (progressive disclosure).

## 本目录约定

- `docs/specs/` — SDD spec directory (one spec per feature; see
  `docs/specs/AGENTS.md`).
- `docs/superpowers/` — pre-existing work products (specs, plans) from the
  broader superpowers methodology integration. Not generated scaffolding;
  leave alone unless explicitly working on it.
- New methodology subdirs (e.g., `docs/domain/`, `docs/features/`) follow the
  same pattern: each gets its own AGENTS.md.

## 与根 AGENTS.md 的关系

继承根 AGENTS.md 的 6 大概念和 Ralph 信条。本文件只补充本目录特有规则。

## 验证

本目录相关的检查：
- `scripts/check-consistency.sh` — C6 verifies methodology-required docs
  subdirs each carry an AGENTS.md.
