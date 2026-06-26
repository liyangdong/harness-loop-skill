# Ubiquitous Language

> Terms used throughout the codebase. Code MUST use these exact terms —
> class names, method names, field names, variables. A term missing from
> this table is a term that should not yet appear in code.

## Terms

| Term          | Definition                                        | Code reference             |
|---------------|---------------------------------------------------|----------------------------|
| <Term1>       | <one-line definition, in business language>       | <class/module/package>     |
| <Term2>       | <one-line definition>                              | <class/module/package>     |
| <Term3>       | <one-line definition>                              | <class/module/package>     |

> Add a row whenever a new domain term enters the codebase. Update the
> definition (not the term) when understanding evolves. Renaming a term is
> a breaking change — it means auditing every code reference.

## Bounded contexts

- **<Context1>**: <responsibility — what this context is responsible for>
- **<Context2>**: <responsibility>
- **<Context3>**: <responsibility>

> A bounded context is a scope within which a term has one meaning. List
> each context with a single-sentence responsibility. If two contexts share
> responsibility, they are probably one context.

## Aggregates

- **<Aggregate1>** (root: `<Entity>`):
  - Invariants:
    - <invariant 1 — a rule that must always hold>
    - <invariant 2>
  - Contains: <list of internal entities and value objects>
- **<Aggregate2>** (root: `<Entity>`):
  - Invariants:
    - <invariant 1>
  - Contains: <list>

> An aggregate is the unit of consistency. One transaction modifies one
> aggregate. List each aggregate's root entity, its invariants (the rules
> the root enforces), and the objects it contains.

## Domain events

- **<Event1>** (raised by: <aggregate>, subscribed by: <aggregate>):
  <trigger — what causes this event>
- **<Event2>** (raised by: <aggregate>, subscribed by: <aggregate>):
  <trigger>

> Events are named in past tense. They describe something that happened,
> not a command. Add to this table whenever a new cross-aggregate flow is
> introduced.

## Value objects

- **<ValueObject1>**: <attributes — the fields that define equality>
- **<ValueObject2>**: <attributes>

> Value objects are immutable and defined by their attributes. List them
> here so reviewers can spot when a primitive is being used where a value
> object would prevent misuse.

## Changelog

| Date       | Author  | Change                                       |
|------------|---------|----------------------------------------------|
| <YYYY-MM-DD> | <name>  | Initial ubiquitous language draft            |

> Append-only. Every term addition, definition refinement, or context
> boundary change gets a new row.
