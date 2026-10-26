# AI Working Rules

These rules apply to all AI assistants working in this repository. They apply to code, database design, git usage, and product decisions alike.

## 0. Go Signal — Conversation Is Not Implementation

Default mode is discussion. Talking about a problem, idea, or feature is NEVER a request to build it.

- Do NOT create, edit, or delete any file until the user gives an explicit go signal: "go", "apply", "implement", "build it", "do it", or equally direct wording.
- Questions, brainstorming, "what if", "I want", "we could", describing a problem — all discussion. Respond with words only: analysis, options, a proposal.
- When discussion produces a concrete plan, end with the proposal and wait. The user says go — then implement exactly what was agreed.
- Unsure whether a message is a go signal? Ask one short question instead of implementing.

## 0.5 Conversation Altitude — Soft Thinking vs Technical Venture

Every conversation runs in one of two modes. The user switches modes, never the AI.

- **Soft mode (default for ideation/brainstorming):** product thinking only — features, users, flows, trade-offs as ideas. ZERO repo contact: no grep, no file reads, no "let me check the codebase", no implementation notes, no effort estimates.
- **Technical mode opens only on explicit bridge from the user**, e.g.:
  - "this feature vs the technical we have" / "check this against the code"
  - naming a technical area: a folder, a file or path
  - "how do we implement this"
- Bridge scopes to what was named — naming one folder opens that folder only, not the rest of the repo.
- One bridge ≠ mode change forever: answer the technical question, return to soft mode unless the user keeps it technical.
- Never pre-fetch repo context "just in case" during soft mode — unrequested exploration drags the conversation out of the user's control.

## 1. Scope Discipline

Implement exactly what was requested — nothing more. The request defines the full scope, not a starting point.

- Do NOT add unrequested error handling, edge cases, validation, fallbacks, refactors, or product features. Example: if asked for a 404 handler, build only the 404 handler — not 500, 403, or timeout handling.
- Never implement anything the user doesn't know about. If it isn't in the request, it doesn't ship.
- Suggestions and improvements ARE welcome, but only as words and only at two moments:
  - **While brainstorming/planning** — before any implementation starts.
  - **After implementation is complete** — as a short "Suggestions" list, one line each.
- Never suggest mid-implementation, and never turn a suggestion into code without explicit approval. The user decides what enters scope.
- This applies beyond code: no unrequested screens, flows, settings, or copy changes.

## 2. Database Rules

### 2.1 Table Purity

A column belongs on a table only if it is a fact about that row's own entity, and it cannot be
derived from other data.

Anything else is noise. It duplicates truth, drifts out of sync, and makes the table about more
than one thing.

| Rejected | Example | Where it belongs |
|----------|---------|------------------|
| Aggregate / counter | `users.project_count` | `COUNT(*)` over the child table |
| Derived value | `users.age`, `users.full_name` | computed at read time |
| Wrong-direction FK | `users.current_project_id` for a one-to-many | on the child row |
| Cross-concern | `users.theme`, `users.timezone`, `users.locale` | `user_preferences` |
| Auth / session state | `last_login_at`, `failed_login_attempts`, `refresh_token` | `user_credentials`, `login_event` |
| Dumping ground | `users.metadata jsonb` | named columns |

Denormalisation is allowed, but only after all three of these are true:

1. A real query was measured and is too slow
2. An ADR records the measurement and the decision
3. The consistency mechanism is named — trigger, or scheduled recompute

Never on a hunch, and never "while we are in here anyway".

### 2.2 Column Types by Domain Meaning

- Timestamps: `TIMESTAMPTZ`, stored UTC. Java `Instant` or `OffsetDateTime`, never `LocalDateTime`
- Calendar dates with no time (date of birth, due date): `DATE`, never a timestamp
- Money: integer minor units or `NUMERIC`, never `float`/`double`
- Identifiers: `UUID` or an integer type, never `float`
- Enumerated state: a named column with a constraint, not a free-text string

### 2.3 Schema Ownership

