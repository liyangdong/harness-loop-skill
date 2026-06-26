---
iteration: 1
max_iterations: 30
last_updated: 1970-01-01T00:00:00+00:00
progress_signature: initial
---

# Iteration State

## Current

- Iteration: 1 / 30
- Active subtask: see TASKS.md
- Last action: loop bootstrap

## Progress log

| Iter | Date | Files changed | Tests passing | Notes |
|------|------|---------------|---------------|-------|
| 1 | 1970-01-01T00:00:00+00:00 | (initial) | 0 | Loop started |

## Blockers

(none)

## Recovery

If loop restarts, read this file first to resume:

1. Current iteration number (front matter `iteration:`).
2. Active subtask in `TASKS.md` (the first unchecked `[ ]`).
3. Last `progress_signature` (front matter) — compare to the previous N
   signatures for stuck detection (see `scripts/check-stuck.sh`).
