# Spec: <feature-name>

> Copy this file to `docs/specs/<feature-slug>.md` and fill in the sections.
> Do not delete sections — leave placeholder text in place until you have a
> real answer, then replace. A spec with `<...>` brackets still in it is
> `Draft`, not `Reviewed`.

## Status

Draft

> One of: `Draft` | `Reviewed` | `Implemented`. Promotion to `Reviewed`
> requires every section below to be filled in with real content (no
> `<placeholder>` brackets remaining).

## Goal

<1-3 sentences on what this feature achieves. Describe the outcome, not the
mechanism. If you can't say it in 3 sentences, the scope is too large — split
into multiple specs.>

## Stakeholders

- PM: <name>
- Tech lead: <name>
- Reviewers: <name>, <name>

> Named individuals, not just roles. A spec with no PM or no tech lead is a
> spec no one is accountable for.

## Constraints

- <Hard constraint 1: e.g., "p99 latency < 200ms under 1k RPS">
- <Hard constraint 2: e.g., "must work on PostgreSQL 14+">
- <Hard constraint 3: e.g., "no new runtime dependencies">

> Constraints are non-negotiable. If the design violates one, the design is
> wrong, not the constraint. Add regulatory / compliance / budget lines here
> too.

## Design

<Architecture narrative. What are the components? How do they communicate?
What is the data model? What are the key algorithms? Where do existing
systems fit in?>

### Diagram

```text
+----------+     +----------+     +----------+
|  Client  |---->|  Service |---->|   Data   |
+----------+     +----------+     +----------+
                       |
                       v
                 +----------+
                 |  Side    |
                 |  effect  |
                 +----------+
```

> ASCII diagrams are preferred over images — see AGENTS.md §3. Boxes for
> components, arrows for direction, labels on arrows for the protocol /
> message name. Keep diagrams under ~60 cols so they render in a side-by-side
> diff view.

### Data model

<Describe the entities, their fields, and their relationships. Reference
existing tables / schemas when relevant.>

### Algorithms

<For any non-trivial logic (ranking, scheduling, dedup, retry), describe the
algorithm in prose or pseudocode. Don't make reviewers reverse-engineer it
from the implementation.>

## Acceptance criteria

- [ ] <Criterion 1: an observable behavior>
- [ ] <Criterion 2: an observable behavior>
- [ ] All tests in `tests/<feature>_test.*` pass
- [ ] Documentation updated (README, API docs, runbook)
- [ ] Performance budget met: <specific measurement>
- [ ] Error cases handled: <list>

> Each criterion must be independently verifiable — either by a human reading
> the output or by an automated check. Vague criteria ("works well",
> "performs adequately") are not criteria.

## Out of scope

- <Explicitly excluded thing 1>
- <Explicitly excluded thing 2>

> Listing what you are NOT doing is as important as listing what you are. It
> forces scope to be explicit and gives reviewers a basis to push back on
> scope creep during implementation.

## Open questions

- <Unresolved decision 1> — owner: <name>, decided by: <date>
- <Unresolved decision 2> — owner: <name>, decided by: <date>

> Open questions must have an owner and a decision date. A question with no
> owner is a question that will never be answered.

## Changelog

| Date       | Status     | Author      | Notes                          |
|------------|------------|-------------|--------------------------------|
| <YYYY-MM-DD> | Draft      | <name>      | Initial draft                  |
| <YYYY-MM-DD> | Reviewed   | <name>      | Approved by tech lead          |
| <YYYY-MM-DD> | Implemented| <name>      | Shipped in release <version>   |

> Append-only. Every status transition gets a new row. Do not edit history.