- Schema is defined by versioned Flyway migrations, never generated from entities
- `spring.jpa.hibernate.ddl-auto` stays `validate` or `none` in every profile
- An entity change without a matching migration is an incomplete change
- Migrations are append-only; a released migration is never edited

### 2.4 Snapshot and Migrations Mirror Exactly

The schema snapshot (`server/src/main/resources/db/schema/schema.sql`) and the migration chain
(`server/src/main/resources/db/migration/`) describe the same schema. Not the snapshot behind, not the
snapshot ahead — the same. A database built either way is byte-identical.

Two artifacts describing one schema is a standing drift risk, and drift here produces the worst
class of bug: environment-dependent. A stale snapshot means clean-slate environments (a new
laptop, CI, Testcontainers) get one schema while populated environments get another, and the next
migration is authored against a schema that exists nowhere but someone's laptop.

The snapshot is therefore **derived, never maintained**:

- Migrations are the source of truth. The snapshot is a build artifact
- Never hand-edit the snapshot. Regenerate it with `server/scripts/schema-dump.sh`,
  which replays every migration against an empty database and dumps the result
- A new migration is not finished until the snapshot is regenerated in the same change
- The snapshot carries its `flyway_schema_history` rows, so a snapshot-built database already knows
  which migrations it contains and `flyway:migrate` does not try to re-run them
- When the two disagree, migrations win and the snapshot is regenerated. Never the reverse —
  patching the snapshot to match a database hides a migration that was applied by hand

The snapshot must be a **fixed point**: loading it and dumping again reproduces it exactly. Where a
semantically equivalent SQL form breaks that (Postgres re-parsing `IN (...)` into a different
expression tree than it renders), the migration is written in the form that round-trips, with a
comment saying why.

Verification — replaying and loading the snapshot must produce identical schemas (run from `server/`):

```
docker compose down -v && docker compose up -d
./mvnw flyway:migrate        # path A: replay from empty
pg_dump --schema-only > a.sql
docker compose down -v && docker compose up -d
./scripts/schema-load.sh     # path B: snapshot, then catch up
./mvnw flyway:migrate
pg_dump --schema-only > b.sql
diff a.sql b.sql             # any output is drift, and is a failing build
```

Strip pg_dump's `\restrict` / `\unrestrict` lines before comparing or committing: they carry a
random nonce per dump and are psql guards, not schema.

Clean-slate setup always ends with `flyway:migrate`, even straight after a snapshot load. The
snapshot is only as new as its last regeneration, and that step is what closes the gap.

Fixtures (`server/src/main/resources/db/fixtures/`) are outside this rule and outside the migration chain.
They are local development data, they never reach a real environment, and they are not part of the
schema. Reference data the application cannot run without is not a fixture — it belongs in a
migration.

### 2.5 Every Table Has

- A primary key
- `created_at` and `updated_at`, defaulted by the database, not only by JPA
- A FK constraint on every reference, with an explicit `ON DELETE` behaviour
- An index behind every column used to filter or join in real queries

## 3. Git Rules

### 3.1 No AI Attribution

Commits must contain no AI authorship markers:

- No `Co-Authored-By: Claude ...` trailer
- No "Generated with Claude Code" line
- No AI tool name, model name, or emoji badge anywhere in the message, commit body, or PR description
- `git commit --author`, `user.name`, and `user.email` are never changed to an AI identity

The human running the commit is the sole author.

### 3.2 Committing Is Explicit-Only

`git commit` is its own action, never a step inside implementing. Rule 0 applies to it in full.

- Never commit as a side effect of finishing work. Implementation landing is not a reason to commit.
- A go signal authorizes the code, never the commit. A batched instruction ("1. schema 2. BE 3. mobile GO") authorizes all the listed work and zero commits.
- Commit only on its own explicit cast in the current message: "commit", "commit this", "commit and push". Cast is per-commit, not per-session — one cast does not cover the next round of work.
- Same rule for `git add`, `git push`, tags, and branch pushes. Never stage-and-hold in anticipation.
- If it is unclear whether a message authorizes a git action, ask one short question and wait.
- Before committing, state the proposed commit message and wait for approval unless the human already supplied one.
- After implementing, leave changes in the working tree and say what is staged-worthy. Offering "want this committed?" is allowed — one line, at the end.

