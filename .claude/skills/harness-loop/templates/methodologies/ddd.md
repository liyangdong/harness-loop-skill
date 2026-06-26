## 工作循环: DDD (Domain-Driven Design)

Ubiquitous language before code. The team and the codebase share one
vocabulary for the domain. That vocabulary lives in
`docs/domain/ubiquitous-language.md` and is mirrored in code identifiers,
type names, and method signatures. The model is the language; the language is
the model.

### Workflow

1. Add or update entries in `docs/domain/ubiquitous-language.md` before
   touching production code. Each term has: canonical name, definition in
   business language, aliases it must not be called, and the bounded context
   it belongs to.
2. Identify the bounded context this change lives in. If no context exists
   yet, sketch one in `docs/domain/contexts/<context>.md` with its
   responsibilities, public interface, and neighbors.
3. Map each ubiquitous-language term in scope to a code construct: an entity,
   value object, aggregate root, domain event, or domain service. The code
   identifier MUST match the canonical term verbatim — no synonyms, no
   abbreviations.
4. Implement domain logic in rich models. Entities and aggregates carry
   behavior, not just data; anemic models that are bags of getters violate
   the methodology (see Anti-patterns).
5. Run `bash scripts/check-consistency.sh`. If a code identifier or type name
   diverges from the ubiquitous-language file, the check fails and points at
   the offending file and line.
6. When the business meaning shifts, update the ubiquitous-language file
   FIRST, then propagate the rename through code via grep + replace. Commit
   the language change and the code change together so history stays
   coherent.
7. On iteration close, every new term introduced is in the
   ubiquitous-language file and every change to code names is reflected
   there.

### Acceptance criteria

- [ ] Every domain noun in the changed code (entity, value object, aggregate,
      event) appears verbatim in `docs/domain/ubiquitous-language.md`
- [ ] No two ubiquitous-language terms are synonyms for each other (no
      `Customer` and `User` meaning the same thing)
- [ ] `bash scripts/check-consistency.sh` exits 0 (code identifiers and
      language file are aligned)
- [ ] Each aggregate root has at least one method that mutates state — pure
      data holders (anemic) are flagged for redesign

### Required artifacts

- `docs/domain/ubiquitous-language.md` — the canonical term glossary.
  Scaffolding directory is
  `templates/scaffolding/methodology-dirs/domain/`.
- `docs/domain/contexts/<context>.md` — one file per bounded context,
  describing its responsibilities and integration points.

### Anti-patterns

- **Anemic models.** Classes that are only fields and getters, with all
  behavior in services that operate on them. The model no longer encodes
  invariants; logic is scattered. Move behavior into the aggregate so the
  model itself enforces the rules.
- **Language divergence.** Business stakeholders say "Policy", the code says
  `Contract`, the database says `agreement_record`. Three names for one thing
  guarantees confusion. Pick one canonical term and use it everywhere.
- **Skipping the glossary.** Building domain code without writing the terms
  down first. The "shared" language then lives in one engineer's head and is
  invisible to fresh-context agents. Write it down before coding.
- **God aggregates.** One aggregate root owning half the domain. Invariants
  become impossible to reason about and transactions span unrelated concepts.
  Split along genuine consistency boundaries.
