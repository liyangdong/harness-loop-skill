# AGENTS.md — domain/ (generated `docs/domain/` when methodology = DDD)

> Conventions for the domain-driven design directory the wizard writes into a
> user project when Q2 (methodology) = DDD. Rendered from
> `templates/scaffolding/methodology-dirs/domain/`. Target path in the
> generated repo: `docs/domain/`.

## 1. Ubiquitous language is the source of truth

- The terms in `ubiquitous-language.md` are the canonical vocabulary for
  this codebase. Code MUST use these exact terms — class names, method
  names, field names, variables.
- If a term is missing from the table, add it before using it in code.
  Using an undefined term in code is a DDD violation, not just a typo.
- If code uses a term that disagrees with the table, the code is wrong —
  fix the code, not the table (unless the table itself was wrong, in which
  case update the table AND audit the codebase for drift).

## 2. Bounded contexts have clear boundaries

- A bounded context is a scope within which a term has exactly one meaning.
  The same word can mean different things in different contexts (e.g.,
  "Customer" in billing vs. shipping).
- Each context owns its own models, its own persistence, its own APIs.
  Cross-context calls go through an explicitly modeled interface
  (anti-corruption layer, published language, or shared kernel).
- Do not share database tables across contexts. Do not share entity classes
  across contexts. Both are implicit coupling that defeats the boundary.

## 3. Aggregates protect invariants

- An aggregate is a cluster of domain objects treated as a single unit for
  data changes. The aggregate root is the only entry point — external
  references go through the root, never to an internal entity directly.
- The root enforces invariants: rules that must always hold (e.g., "an
  Order's total equals the sum of its LineItems"). Invariants are checked
  inside the root's methods, never in callers.
- One transaction modifies at most one aggregate. Cross-aggregate updates go
  via domain events, not via a single transaction.

## 4. Value objects are immutable

- A value object (e.g., `Money`, `Address`, `DateRange`) has no identity —
  it is defined entirely by its attributes. Two `Money(10, "USD")` instances
  are interchangeable.
- Value objects are immutable: any "modification" returns a new instance.
  Methods like `add(other)` return `new Money(...)`, never `this.amount = ...`.
- Prefer value objects over primitives. A `Money` parameter is harder to
  misuse than a `BigDecimal` parameter.

## 5. Domain events for cross-aggregate communication

- When one aggregate's change should trigger behavior in another, raise a
  domain event (e.g., `OrderPlaced`, `PaymentReceived`). The other
  aggregate subscribes and reacts on its own transaction.
- Events are named in past tense — they describe something that *happened*,
  not a command to do something. `OrderPlaced` (event) vs. `PlaceOrder`
  (command).
- Events are part of the ubiquitous language. Add them to the table in
  `ubiquitous-language.md` with their trigger and their subscribers.

## 6. Repositories are for persistence, not domain logic

- A repository's job is to load and save aggregates by identity. It is a
  collection-like interface (`findById`, `save`, `delete`) — nothing more.
- Domain logic belongs on the aggregate, not on the repository. A method
  like `repository.applyDiscount(orderId, percent)` is a smell — the
  discount logic should live on `Order`, with the repository only persisting
  the result.
- Repositories are defined in the domain layer (interface) and implemented
  in the infrastructure layer. The domain layer never imports an ORM.

## 7. What lives here vs. elsewhere

- `docs/domain/ubiquitous-language.md` is the single source of truth for
  vocabulary. It is read by humans and referenced by code reviews.
- Implementation lives under `src/` (or language-specific layout), organized
  by bounded context (e.g., `src/billing/`, `src/shipping/`).
- Tests live under `tests/` (when Q2 = Hybrid and TDD is also selected) and
  exercise aggregate invariants and event flows directly.
