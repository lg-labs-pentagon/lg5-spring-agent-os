# Changelog — lg5-spring-agent-os skills bundle

All notable changes to the **bundle** (every change in any skill rolls up here)
are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this bundle adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

Per-skill detail lives in `<skill>/CHANGELOG.md`.

## Versioning policy

- **MAJOR** — breaking re-organization of the skills (renames, deletions,
  removal of mandatory rules).
- **MINOR** — new skill, new section in an existing skill, validated against
  a new `lg5-spring-sha`.
- **PATCH** — clarifications, typo fixes, anti-pattern additions, no behavioral
  change in the recipes.

Each bundle release pins **all** included skills to a single `lg5-spring-sha`
(see `manifest.yaml`). Mixing skills validated against different framework
commits is unsupported.

## [Unreleased]

## [4.3.0] — 2026-05-13
### Removed
- **`model:` frontmatter field stripped from all 12 subagents**. Was
  previously hardcoded to `anthropic/claude-sonnet-4-20250514`,
  breaking any consumer whose OpenCode / Claude Code / Cursor provider
  config did not expose that exact model id (typical error:
  `Model not found: anthropic/claude-sonnet-4-20250514`). After this
  change subagents inherit the **consumer's default model**, making
  the bundle portable across providers (Anthropic, OpenAI, Gemini,
  GitHub Copilot, …) without per-consumer edits. Reported by
  `blank-service` (Luis Quiroga). See `subagents/CHANGELOG.md`
  [4.0.0] for the full migration note.

### Changed
- `scripts/validate.sh`: removed `model` from the required-keys set in
  `validate_subagents()` (line 270) and updated the header comment
  (lines 21-24) to document the new portability stance.
- `subagents/manifest.yaml`: header comment rewritten to explain the
  intentional absence of `model:` and the provider-agnostic design.
- All 5 manifests bumped `bundle.version: 4.2.0 → 4.3.0`. Internal
  versions: subagents 3.2.0 → **4.0.0** (MAJOR — breaking schema
  change for the subagent artifact set in isolation, even though the
  cross-bundle release is MINOR). skills 4.2.0 → 4.3.0,
  commands 0.7.0 → 0.7.1, specs 0.6.0 → 0.6.1, rules 0.4.0 → 0.4.1
  (PATCH no-op bumps for cross-bundle invariant).

### Rationale (v4.3.0 — provider-agnostic subagents)
The original bundle authors pinned every subagent to Sonnet 4 for
quality consistency, but the trade-off was severe portability loss:
the bundle was *de facto* Anthropic-only, despite OpenCode and the
SDD workflow being model-agnostic by design. The fix is the simplest
possible: remove the `model:` line entirely (Option A from the
v4.2.0 retrospective discussion). Consumers who genuinely want to
pin a specific model can re-add `model: …` to any subagent in their
local checkout post-install — the validator now allows either
presence (any string) or absence.

## [4.2.0] — 2026-05-13
### Added
- **`/add-rest-endpoint` building-block command** (commands v0.7.0). New
  slash command that adds a single REST endpoint end-to-end to an
  existing lg5-spring service: appends a handler method to the
  aggregate's existing `<Aggregate>Controller`, creates verb-scoped DTOs
  (`<Verb><Aggregate>Command` + `<Verb><Aggregate>Response` records under
  `<svc>-domain/<svc>-application-service/.../domain/dto/<verb>/`), adds
  the service-port method signature with `@Valid`, implements it in the
  package-private impl delegating to a fresh `<Verb>CommandHandler`
  `@Component`, extends the MapStruct mapper, appends an OpenAPI fragment
  to `openapi.yaml` (path block + schemas), and creates a package-private
  IT extending `Bootstrap`. Idiomatic media-type `application/vnd.api.v1+json`
  inherited from the class-level `@RequestMapping` (RULE-006). Aggregate
  controllers are reused — the command refuses to create a second
  controller for the same aggregate (RULE-004). Grounded on real evidence
  from `blank-service:BlankController.java`, `BlankApplicationServiceImpl.java`,
  `BlankCreatorIT.java`, `openapi.yaml`. Default invocation:
  `/add-rest-endpoint blank POST /blank addBlank`. Out of scope: file
  uploads, WebSocket/SSE, API versioning bumps, aggregate-less endpoints.
