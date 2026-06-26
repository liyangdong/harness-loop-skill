# AGENTS.md — specs/ (generated `docs/specs/` when methodology = SDD)

> Conventions for the spec-driven development directory the wizard writes into
> a user project when Q2 (methodology) = SDD. Rendered from
> `templates/scaffolding/methodology-dirs/specs/`. Target path in the
> generated repo: `docs/specs/`.

## 1. One feature per file

- Each `.md` file under `docs/specs/` describes exactly **one feature**.
- Filename = feature slug: `user-auth.md`, `search-ranking.md`, `billing-csv-export.md`.
- Do not co-locate multiple features in one spec; that defeats the
  "spec exists before implementation" gate (§5 below).

## 2. Required sections

Every spec must contain these top-level sections, in this order:

1. **Status** — `Draft` / `Reviewed` / `Implemented` (controlled vocabulary).
2. **Goal** — 1-3 sentences on the *what*, not the *how*.
3. **Stakeholders** — PM, tech lead, reviewers (named, not just roles).
4. **Constraints** — hard limits: performance budgets, security requirements,
   compatibility matrix, regulatory, deadlines.
5. **Design** — architecture, data model, key algorithms. ASCII diagrams OK.
6. **Acceptance criteria** — checkbox list, each independently verifiable.
7. **Out of scope** — explicit non-goals. Surfaces scope creep during review.
8. **Open questions** — unresolved decisions, each with an owner.

A spec missing any of these sections is `Draft` by definition — it cannot be
promoted to `Reviewed` until all eight are present and non-placeholder.

## 3. ASCII diagrams encouraged

For architecture, data flow, and entity relationships, prefer ASCII over
images. ASCII diagrams:

- Diff cleanly in code review (every character is visible).
- Are searchable (grep finds the box label, not pixels).
- Render identically on every platform (no embedded font / DPI issues).

Use `template.md` for the conventions (boxes, arrows, legends). For anything
that genuinely cannot be ASCII (e.g., a complex state machine), link out to a
checked-in `.svg` or `.png` — never embed as a base64 blob.

## 4. Specs are versioned artifacts

- Specs are committed to git, same as code. `docs/specs/foo.md` has a history.
- Reviewers read the diff, not just the latest version. A spec change is a
  real change and deserves scrutiny.
- Branch PRs that touch implementation MUST also touch the spec — the spec
  is the source of truth, code follows.

## 5. Spec before implementation

- A spec at `Status: Reviewed` MUST exist before implementation begins on
  the corresponding feature. Implementation against a missing or `Draft`
  spec is blocked at PR review.
- If you find yourself wanting to code first, that is a signal the design is
  under-specified. Go back and write the spec.

## 6. Spec changes require a new commit

- A spec change MUST land as a new commit on top of the previous spec
  history. Do NOT amend or squash spec commits away — the history of
  *why* a decision changed is the point of versioning specs.
- If a spec change invalidates already-shipped code, the spec commit and
  the code-update commit go in the same PR but are distinct commits.

## 7. What lives here vs. elsewhere

- This directory is for **specs only** — design intent at the feature level.
- Implementation lives in `src/` (or wherever the language layout dictates).
- Tests live under `tests/` (when Q2 = Hybrid and TDD is also selected) and
  are themselves the executable acceptance criteria for a spec.
- A spec's **Acceptance criteria** section SHOULD reference concrete test
  files / scenario names whenever the methodology mix allows it.