### 3.3 No Commit-Then-Undo

Never create a commit and then reverse it. Forbidden without explicit human instruction in the current message:

- `git commit` followed by `git reset`, `git revert`, `git commit --amend`, or `git rebase` on that commit
- Committing to "checkpoint" work, then rewriting or dropping it
- Any push followed by a corrective force-push
- Amending or rewriting history to strip attribution after the fact — get it right on the first commit

Get the change right before committing. If a commit turns out wrong, stop and report it — the human decides whether to revert, amend, or fix forward.

### 3.4 Conventional Commits

```
<type>(<scope>): <description>

<optional body>

<optional footer>
```

- Allowed types: `feat`, `fix`, `refactor`, `docs`, `test`, `chore`, `perf`, `ci`, `build`, `style`, `revert`
- Description: imperative mood, lowercase, no trailing period, max 72 chars
- Breaking change: `!` after type/scope (`feat!:`) plus a `BREAKING CHANGE:` footer
- Body explains **why**, not what — omit it when the subject already says everything

### 3.5 Scope Is the Repo Domain, Never the Feature

Scope answers *where in the repo*, not *what feature*. Closed list — extend only by editing this line:

`server` `mobile` `docs` `repo`

- `repo` covers root-level config and tooling (`.gitignore`, CI, package manifests, `AGENTS.md`).
- Never scope by feature, entity, or ticket — the feature belongs in the subject.
- A commit spanning two domains is split into one commit per domain. If genuinely inseparable, drop the scope entirely: `feat: ...`.
- Scope is lowercase, singular, spelled exactly as listed above.

## 4. Architecture Patterns

### 4.1 `server/` — Spring Boot + Java 21 + PostgreSQL

Built with Maven. Flyway migrations. Build: `./mvnw verify`, run: `./mvnw spring-boot:run`. Base package: `com.chap.server`.

#### Package Layout

```
com.chap.server
├── controller    @RestController — HTTP only
├── service       @Service — business logic
├── repository    @Repository / JpaRepository — DB access only
├── entity        @Entity — JPA table mappings
├── dto           request/response records
├── config        @Configuration beans
└── util          stateless helpers, mappers
```

#### Dependency Direction

Dependencies flow downward only: `controller → service → repository → DB`.

- A controller never injects a repository
- A service never injects a controller
- A repository never injects a service
- No layer may be skipped

#### Layer Responsibilities

| Layer | Must do | Must NOT do |
|-------|---------|-------------|
| Controller | Map HTTP, bind + validate DTOs, delegate to service, set status codes | Business rules, conditionals over domain state, DB calls, transactions |
| Service | Business rules, orchestration, `@Transactional`, DTO↔entity mapping | Touch `HttpServletRequest`, `ResponseEntity`, or any HTTP type; write JPQL/SQL |
| Repository | Derived query methods, `@Query`, persistence | Business rules, DTO usage, validation |
| Entity | Model the table, own its invariants | Carry HTTP or DTO concerns; be returned from a controller |

#### DTO Boundary

- Controllers accept and return DTOs only — never entities
- Entities never leave the service layer
- Use Java `record` for DTOs; add `@Valid` on controller request bodies
- Separate request and response DTOs when their fields differ

#### Transactions

`@Transactional` belongs on service methods. Never on a controller, never on a repository. Read-only operations use `@Transactional(readOnly = true)`.

#### Dependency Injection

Constructor injection only. No `@Autowired` on fields, no setter injection. Dependencies are `private final`.

#### Interfaces

Do not create a service interface with exactly one implementation. Add the interface when a second implementation actually exists.

#### Error Handling

- Throw domain exceptions from the service layer
- Translate them to HTTP status codes in one `@RestControllerAdvice`
- Controllers contain no `try/catch` for business errors

