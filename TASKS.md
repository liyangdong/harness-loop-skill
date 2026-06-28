# Tasks

Active task board for harness-loop-skill. Updated each loop iteration.

## Current epic

Evolve the harness-loop skill: extend methodology/check/language coverage and harden the dogfooded constraint system at project root.

## Subtasks

- [ ] Add remaining languages (Rust/Kotlin/Scala/C#/Ruby) to Q3 branching
- [ ] Add a fifth check (C7: spec coverage gate) for SDD+TDD Hybrid projects
- [ ] Sweep all concept files for cross-reference accuracy after each concept edit

## Done

- [x] T22: Dogfood skill on this project (SDD + non-code + strict) — initial generation
- [x] knowledge-map skill: agent-first KB from deepwiki + codegraph (lucene baseline)

## Blocked

(initially empty)

---

## Conventions

- Each subtask is one checkable unit of work.
- Check off (`[x]`) only after `scripts/check-tests.sh` passes for that subtask.
- If blocked: move to Blocked section + add entry to `state/iteration.md`.
- One PR per subtask when feasible (per throughput-merges concept).
- When a subtask completes, append a one-line summary to `state/iteration.md`
  under the Progress log table before checking the next one off.
