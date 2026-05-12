# Changelog — lg5-spring-agent-os commands bundle

All notable changes to the **commands** artifact set are documented here.
Uses [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and
[SemVer 2.0.0](https://semver.org/spec/v2.0.0.html).

## [0.6.2] — 2026-05-13
### Changed (PATCH — bundle 4.1.2)
- `manifest.yaml` `bundle.version` bumped to `4.1.2` per the cross-bundle
  invariant. No command changed; the 4.1.2 release ships documentation
  improvements (#16) and the `scripts/validate.sh --install` regression
  test (#17) — full notes in `skills/CHANGELOG.md`.

## [0.6.1] — 2026-05-13
### Changed (PATCH — bundle 4.1.1)
- `manifest.yaml` `bundle.version` bumped to `4.1.1` per the cross-bundle
  invariant. No command changed; the 4.1.1 release ships a fix to
  `scripts/install.sh` (housekeeping-files-leak — issue #15) reflected in
  full in `skills/CHANGELOG.md`.

## [0.6.0] — 2026-05-13
### Added (MINOR — bundle 4.1.0)
- **`/sdd-quick <change-slug> "<description>"`** (v0.1.0) — new SDD
  Quick-path command. For trivial changes (1 endpoint, 1 entity,
  1 listener, 1 field, 1 config) that don't justify the full
  7-phase workflow. Produces a compressed `quick-spec.md` (~40
  content lines) under `docs/specs/<NNN-slug>/` and recommends
  going directly to `/sdd-implement`. `/sdd-verify` remains
  **mandatory** — preserves SDD's essence ("the spec is canonical;
  code is derived from it"). Strict eligibility gate rejects: sagas,
  new outboxes, new aggregates, new Avro schemas, multi-module
  changes, new dependencies, breaking API changes, performance- or
  security-critical changes. Pairs with the `sdd-quicker` subagent.
### Rationale
- Empirical: 7 phases × human approval for every trivial change
  produced predictable bypass behavior. Sanctioned quick path with
  mandatory verify > unsanctioned bypass with no verify.

## [0.5.0] — 2026-05-12
### Added (bundle 4.0.0)
- **`/scaffold-docs <service-name> <firebase-project-id>`** (v0.1.0) — new
  building-block command. Drops the unified VitePress documentation site into
  a consumer service: `docs/site/` aggregator scaffold, `firebase.json`,
  `.firebaserc`, 6 Make targets, and 6 CI jobs appended to the canonical
  `c-integration.yml` (`docs-build-pages`, `docs-build-firebase`,
  `pages-deploy`, `firebase-deploy-docs`, `firebase-deploy-allure`,
  `firebase-preview`). Operationalises the `lg5-vitepress-docs` skill
  introduced in skills bundle 4.0.0.
- Final-output checklist for one-time operator setup (Firebase project,
  service-account secret, Pages source toggle, `docs/preview` label).

## [0.4.0] — 2026-05-10
### Added (MAJOR — bundle 3.0.0)
- **4 new SDD orchestrator commands** that extend the workflow from 4
  phases to 7 (plus a read-only meta-helper):
  - **`/sdd-intent <slug> "<idea>"`** (v0.1.0) — optional phase 0.
    Frame an informal idea as a one-page `intent.md` (problem, users,
    why now, desired outcome, success metrics, non-goals, constraints,
    open questions). Pairs with `subagents/sdd-intender.md`. Never
    mentions technology or solution words.
  - **`/sdd-design <NNN-slug>`** (v0.1.0) — new phase 3, between Plan
    and Tasks. Produces `design.md` + `data-model.md` with concrete
    class signatures, REST contracts, Avro schemas, JPA model, configs,
    and module dependency graph. Sits between `sdd-planner`
    (architecture) and `sdd-tasker` (atomic backlog). Pairs with
    `subagents/sdd-designer.md`.
  - **`/sdd-verify <NNN-slug>`** (v0.1.0) — new closing phase 6. Builds
    an AC↔evidence matrix by running `make all-build` + `make
    run-acceptance-test` and cross-checking every PRD AC against test
    output. Constitutional spot-check per RULE-NNN. Emits a gate
    decision (VERIFIED / VERIFIED WITH OVERRIDE / NOT VERIFIED). Red
    gate **blocks spec closure** unless overridden by a `tech-debt`
    ADR. Pairs with `subagents/sdd-verifier.md`.
  - **`/sdd-orchestrate [<NNN-slug>]`** (v0.1.0) — read-only meta-helper.
    Inspects `docs/specs/<NNN-slug>/` and recommends the next phase
    command. With no argument, produces a multi-spec dashboard. Never
    creates artifacts. Pairs with `subagents/sdd-orchestrator.md`.
### Changed (BREAKING)
- **`/sdd-plan`** (v0.1.0 → v0.2.0) — **no longer produces
  `data-model.md`**. Detailed design (including the data model) moves
  to the new `/sdd-design` phase. `plan.md` now contains architecture
  decisions and ADRs only.
- **`/sdd-tasks`** (v0.1.0 → v0.2.0) — now reads `design.md` (mandatory)
  in addition to `plan.md`. Every TASK must reference a specific
  section of `design.md`; tasks that improvise design are forbidden.
- **`/sdd-specify`** (v0.1.0 → v0.2.0) — now optionally reads
  `intent.md` (if present from a prior `/sdd-intent` run) and uses it
  as anchor for REQs and non-goals.
### Notes
- Bundle bumped to `3.0.0` (MAJOR) because the canonical SDD workflow
  changed from `specify → plan → tasks → implement` (4 phases) to
  `[intent →] specify → plan → design → tasks → implement → verify`
  (6-7 phases). Existing specs continue to work — `/sdd-tasks` falls
  back gracefully when `design.md` is missing (it complains and asks
  the human to backfill via `/sdd-design`).
- All transitions still require explicit human approval — no auto-flow.
- Intent (phase 0) is **optional**; Verify (phase 6) is **mandatory**
  and bloqueante.

## [0.3.3] — 2026-05-10
### Added
- New building-block command **`/scaffold-ci-cd`** (v0.1.0) that
  installs the CI/CD pipeline into a consumer service by copying the
  templates shipped by the new `lg5-github-actions`, `lg5-api-docs`,
  and `lg5-allure-report` skills (workflow, composite action, Swagger
  UI / AsyncAPI HTML wrappers, Allure properties). Also performs the
  in-place edits in `<svc>-acceptance-test/pom.xml` and
  `AcceptanceTestCase.java` that Allure requires. Pre-flight ensures
  the bundle is installed at `.agent-os/`.
### Notes
- **No existing command behavior changed** in this release.

## [0.3.2] — 2026-05-10
### Changed
- Framework SHA pin bumped from `af81c7c` to `d0d754a` (PATCH).
- Includes [`fix(testcontainers)`: in-network Kafka listener](https://github.com/lg-labs-pentagon/lg5-spring/pull/1)
  — surfaced while wiring the first downstream Kafka listener IT in
  `lg5-loyalty-ledger` TASK-009.
- Also pulls in [LG-83] Jib Maven plugin upgrade to 3.5.1 (transitive on
  the framework parent pom).
### Notes
- **No command behavior changed** in this release. Individual command
  versions are unchanged.

## [0.3.1] — 2026-05-10
### Changed
- Framework SHA pin bumped from `cbb6783` to `af81c7c` to honor RULE-001's
  Spring Boot 3.4.2 requirement (`cbb6783` actually shipped 3.3.5,
  discovered during consumer-service TASK-002 of `lg5-loyalty-ledger`).
- `bundle.version` in `manifest.yaml` bumped to `0.3.1` (PATCH; cross-bundle
  invariant requires every per-type manifest to agree).
### Notes
- **No command behavior changed** in this release. Individual command
  versions are unchanged.

## [0.2.0] — 2026-05-09
### Added
- **SDD orchestrator commands** (4 new) that drive the Spec-Driven
  Development workflow phases per Fowler/spec-kit:
  - `/sdd-specify <feature-slug> "<informal description>"` — produces a
    functional, technology-free PRD under `docs/specs/<NNN-slug>/prd.md`.
  - `/sdd-plan <NNN-feature-slug>` — produces `plan.md` + `adr/*.md`
    (and `data-model.md` if persistent state); each ADR explicitly
    states its constitutional impact by RULE-ID.
  - `/sdd-tasks <NNN-feature-slug>` — decomposes the Plan into atomic
    `TASK-NNN` with Given/When/Then acceptance criteria and a
    Definition-of-Done checklist.
  - `/sdd-implement <TASK-NNN>` — executes ONE task at a time (write
    code + tests, run `lg5-code-reviewer`, commit with `TASK-NNN` ID).
- New `category` field in `manifest.yaml`: `sdd` vs `building-block`.
### Changed
- Existing 4 commands re-categorized as `building-block` (invoked from
  inside `/sdd-implement`, not directly by humans in the SDD flow).
### Notes
- Bundle bumped to `0.3.0` to align with the rules + specs co-release.
- The SDD commands assume the bundle is mounted at `.agent-os/` in the
  consumer repo (git-submodule mode).

## [0.1.0] — 2026-05-09
### Added
- `/scaffold-service` — bootstrap a new microservice from `blank-service`.
- `/add-saga` — add an end-to-end SagaStep (publisher + listener + outbox + scheduler).
- `/add-outbox` — add a Transactional Outbox (entity + DDL + helper + scheduler) for one event type.
- `/add-kafka-listener` — add a batch Kafka listener with NO-OP exception
  handling per RULE-010.
### Notes
- Validated against `lg5-spring` SHA `cbb6783`.
- Commands are written for OpenCode's slash-command format (YAML frontmatter
  with `description`, `argument-hint`, `allowed-tools`); they should be
  portable to Claude Code and Cursor with minor adaptation.