### 4.2 `mobile/` — Flutter + Dart, iOS + Android only

Native mobile is the only client. There is no web client in this repo.

Analyze: `flutter analyze`, test: `flutter test`, run: `flutter run`.

**Architecture is the Flutter team's official app architecture** (docs.flutter.dev/app-architecture, Compass sample): MVVM, layer-first at the top, feature folders inside the UI layer. Not community feature-first — do not restructure toward `features/<name>/{data,domain,presentation}`.

```
mobile/lib/
  main.dart                  # entrypoint — runApp only
  config/                    # env values, dependency wiring
  routing/                   # router + route names
  ui/
    core/
      themes/                # theme.dart, colors.dart, dimens.dart
      ui/                    # shared widgets — never feature-specific
    <feature>/
      view_model/            # <feature>_viewmodel.dart
      widgets/               # <feature>_screen.dart + its parts
  domain/
    models/<entity>/         # plain immutable data, no I/O
    use_cases/               # only when logic spans repositories
  data/
    repositories/<entity>/   # abstract + _remote / _local impls
    services/                # one wrapper per external source
  utils/                     # result.dart, command.dart
```

Rules:
- Data flows one way: `Service → Repository → ViewModel → View`. Never skip a step, never reverse one.
- One view model per view, 1:1. A view holds zero business logic — it reads getters and calls commands.
- A view model depends on repositories only, never on a service, and never holds a `BuildContext`.
- A repository is the single source of truth for its entity. It owns caching and translates wire data into domain models at the boundary — parsing happens once, there.
- A service wraps exactly one external source (HTTP, db, platform channel) and returns decoded raw data, never domain models.
- Fallible data-layer calls return `Result<T>` from `utils/result.dart` instead of throwing, so callers must handle both branches.
- Async UI actions go through `Command0`/`Command1` from `utils/command.dart` — never hand-rolled `isLoading` / `errorMessage` fields on a view model.
- `domain/` imports nothing from `data/` or `ui/`. `ui/core/` never imports a feature.
- Money is `int` minor units, never `double`. Dates are `DateTime`, never `String`.
- Spacing, radii, and tap targets come from `ui/core/themes/dimens.dart`. Colors come from `Theme.of(context).colorScheme`, never from `colors.dart` directly.
- `test/` mirrors `lib/` path-for-path.
- Start flat inside a feature; split a file only when it grows past ~300 lines.
- Naming: files `snake_case.dart`, classes `PascalCase`, view models suffixed `ViewModel`, screens suffixed `Screen`.

**UI/UX — the phone is the constraint.** Design viewport is **360dp wide**. If it fits 360 it fits everything.

Structural guards (mechanical — a violation is a defect, not a preference):
- Every `Text` in a `Row` is wrapped in `Flexible`/`Expanded`, or carries `maxLines` + `overflow`. No exceptions.
- Any string from the server, the AI, or user input rendered in a constrained slot gets `maxLines: 1` + `TextOverflow.ellipsis`.
- No fixed height around a `Text`. Height comes from content, or the second line clips.
- Layout survives `textScaler` 2.0. If it clips at 2.0 it is broken, not "edge case".
- Size the **hit area**, never the glyph. Minimum `Dimens.minTapTarget`.
- Never read `BrandColors.*` in a widget. Colors come from `Theme.of(context).colorScheme`.
- Never use a brand tint as text or icon ink. Those are fills. Ink has its own tokens.
- Text clears 4.5:1 against its background; borders and UI glyphs clear 3:1.
- Loading, thinking, and skeleton states wrap in `Semantics(liveRegion: true)`.
- Every SVG carries `semanticsLabel:` or `excludeFromSemantics: true`. Never the default.

Copy in constrained slots — hard caps, because the slot cannot grow:

| Slot | Cap |
|------|-----|
| Button label | 14 chars, 1–2 words, imperative verb |
| Chip / filter / pill | 12 chars |
| Field label | 20 chars, not a sentence |
| Field error | 40 chars — the fix, not the diagnosis |
| Section header | 20 chars |
| Snackbar | 60 chars, one line |