- **`/add-jpa-entity` building-block command** (commands v0.7.0). New
  slash command that creates a brand-new persistent aggregate end-to-end
  (8 files created + 1 modified): domain entity extending
  `AggregateRoot<<Aggregate>Id>` with private final fields and a
  `validate()` method (Spring/JPA-free per RULE-003), value-object id
  extending `BaseId<UUID>` (RULE-016), `<Aggregate>DomainException`,
  output-port repository interface with `create<Aggregate>` +
  `findById(UUID)` (no speculative finders), JPA entity with
  `@Table(schema=…)` + Lombok `@Getter @Setter @Builder @NoArgsConstructor
  @AllArgsConstructor` and `@Column` per field-spec, `JpaRepository<…, UUID>`
  extension, hexagonal adapter `@Component implements <Aggregate>Repository`,
  MapStruct mapper with the canonical `default <Aggregate>Id map(UUID)`
  helper that unwraps the VO on read, Liquibase YAML changelog
  (`ddl-v.0.0.<next>.yaml` auto-versioned from existing files), and a
  one-line wire-up to `db.changelog-master.yaml`. Plus a save+findById
  round-trip IT extending `Bootstrap`. Field-spec syntax:
  `<name>:<type>[:<constraint>]` with `<type>` ∈ {String, UUID, Long,
  Integer, BigDecimal, Instant, LocalDate, Boolean} and `<constraint>` ∈
  {notnull, unique}. Reuses the service's existing Liquibase schema (does
  not create new schemas). Grounded on real evidence from
  `blank-service:Blank.java`, `BlankId.java`, `BlankRepository.java`,
  `BlankEntity.java`, `BlankJPARepository.java`, `BlankRepositoryImpl.java`,
  `BlankDataAccessMapper.java`, `ddl-v.0.0.1.yaml`,
  `db.changelog-master.yaml`. Default invocation:
  `/add-jpa-entity blank Customer name:String:notnull email:String:unique,notnull`.
  Out of scope: `@OneToMany`/`@ManyToOne`/`@Embedded` relationships,
  native Postgres ENUM columns, `@Version` optimistic locking,
  outbox-pattern aggregates (use `/add-outbox` instead), Flyway-based
  services.

### Changed
- `AGENTS.md` building-blocks table updated with the two new commands.
- All 5 manifests (`commands`, `skills`, `subagents`, `specs`, `rules`)
  bumped to `bundle.version: 4.2.0` per the cross-bundle invariant.
- Per-bundle internal versions: commands 0.6.2 → 0.7.0 (MINOR — new
  commands); skills 4.1.2 → 4.2.0 (MINOR — primary record);
  subagents 3.1.2 → 3.2.0, specs 0.5.2 → 0.6.0, rules 0.3.6 → 0.4.0
  (MINOR no-op bumps to keep cross-bundle invariant on the `4.x.0` line).

### Rationale (v4.2.0 — boilerplate generators)
These two commands close the largest pain point identified in the
post-v4.1.x productivity audit: scaffolding boilerplate for the two
most-frequent code paths in a hexagonal lg5-spring service (HTTP surface
+ persistent state). Together with `/scaffold-service`, `/add-saga`,
`/add-outbox`, `/add-kafka-listener`, the bundle now covers the seven
canonical extension points from `blank-service` (the upstream template
itself was the primary reference). Convention: both commands are
typically invoked from inside `/sdd-implement` for a `TASK-NNN` whose
acceptance criteria call for a new endpoint or aggregate, but they can
also be invoked standalone for ad-hoc work. Generator output goes
straight into the repo (no per-file confirmation prompts) — accept the
rollback risk in exchange for max productivity. Deferred to v4.3.0:
`/add-domain-event`, `/add-cucumber-scenario`, incremental code-reviewer
hook, retrospective subagent.

