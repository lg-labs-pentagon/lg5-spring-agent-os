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