Over cap is not done. Count before writing, not after. A revision may never lengthen a string — shorter or equal, every pass. Lengthening needs the user to ask for it.

Until a pattern is defined here, ask the user before establishing any folder structure or architectural convention. Once defined, follow it strictly — update this section before starting work under a new pattern.

## 5. Minimal Code

Write the smallest amount of code that fully achieves the goal. Less code = less to read, review, and break.

- Prefer the direct solution. No wrapper functions, helper classes, config objects, or abstraction layers for a single use case.
- Use what already exists: language built-ins, stdlib, and utilities already in the project — before writing new code.
- No premature abstraction. Duplicate twice before extracting; abstract only when the third use appears.
- Short must stay readable. Clear names and straightforward logic beat clever one-liners — if shorter makes it cryptic, the longer version wins.
- Delete dead code, unused imports, and leftover scaffolding in files you touch — never leave "just in case" code.
- Fewer files > more files. Don't split code across files until size or reuse forces it.

## 6. Lint & Type Safety

Code isn't done until it passes the project's linter and type checker cleanly. Applies to whatever stack the project uses.

- Run the project's lint and type checks after changes; fix all errors AND warnings before declaring done.
- Never use escape-hatch types that disable type checking (e.g. a catch-all "any"-style type, unchecked casts). If a type is genuinely unknown, use the language's safe equivalent and narrow it; if a type is missing, define it.
- Never silence instead of fix: no suppression comments or annotations that hide an error without user approval.
- Never weaken configs to make errors pass — no loosening compiler strictness, lint rules, or ignore files to bypass an error.
- Fix the cause, not the warning.
- Choose types by domain meaning, not convenience. Examples: money = integer minor units or a decimal type, NEVER float/double (rounding drift); IDs = string or integer, never float; dates/times = proper date types, not raw strings.
- Cast deliberately: convert at the boundary (parse input once into the right type), don't sprinkle casts through the code.

## 7. Documentation Workflow — PRD + Worklog

`docs/` holds exactly three things. `PRD.md` is the locked, compacted current state, written in product language. `IMPLEMENTATION.md` is the build plan — phases and order of work, technical language allowed. `log/` is the append-only trail, one file per conversation. Neither doc has to be both a record and a current view — that separation is the point, so do not blur it.

```
docs/
  PRD.md             # product truth — locked by default (see below)
  IMPLEMENTATION.md  # build plan — edit only on explicit request
  log/               # append-only worklog entries
```

### Worklog — when to write

Only when the user explicitly asks. Never on your own initiative, never as a side effect of other work, never because a session felt significant. No entry is written without a direct instruction.

When asked, keep the entry to what **contradicts** prior understanding: a stub became real, something was cut, a decision reversed, a feature shipped. Apply this filter to every line — *would future-me redo this work without knowing it?* If nothing in the session passes, say so rather than padding the entry.

### Worklog — filename

`YYYY-MM-DD-HHMM-domain-slug.md`

- Build the prefix with `date +%Y-%m-%d-%H%M`. Never hand-type it — zero-padding is what makes the folder sort correctly.
- Create-if-not-exists. A name collision must fail loudly. Never overwrite an existing entry.
- Domain is exactly one word from the vocabulary below, with no internal hyphen, or the filename stops parsing as `date | time | domain | slug`.
- Slug is 2–4 words, lowercase, hyphenated.

### Worklog — domains

Closed list. Singular. Extend only by editing this line.

_(none defined yet — ask the user before writing the first entry)_

Put the primary domain in the filename and any secondary domains in frontmatter. Never tag by activity — `bugfix`, `ui`, `refactor` feel natural and will never be queried.

### Worklog — entry

3–6 lines. 400–800 characters of body. Hard ceiling 1200.

### Product PRD (`docs/PRD.md`)

