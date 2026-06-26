## 4. Agent Readability

Optimize for agent reasoning over human convenience.

### Why it matters

A repo that is pleasant for a human to skim and a repo that an agent can reason about
reliably are not the same thing. Agents struggle with: magic that depends on runtime
convention, library APIs that change between minor versions, frameworks with terse DSLs
that hide control flow, and dependencies whose training data is thin.

Choosing "boring" technology — stable APIs, well-documented libraries, plain data
structures — dramatically increases the agent's hit rate. The agent has seen these
patterns thousands of times in training; it can write correct code on the first try
without spelunking through docs.

Sometimes this means reimplementing a small subset of a fancy library by hand. A 50-line
inlined implementation the agent fully understands beats a 5-line call into an opaque
upstream that fails in ways the agent cannot diagnose. The cost of writing the subset is
paid once; the cost of debugging the opaque call is paid every iteration.

### How to apply

- Prefer languages and runtimes with stable, well-documented standard libraries.
- Pick libraries that appear frequently in training data (a popular ORM > a clever new
  one).
- Inline small utilities rather than introducing a one-off dependency for 20 lines of
  code.
- Prefer explicit data (plain dicts, structs, JSON) over framework magic (annotations
  that hide control flow, metaclasses, codegen).
- When wrapping an upstream API, write a thin shim with a stable interface — isolate
  upstream churn behind it.
- Avoid beta/preview features in agent-edited code; they change semantics between
  releases.

### Anti-patterns

- Adopting a brand-new framework because it "saves typing" — agent gets it wrong on
  every iteration until training data catches up.
- Heavy metaprogramming so the human can write 3 lines instead of 30 — the agent cannot
  follow the control flow and emits plausible-looking but broken code.
- Wrapping a stable stdlib call in a clever helper "for readability" — now the agent has
  to learn your helper.
- Pinning to `latest` — upstream breaks, agent has no idea why.

### References

- Concept 01 — repo as truth (decisions about stack go in ADRs)
- Concept 06 — entropy GC catches "agent picked the fancy library" drift
- deusyu/harness-engineering — "Fresh Context Is Reliability"
