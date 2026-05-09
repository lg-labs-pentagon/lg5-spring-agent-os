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