- PRD is the product truth — product language ONLY: features, users, value. Zero technical implementation content.
- Compacted current state, not a changelog. History lives in `log/`.
- PRD is locked by default. Read anytime; edit ONLY on explicit cast: "update the PRD", "add this to the PRD", "PRD this feature". Cast is per-edit, not per-session. Brainstorming a feature — even a liked one — never auto-lands in the PRD.
- Single `PRD.md` until ~300 lines; split into per-feature files only then.

### End-of-conversation learn habit

- When a conversation is wrapping up — task complete, or the user signals they're done — remind the user to capture learnings with `/ecc:learn`. Applies to every conversation type: brainstorming, code, review.
- Remind only; never auto-run learning or session-save tools.

### Docs are explicit-only (rule 0 applies to docs, strictly)

- Never create a `docs/` file as a side effect of other work — even when the conversation "produces something worth documenting".
- Each docs file needs its own explicit request naming what to create. Conversation output stays in conversation until then.
- Suggesting "want this in the log?" is allowed — one line, at the end.

## 8. OpenSpec — Spec-Driven Slices

`openspec/` at the repo root holds the build specs for fullstack work (server + mobile), one vertical slice at a time. It sits beside `docs/`, not inside it: `docs/IMPLEMENTATION.md` stays the high-level phase plan, and `openspec/` holds each slice's detail.

```
openspec/
  specs/<capability>/spec.md   # current behavior — updated only by archiving a change
  changes/<change>/            # one proposed slice: proposal.md, design.md, specs/ deltas, tasks.md
  changes/archive/             # finished slices
```

- Initialize with `openspec init --tools none`: no generated slash commands or tool files. Drive it with the `openspec` CLI.
- One change per vertical slice (DB → server → mobile). Each proposal names what it depends on; build in that order.
- Specs state behavior: `### Requirement:` with SHALL/MUST, and at least one `#### Scenario:` with WHEN/THEN. Each scenario is a test case. Technical choices go in `design.md`, steps in `tasks.md`.
- `openspec validate --all --strict` passes before a change is called ready.
- Rule 0 applies: creating or editing a change, spec or design needs a go signal. During an approved implementation, ticking `- [x]` in that change's `tasks.md` is part of the work.
- `openspec archive <change>` (which rewrites `specs/`) runs only on its own explicit cast.

## 9. Local Artifacts

Design studies that live outside the app — mockups, reports, dashboards, diagrams — in `artifacts/`. Every shipped artifact is one self-contained HTML file opened by double-click (`file://`): no server, no build, no network. Called **local artifacts** to distinguish from Claude web artifacts (claude.ai-hosted pages).

| Cast | Kind | Authored |
| --- | --- | --- |
| `local artifacts html` | static | hand-written HTML, straight into `artifacts/[title]-[YYYY-MM-DD]/` |

### Casting

- **Ambiguous "artifact" = ask first.** When the user requests an "artifact" without saying which kind, ask: Claude web artifact (claude.ai) or local artifact (this folder)? Never assume.
- **"local artifacts" = static HTML.** It is the only kind in this repo. Build it that way; don't switch kinds mid-build.
- **Explicit-only creation.** A local artifact is written only on a direct request — never as a side effect of other work.

### Rules

- **Folder per artifact:** `[title]-[YYYY-MM-DD]/` — title first, kebab-case. Revisiting a topic on a later date = new folder with the new date.
- **Main file repeats the title:** `floor-plan-2026-09-27/floor-plan.html`. Sibling files (variants, extra pages) live in the same folder.
- **Numbered files on an explicit count cast:** "5 artifacts of the top navbar" = 5 sibling files, each prefixed `01-`…`05-` (`01-top-navbar.html`). One file per artifact, no variant grid inside one file. Without a count cast, one main file named after the title.
- **Versioning: `versions/` subfolder, main file always latest.** On explicit cast only ("version this", "snapshot it"): copy the current main file → `versions/vN-YYYY-MM-DD.html` (N = next number, date = snapshot day), then apply the update to the main file. Snapshots are frozen — never edited again.
- **The shipped HTML makes zero external requests.** No CDN, no fonts over the network, no `fetch()` — it must render offline via `file://`, today and in two years.
- **One hand-written file** with inline `<style>` and classic `<script>` only. No `type="module"`, no build step, no dependencies.
- **Design tokens are copied, not shared:** paste the app's `:root` variables once they exist — an artifact is a snapshot of the design system, not a live consumer.
- **Synthetic data only** — no real user data, no keys.
- **Source backlink when one exists:** `<meta name="source" content="docs/...">` plus a visible footer line. Exploratory mockups may predate any spec — backlink is optional.