## [4.1.2] — 2026-05-13
### Added
- **Discoverability docs** (issue #16). New "How to invoke the bundle's
  agents" section in `AGENTS.md` (linked from `README.md`'s consumer-layout
  section) clarifies that bundle subagents have `mode: subagent`, so Tab
  in OpenCode does NOT cycle through them — Tab is reserved for `primary`
  agents (Build, Plan, custom). The right way to invoke a bundle subagent
  is `@<name>` from a primary chat, but in practice the `/sdd-*` commands
  dispatch to the right subagent automatically. The three cross-cutting
  subagents (`lg5-code-reviewer`, `lg5-test-generator`, `lg5-ci-cd-engineer`)
  are the typical `@`-mention targets for ad-hoc work outside the SDD flow.
  Reported by `lg5-loyalty-ledger` (Luis Quiroga).
- **`scripts/validate.sh --install`** (issue #17) — regression test for
  the housekeeping-files-leak (#15). Runs `scripts/install.sh` against a
  disposable temp consumer fixture (fake repo with `.agent-os/` symlinked
  to the bundle), then asserts that `.opencode/{agents,commands,skills}/`
  are **real directories** containing none of the forbidden meta files
  (`CHANGELOG.md`, `manifest.yaml`, `.DS_Store`) and that every `.md`
  under `agents/` and `commands/` has YAML frontmatter. Verified
  end-to-end: removing `"CHANGELOG.md"` from `install.sh`'s `meta_skip`
  makes the lint fail with exit code 1, citing each leaked path by
  reference to #15. Gated behind `--install` because it materializes a
  temp filesystem.
- **CI wiring** — `.github/workflows/validate.yml` now runs
  `scripts/validate.sh --install` as a second step after the artifact-side
  checks. Future regressions of #15 fail CI on the same PR that
  introduces them.

### Changed
- `bundle.version` in `manifest.yaml` bumped to `4.1.2` per the
  cross-bundle invariant.
- `README.md`'s "Resulting consumer layout" diagram updated to reflect
  the per-entry symlink layout introduced in `4.1.1`. Adds a short
  pointer-to-AGENTS.md FAQ on Tab-vs-`@` discoverability.

### Rationale
- Issues #15 and #16 originated from the same downstream confusion
  ("only one agent loaded"). #15 was the bug; #16 was the missing docs
  that prevented the consumer from self-diagnosing. Shipping the docs in
  the same minor cycle as the regression test closes the feedback loop.
- The install-output lint is the smallest possible test that exercises
  the actual user-visible artifact (`.opencode/`), which was previously
  unverified by CI. Any future change to `install.sh` (or any new
  housekeeping file in an artifact folder) that re-introduces #15 will
  fail CI on the introducing PR.

## [4.1.1] — 2026-05-13
### Fixed
- `scripts/install.sh` no longer leaks bundle housekeeping files
  (`CHANGELOG.md`, `manifest.yaml`, `.DS_Store`) into the OpenCode
  discovery surface. The legacy folder-level symlinks
  (`.opencode/{skills,commands,agents}` → `.agent-os/<artifact>`) caused
  OpenCode to load `CHANGELOG.md` as a phantom subagent (no frontmatter,
  visually noisy in the `@`-mention picker) and the same for commands and
  skills. Reported by downstream consumer `lg5-loyalty-ledger` (issue #15).

  The installer now creates `.opencode/{skills,commands,agents}/` as real
  directories populated with one symlink per real artifact entry, filtering
  a configurable `meta_skip` list. Upgrading from any earlier version is
  transparent: the existing folder-level symlink is removed and replaced
  by the per-file tree on the next `install.sh` run; consumers do not have
  to re-add the submodule or change `.gitignore`.

  No skill, rule, command, subagent, spec, template, or example content
  changed in this release — the fix lives entirely in `scripts/install.sh`.

### Changed
- `bundle.version` in `manifest.yaml` bumped to `4.1.1` per the
  cross-bundle invariant.

## [4.1.0] — 2026-05-13
### Changed
- `bundle.version` in `manifest.yaml` bumped to `4.1.0` per the
  cross-bundle invariant. The SDD Quick-path (`/sdd-quick` +
  `sdd-quicker` + `quick-spec-template`) shipped from `commands`,
  `subagents`, and `specs` — all per-type manifests must agree.
### Notes
- **No skill content changed.** The Quick-path is orthogonal to the
  11 existing skills; they remain valid for the same situations.

## [4.0.0] — 2026-05-12
### Added
- New skill **`lg5-vitepress-docs`** (v0.1.0) capturing the unified
  VitePress documentation site that aggregates the per-contract viewers
  (from `lg5-api-docs`), Allure acceptance reports (from
  `lg5-allure-report`), architecture visualizations, ADRs, runbooks, and
  glossary into a single navigable surface.
- Pattern coverage: dual-deploy (GitHub Pages + Firebase Hosting),
  7-day PR preview channels with bot-commented URLs, source-state footer
  (short SHA + ISO timestamp + PR number), pnpm 11 build-script gating,
  VitePress `public/` static-asset wiring (the critical "don't drop my
  HTML" rule), base-aware relative links for dual-base-path builds, and
  the warn-don't-fail artifact handling via
  `check-artifacts.mjs` + `linkinator-to-annotations.mjs`.
- "Common pitfalls" catalogue: the 4 post-merge bugs surfaced during
  the canonical implementation's verification (footer rendering `dev`,
  footer rendering full 40-char SHA, viewers placed in wrong directory,
  absolute links breaking under non-root base) — all distilled into
  Rules 1-6 in the skill body.
- Compatibility marker `lg5-spring-sha: d0d754a` matching the other
  skills in this release.

### Changed
- `bundle.version` in `manifest.yaml` bumped to `4.0.0` per ADR-006 of
  the canonical consumer (`lg5-loyalty-ledger/docs/specs/004-project-docs/adr/ADR-006-bundle-version-strategy.md`),
  which earmarked v4.0.0 for the introduction of docs-aggregator
  capabilities. The bump is **additive-only** (no existing artifact
  changed); it is marked MAJOR per the consumer's pre-agreement to
  signal the new aggregator capability prominently to downstream
  services.

## [3.0.0] — 2026-05-10
### Changed
- `bundle.version` in `manifest.yaml` bumped to `3.0.0` to honor the
  cross-bundle invariant — `commands`, `subagents`, and `specs` shipped
  a MAJOR (extended SDD workflow with new `/sdd-intent`, `/sdd-design`,
  `/sdd-verify`, `/sdd-orchestrate` phases). All per-type manifests
  must agree on `bundle.version`.
### Notes
- **No skill content changed in this release.** The 11 skills and their
  individual versions remain stable. The new Design phase consumes
  existing skills (`lg5-saga`, `lg5-outbox`, `lg5-kafka-avro`, `lg5-atdd`,
  `lg5-api-docs`, `lg5-allure-report`) without modifying them.

## [2.0.0] — 2026-05-10
### Added (BREAKING)
- **3 new SDD phase-specialist subagents** completing the 1:1 mapping
  with the four `/sdd-*` orchestrator commands. Each subagent is the
  persistent / interactive counterpart of the slash command:
  - `sdd-specifier` (v0.1.0) ↔ `/sdd-specify` — informal prompt → tech-free PRD.
  - `sdd-tasker`    (v0.1.0) ↔ `/sdd-tasks`   — Plan → atomic TASK-NNN with Given/When/Then AC.
  - `sdd-implementer` (v0.1.0) ↔ `/sdd-implement` — one TASK → code + tests + lg5-code-reviewer + commit.
- The four SDD subagents now form a complete chain: `sdd-specifier →
  sdd-planner → sdd-tasker → sdd-implementer`, with every transition
  gated by human approval per Fowler's spec-anchored SDD model.

### Changed (BREAKING)
- **Subagent rename**: `lg5-planner` → `sdd-planner` (bumped 0.1.1 →
  0.2.0). Body rewritten to align strictly with the `/sdd-plan` phase:
  read PRD, generate `plan.md` + ADRs (+ `data-model.md`), cite
  RULE-NNN, fill Constitutional-impact section in every ADR. Tool
  capabilities expanded from `read/glob/grep` to
  `read/write/edit/glob/grep` (Plan phase writes markdown).
- The 3 cross-cutting subagents intentionally keep their `lg5-`
  prefix: `lg5-code-reviewer`, `lg5-test-generator`,
  `lg5-ci-cd-engineer`. They are not phase-specific and are invoked
  from any phase (notably `lg5-code-reviewer` is invoked by
  `sdd-implementer` before every commit; `lg5-test-generator` is
  invoked when a TASK references RULE-012/013).
- `AGENTS.md` subagent catalog split into two tables: cross-cutting (3)
  vs. SDD phase specialists (4). README inventory updated to reflect
  7 subagents (was 3).
- `commands/sdd-plan.md` updated to reference `sdd-planner` (was
  `lg5-planner`).
- `specs/examples/loyalty-ledger/plan.md` reference updated.

### Migration from v1.0.1
- Replace `@lg5-planner` invocations with `@sdd-planner` in any
  consumer prompts, in-flight specs, or documentation.
- No action needed for `lg5-code-reviewer`, `lg5-test-generator`,
  `lg5-ci-cd-engineer` — names unchanged.
- The submodule bump from `v1.0.1` → `v2.0.0` is sufficient for
  consumers using the `.agent-os/` submodule integration; symlinks
  remain valid.

### Why MAJOR
Subagent name resolution in OpenCode (and most agent runtimes) keys on
the filename + `name:` frontmatter field; there is no alias mechanism.
Any consumer reference to `@lg5-planner` will fail to resolve. The
break is intentional and one-time; it locks in the SDD naming
convention so future phase-specialist subagents stay consistent.

## [1.0.1] — 2026-05-10
### Fixed
- **Subagent frontmatter — OpenCode compatibility** (4 subagents bumped 0.1.0 → 0.1.1):
  - `tools` is now an object (`tools: { read: true, ... }`) instead of a CSV
    string (`tools: "read, write, edit, ..."`). OpenCode rejected the string
    form with `Expected object | undefined, got "..."`.
  - `model` is now a real provider/model identifier
    (`anthropic/claude-sonnet-4-20250514`) instead of the bare word `opus`,
    which OpenCode could not resolve.
  - Added `mode: subagent` (required by OpenCode for non-primary agents).
  - Per-tool capabilities preserved: `lg5-ci-cd-engineer` and
    `lg5-test-generator` get `read/write/edit/glob/grep/bash`;
    `lg5-code-reviewer` gets the read-only set + bash; `lg5-planner` gets
    only `read/glob/grep`.
- Affected files:
  - `subagents/lg5-ci-cd-engineer.md`
  - `subagents/lg5-code-reviewer.md`
  - `subagents/lg5-planner.md`
  - `subagents/lg5-test-generator.md`

### Notes
- This release adopts the **OpenCode dialect** of subagent frontmatter.
  Multi-client portability (Claude Code, Cursor, Continue, etc.) will be
  addressed in a future MAJOR release with a neutral/canonical frontmatter
  schema and per-client adapters in `install.sh`. v1.0.1 explicitly does
  NOT introduce that abstraction — it unblocks OpenCode users today.
- No artifact contracts changed in skills, commands, rules, or specs;
  consumers using those artifact types do not need to upgrade.

## [1.0.0] — 2026-05-10
### Changed (BREAKING)
- **Install model: submodule-as-source-of-truth + symlinks** — `scripts/install.sh`
  no longer copies artifacts. The bundle is now consumed exclusively as a git
  submodule mounted at `.agent-os/` in the consumer repo. The submodule itself
  IS the source of truth; `install.sh` materializes a `.opencode/` directory of
  relative symlinks that point back into `.agent-os/`:

  ```
  .opencode/skills    -> ../.agent-os/skills
  .opencode/commands  -> ../.agent-os/commands
  .opencode/agents    -> ../.agent-os/subagents     (OpenCode's naming)
  .opencode/AGENTS.md -> ../.agent-os/AGENTS.md
  ```

  `.opencode/` is added to the consumer's `.gitignore` automatically. Upgrades
  are now `git -C .agent-os checkout vX.Y.Z` — symlinks remain valid; no
  re-install needed for the artifact tree.

### Removed (BREAKING)
- **Install Modes B (plain copy) and C (sparse checkout)** — both relied on
  the copy model and are no longer supported. The submodule is the only
  supported integration.
- **`scripts/dev-link.sh`** — its self-host symlink logic was absorbed into
  `install.sh`, which now auto-detects whether it is invoked from a submodule
  (`.agent-os/scripts/install.sh`, consumer mode) or from the upstream working
  tree (`./scripts/install.sh`, self-host mode) and adjusts symlink targets
  accordingly.

### Migration from v0.3.x
A v0.3.x consumer (e.g. `blank-service` with `.lg5-agent-os/` submodule +
copied `.agent-os/`) migrates by:

1. Removing the old submodule: `git submodule deinit -f .lg5-agent-os && git rm -f .lg5-agent-os && rm -rf .git/modules/.lg5-agent-os`
2. Removing the copied tree: `rm -rf .agent-os`
3. Re-adding as `.agent-os/`: `git submodule add -b main <url> .agent-os && git -C .agent-os checkout v1.0.0`
4. Wiring symlinks: `.agent-os/scripts/install.sh`
5. Committing: `.gitmodules`, `.agent-os` gitlink, `.gitignore`.

### Why MAJOR
Layout change at the install boundary. v0.3.x consumers have hard-coded
references to `.lg5-agent-os/` (submodule path) and `.agent-os/` (copy
target); v1.0.0 collapses both into a single `.agent-os/` (submodule). The
break is intentional and one-time; subsequent bumps within v1.x stay
backward-compatible.

## [0.3.6] — 2026-05-10
### Added
- **Developer tooling** — `scripts/dev-link.sh` self-hosts the bundle for
  OpenCode in the upstream working tree by materializing `.opencode/` as
  symlinks pointing at the source-of-truth artifact directories
  (`.opencode/skills → ../skills`, `.opencode/commands → ../commands`,
  `.opencode/agents → ../subagents`, `.opencode/AGENTS.md → ../AGENTS.md`).
  `.opencode/` is gitignored. Idempotent; supports `--clean`.
  Lets bundle authors dogfood OpenCode against the same artifacts a
  consumer sees, with zero copying or drift.

### Notes
- **No artifact contract changes** — no skill, command, subagent, rule, or
  spec was modified. Consumers do not need to bump. This release exists
  only because cross-bundle invariants (`scripts/validate.sh`) require all
  five `manifest.yaml` files to declare the same `bundle.version`, and the
  new dev script is part of the bundle release surface.

## [0.3.5] — 2026-05-10
### Added
- **Subagent `lg5-ci-cd-engineer`** (v0.1.0) — CI/CD specialist that loads
  the three CI/CD skills (`lg5-github-actions`, `lg5-api-docs`,
  `lg5-allure-report`) on demand. Declares an explicit out-of-scope
  section listing 8 future skills (container delivery, k8s manifests,
  GitOps, release automation, secrets, env promotion, perf pipelines,
  quality gates) with a refusal protocol to avoid invented patterns
  (RULE-018). Backfilled here for completeness — see `subagents/CHANGELOG.md`
  for the original entry.

## [0.3.4] — 2026-05-10
### Security
- **`lg5-github-actions`** (0.1.0 → 0.1.1) — pinned
  `NBprojekt/gource-action@v1.2.1` to its commit SHA
  (`d2fdf85904db416b69445dae5551282528e052ae`) in the `visualization`
  job of `templates/.github/workflows/c-integration.yml`. Mutable tag
  references on non-verified third-party actions are a supply-chain
  risk flagged by Codacy / OpenSSF Scorecard / actionlint. Surfaced by
  Codacy on consumer repo `blank-service` PR #7.
### Notes
- No other skill changed in this release. `lg5-api-docs` and
  `lg5-allure-report` remain at `0.1.0`.

## [0.3.3] — 2026-05-10
### Added
- New skill **`lg5-github-actions`** (v0.1.0) capturing the canonical
  11-job CI topology used by `blank-service` and the shared
  `setup-maven-credentials` composite action that solved the recurring
  Maven 401 in parallel jobs (Checkstyle/Coverage/Build/Test).
  Ships byte-identical templates for
  `templates/.github/actions/setup-maven-credentials/action.yml` and
  `templates/.github/workflows/c-integration.yml`.
- New skill **`lg5-api-docs`** (v0.1.0) capturing the static-HTML
  approach for OpenAPI (Swagger UI 5 from unpkg) and AsyncAPI
  (`@asyncapi/web-component@3` from unpkg). Replaces the legacy
  `openapitools/openapi-generator-cli` and `asyncapi/cli` Docker
  pipelines that broke on `--use-new-generator` and puppeteer install.
  Ships `templates/openapi-template/index.html` and
  `templates/asyncapi-template/index.html`.
- New skill **`lg5-allure-report`** (v0.1.0) capturing the Allure
  Report wiring for Cucumber 7 + JUnit Platform acceptance tests
  (`allure-cucumber7-jvm` 2.29.1 dep, Cucumber plugin registration in
  `AcceptanceTestCase`, `allure.properties`, and the CI job that runs
  Allure CLI 2.32.0 with `if: always()` so dashboards survive flaky
  runs). Ships `templates/src/test/resources/allure.properties`.
### Notes
- Per the policy in this CHANGELOG, MINOR is normally reserved for new
  skills. We chose **PATCH (0.3.3)** intentionally to mark this release
  as **early-access** while consumer repos validate the templates. A
  `0.4.0` MINOR will follow once the templates are battle-tested.

## [0.3.2] — 2026-05-10
### Changed
- Framework SHA pin bumped from `af81c7c` to `d0d754a` (PATCH).
- Includes [`fix(testcontainers)`: in-network Kafka listener](https://github.com/lg-labs-pentagon/lg5-spring/pull/1)
  — companion containers (Schema Registry, app-in-container) now reach
  the broker via `kafka:19092` instead of the host-mapped
  `localhost:<random-port>` advertised listener. Surfaced while wiring
  the first downstream Kafka listener IT in `lg5-loyalty-ledger`
  TASK-009.
- Also pulls in [LG-83] Jib Maven plugin upgrade to 3.5.1 (transitive on
  the framework parent pom).
- All 7 skill files updated `lg5-spring-sha: d0d754a` in frontmatter.
  Worked examples in `food-ordering-system` and `lg5-spring-overview`
  updated the parent-pom coordinate snippets to `1.0.0-alpha.d0d754a`.
### Notes
- **No skill content changed** in this release. Individual skill
  versions remain at `0.1.0`.

## [0.3.1] — 2026-05-10
### Changed
- Framework SHA pin bumped from `cbb6783` to `af81c7c` to honor RULE-001's
  Spring Boot 3.4.2 requirement (`cbb6783` actually shipped 3.3.5,
  discovered during consumer-service TASK-002 of `lg5-loyalty-ledger`).
- `bundle.version` in `manifest.yaml` bumped to `0.3.1` (PATCH; cross-bundle
  invariant requires every per-type manifest to agree).
- All 7 skill files updated `lg5-spring-sha: af81c7c` in frontmatter.
  Worked examples in `food-ordering-system` and `lg5-spring-overview` updated
  the parent-pom coordinate snippets to `1.0.0-alpha.af81c7c`.
### Notes
- **No skill content changed** in this release. Individual skill versions
  remain at `0.1.0`.
- Bundles in `af81c7c`: Spring Boot 3.4.2 upgrade (`e5139d0`),
  `ConfluentKafkaContainerCustomConfig` (`5fb16aa`), CI/docs updates.

## [0.3.0] — 2026-05-09
### Changed
- `manifest.yaml` `bundle.version` bumped to `0.3.0` to align with the
  rest of the bundle (cross-bundle invariant: all per-type manifests must
  agree on `bundle.version`).
### Notes
- **No skill content changed in this release.** All 7 skills remain at
  individual version `0.1.0` and validated against `lg5-spring` SHA
  `cbb6783`.
- The 0.3.0 release of the bundle adds a constitution layer to `rules/`,
  Spec-Driven-Development workflow templates to `specs/`, and 4 new SDD
  orchestrator commands to `commands/`. See those directories' CHANGELOGs
  for details.

## [0.2.0] — 2026-05-09
### Changed
- **Bundle rebranded** from `lg5-spring-skills` to `lg5-spring-agent-os` to
  accommodate additional artifact types alongside skills. The repo on GitHub
  was renamed accordingly; old URLs redirect.
- `manifest.yaml` `bundle.name` updated to `lg5-spring-agent-os`,
  `bundle.version` bumped to `0.2.0`.
- Top-level scripts renamed (`validate-skills.sh` → `validate.sh`,
  `install-skills.sh` → `install.sh`) and extended to handle multiple artifact
  types (`skills/`, `rules/`, `commands/`, `subagents/`, `specs/`, `hooks/`).
- README rewritten to describe the artifact-typed organization.
### Notes
- **No skill content changed** in this release; only metadata/structural
  rebrand. Individual skill versions stay at `0.1.0`. The bundle version
  bumps because the cross-bundle invariant requires every per-type
  manifest's `bundle.version` to be identical, and other artifact types
  (rules, commands, subagents, specs) are introduced at the same time.
- All skills still validated against `lg5-spring` SHA `cbb6783`.
- Companion artifact types added in this release have their own per-type
  CHANGELOGs: `rules/CHANGELOG.md`, `commands/CHANGELOG.md`,
  `subagents/CHANGELOG.md`, `specs/CHANGELOG.md`.

## [0.1.0] — 2026-05-09
### Added
- Initial bundle with 7 skills:
  - `lg5-spring-overview` — framework module map and recent commit insights.
  - `lg5-new-service` — recipe to scaffold from `blank-service`.
  - `lg5-saga` — `SagaStep<T>` pattern with helper-class split.
  - `lg5-outbox` — transactional outbox with `@Version`, native PG enums, jsonb payload.
  - `lg5-kafka-avro` — producer/consumer wiring with batch listeners and NO-OP exception handling.
  - `lg5-atdd` — Cucumber + Testcontainers + Wiremock + AppContainer.
  - `food-ordering-system` — canonical reference implementation breakdown.
- Validated against `lg5-spring` SHA `cbb6783`.
- `manifest.yaml` as single source of truth for installed skill versions.
- `AGENTS.md` at workspace root with 18 hard rules and skill routing table.
