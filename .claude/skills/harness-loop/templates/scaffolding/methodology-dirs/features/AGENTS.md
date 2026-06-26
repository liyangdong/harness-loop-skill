# AGENTS.md — features/ (generated when methodology = BDD)

> Conventions for the behavior-driven development directory the wizard writes
> into a user project when Q2 (methodology) = BDD. Rendered from
> `templates/scaffolding/methodology-dirs/features/`. Target path in the
> generated repo: `features/`.

## 1. One Feature per `.feature` file

- Each `.feature` file describes exactly **one Feature** (the Gherkin
  keyword, capital F).
- Filename = feature slug: `user-auth.feature`, `search-ranking.feature`.
- A `.feature` file with two `Feature:` lines is invalid Gherkin — split it.

## 2. Given / When / Then structure

- Every Scenario uses the three-keyword structure: `Given` (preconditions),
  `When` (action), `Then` (observable outcome).
- `And` / `But` chain within a section; do not invent new top-level keywords.
- A Scenario without a `When` is not a scenario, it is a fixture — move it
  to `Background`.

## 3. Background for shared preconditions

- Use `Background:` at the top of a `.feature` file to declare preconditions
  that apply to *every* Scenario in that file.
- Do not repeat Background steps inside each Scenario — that is what
  Background is for.
- Keep Background short (≤5 steps). Long backgrounds signal the feature's
  setup is too coupled — refactor.

## 4. Scenario Outline + Examples for data-driven scenarios

- When the same logical Scenario runs against many inputs, use
  `Scenario Outline:` with `<parameter>` placeholders and an `Examples:`
  table.
- One row per data case. Columns are the parameters referenced in the steps.
- Example tables belong *inside* the `.feature` file — do not link out to
  CSV. The file must be self-contained.

## 5. Step definitions live in `features/step_definitions/`

- Steps (the `Given`/`When`/`Then` lines) are bound to executable code via
  step definitions in `features/step_definitions/`.
- One step-definition file per *domain area* (auth, billing, search), not
  one per Scenario. Step definitions are shared across features.
- A step that appears in multiple `.feature` files must have exactly one
  matching definition — duplicates cause ambiguous-match errors at runtime.

## 6. Prefer declarative steps over imperative

- **Bad (imperative):** `When the user clicks the "Submit" button` — this
  is a UI instruction, not a behavior. It breaks the moment the UI changes.
- **Good (declarative):** `When the user submits the registration form` —
  describes the *intent*, agnostic to UI mechanics.
- Declarative steps survive UI rewrites. Imperative steps are brittle.

## 7. What lives here vs. elsewhere

- This directory holds `.feature` files only (plus `step_definitions/`).
- Implementation lives under `src/` (or language-specific layout).
- A Scenario's `Then` step is the executable acceptance criterion — if the
  Scenario passes, the behavior exists. Specs (`docs/specs/`) and features
  can coexist when Q2 = Hybrid (SDD + BDD): specs describe intent, features
  describe verifiable behavior.
