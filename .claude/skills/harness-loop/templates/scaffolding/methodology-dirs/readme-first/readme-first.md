# README-First Workflow

> Generated as `docs/readme-first.md` when Q2 (methodology) = RDD. Single-file
> directory — no AGENTS.md sibling, because this file IS the methodology.
> Rendered from `templates/scaffolding/methodology-dirs/readme-first/`.

When adding a new feature, write the README section first.

1. **Describe the feature from the user's perspective.** What does the user
   see? What problem does it solve for them? Write one paragraph as if you
   were explaining it to someone who will never read your code.
2. **Show example usage** (CLI, API, UI). Concrete invocations, concrete
   outputs. Not "the function returns a result" — the actual call and the
   actual return value.
3. **Document error cases.** What happens when the input is bad? When the
   dependency is down? When the user lacks permission? List the failures
   before you implement them, or you will forget half of them.
4. **Then — and only then — start implementation.** If you reach for the
   keyboard before step 4, you are implementing against an unstated design,
   and the design will drift.

If you can't describe the feature clearly in the README, **the design isn't
ready.** That is the point. The README is a design-pressure test: it forces
ambiguity to surface while it is still cheap to fix.

## Why this works

- **Forces user-perspective thinking.** Code-first features tend to expose
  implementation details in the API. README-first features tend to expose
  intent.
- **Surfaces design ambiguity early.** A sentence that won't write itself
  cleanly is a design flaw. Better to find it in paragraph form than in a
  shipped API.
- **Creates an implicit spec.** The README becomes the contract the
  implementation is held to. Reviewers compare code against README, not
  against the implementer's memory of "what I meant."
- **The README becomes documentation without extra work.** Writing docs
  after implementation is double work and is usually skipped. Writing docs
  before implementation is single work and is the design step.

## Anti-patterns

- **Writing the README after implementation.** You lose the design-pressure
  benefit. The README becomes a transcript of what you happened to build,
  not a statement of what you meant to build.
- **Vague README.** "This feature does X" without examples is not a README,
  it is a heading. A README without examples cannot pressure the design.
- **Skipping error cases.** A README that lists only the happy path leads
  to under-implemented error handling. The errors you forgot to write down
  are the errors you will forget to handle.
- **README that describes the implementation.** "Uses a red-black tree
  internally" is not a user-facing statement. Move it to a design doc or
  delete it. The README is for users.

## Workflow checklist

- [ ] User-perspective paragraph written
- [ ] At least one example invocation with concrete output
- [ ] Error cases enumerated (bad input, dependency failure, permission)
- [ ] README reviewed by at least one other person
- [ ] Only then: implementation begins

If any box is unchecked, you are implementing prematurely.