### Master artifact

`artifacts/master-mobile.html` is the one living master template of every app screen and state — never "done", never archived. Every other local artifact is a **slice**: one area (a screen, the tab bar, a card) worked on in isolation, then merged back. This exists so rapid prototyping never means rebuilding the whole app, and never means copying the whole app to touch one area.

- **Undated, single exception** to folder-per-date: `master-mobile.html` lives directly in `artifacts/` with no folder and no date in its name.
- **Layout like Mobbin** (same pattern as tenant-help-app's `mobile-master-template.html`): left sidebar of tabs, one numbered section per tab, each a row of screens. The URL hash (`#s-0`, `#s-1`…) keeps the selected tab.
- **Section** = `<section data-name="...">` inside `<main id="sections">`; its number is its order. `Role · Area` names (e.g. `Admin · Users`) group tabs under the role.
- **Screen** = `<template data-title="..." data-note="...">` inside a section, holding the screen body only. The script adds the device frame, screen numbers (`2.3`), counts and tabs.
- **Phone or web:** `data-device="web"` puts a screen in a 1440 × 900 browser window; default is phone (iPhone 16e, 390 × 844 pt). Both can sit in one section.
- **Flows and states:** `data-group="..."` on the first `<template>` of each flow adds a heading. Every state (empty, typing, error, sheet open…) is its own `<template>`, in flow order.
- Screens are static snapshots. Click-through interaction belongs in slices.
- **Region markers fence every area** so a slice is extracted — and merged back — without reading or rewriting the rest of the file. Same marker pattern around an area's HTML, CSS, and JS:
  `<!-- @region tab-bar -->` … `<!-- @endregion tab-bar -->` (`/* @region tab-bar */` … `/* @endregion tab-bar */` in CSS/JS). Region names are lowercase kebab-case and match across all three. Each section's HTML is one region.
- A shared `tokens` region (the `:root` variables) lives in the master and is copied into every slice.
- How-to-extend comment at the top of the file; keep it current.
- Same rules as any local artifact: one file, inline `<style>`/`<script>`, zero external requests, synthetic data.

Casts, all explicit-only — none runs as a side effect of other work:

| Cast | Does |
| --- | --- |
| `master artifact` | work directly in `master-mobile.html` |
| `slice <area>` | new folder `artifacts/<area>-[YYYY-MM-DD]/<area>.html` holding only that area's regions + the regions it depends on (`tokens`, `base`, shared CSS/JS) + the minimal shell to render it |
| `merge <area>` | add the slice's screens to `master-mobile.html` as `<template>`s (one per state) in that area's section, and replace that area's CSS regions with the slice's version; every other region stays untouched |

- **After every merge, end with one line asking to archive the slice:** "Merged. Archive `artifacts/<area>-[YYYY-MM-DD]/`?" Remind only — the move happens only on the user's explicit "archive" (see Archive below). Never archive on your own.
- A slice is a working copy, not a live link: if the master's region changed while the slice was open, merging overwrites it.

### Archive

`artifacts/_archive/` is where an artifact goes once it has been used, superseded, or dropped. `artifacts/` holds only live work — finished ones don't pile up beside it.

- Move, never delete: the whole folder moves to `artifacts/_archive/[title]-[YYYY-MM-DD]/`, name unchanged.
- `_archive/` is frozen history: read it, never edit inside it, never start new work there.
