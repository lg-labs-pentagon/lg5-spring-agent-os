# Changelog — lg5-spring-agent-os subagents bundle

All notable changes to the **subagents** artifact set are documented here.
Uses [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and
[SemVer 2.0.0](https://semver.org/spec/v2.0.0.html).

## [3.0.0] — 2026-05-10
### Added (MAJOR — bundle 3.0.0)
- **4 new SDD phase-specialist subagents** completing the 1:1 mapping
  with the extended 7-phase workflow (plus a meta-orchestrator):
  - **`sdd-intender`** (v0.1.0) — pairs with `/sdd-intent`. Optional
    phase 0. Converts an informal idea into a one-page `intent.md`
    framing problem, users, why now, desired outcome, success metrics,
    non-goals, constraints, and open questions. Never mentions
    technology or solution words. Tools: `read, write, edit, glob, grep`.
  - **`sdd-designer`** (v0.1.0) — pairs with `/sdd-design`. New phase
    3, between Plan and Tasks. Produces `design.md` + `data-model.md`
    with concrete class signatures, REST contracts (RULE-006), Kafka
    contracts + Avro schemas (RULE-007), JPA model + outbox payloads
    (RULE-008), Saga step semantics (RULE-009), configs (RULE-014), and
    an acyclic module dependency graph (RULE-004). Tools: `read, write,
    edit, glob, grep`.
  - **`sdd-verifier`** (v0.1.0) — pairs with `/sdd-verify`. New closing
    phase 6. Runs `make all-build` + `make run-acceptance-test` and
    cross-checks every PRD AC against test evidence (Surefire,
    Failsafe, Cucumber JSON, Allure results). Performs a constitutional
    spot-check per RULE-NNN. Emits a gate decision (VERIFIED / VERIFIED
    WITH OVERRIDE / NOT VERIFIED). Bloqueante — a red gate blocks spec
    closure unless overridden by a pre-existing `tech-debt` ADR file on
    disk. Tools: `read, write, edit, glob, grep, bash`.
  - **`sdd-orchestrator`** (v0.1.0) — pairs with `/sdd-orchestrate`.
    Meta-subagent. Inspects `docs/specs/<NNN-slug>/` state and
    recommends the next phase command. Read-only — never produces
    feature artifacts. Decision tree covers all 7 phases plus closed
    specs. Tools: `read, glob, grep, bash`.
### Changed (BREAKING)
- **`sdd-specifier`** (v0.1.0 → v0.2.0) — now optionally reads
  `intent.md` (if present) and uses it as anchor for REQs and
  non-goals. Pre-flight detects intent presence and adapts the prompt.
- **`sdd-planner`** (v0.2.0 → v0.3.0) — **no longer produces
  `data-model.md`**. Detailed design (data model, REST contracts, Avro
  schemas, JPA tables, configs) moves to the new `sdd-designer`
  subagent. `plan.md` now contains architecture decisions and ADRs
  only. Suggested next-step recommendation changes from `/sdd-tasks`
  to `/sdd-design`.
- **`sdd-tasker`** (v0.1.0 → v0.2.0) — now reads `design.md` (mandatory
  pre-flight) in addition to `plan.md`. Every TASK references a
  specific design section. Tasks that improvise design are forbidden —
  if a TASK has no design anchor, the subagent STOPs and recommends
  re-running `/sdd-design`.
### Notes
- Bundle bumped to `3.0.0` (MAJOR) — the canonical SDD subagent set
  grew from 4 to 8 (7 phase specialists + 1 meta-orchestrator).
- All new subagents have `mode: subagent` and `model:
  anthropic/claude-sonnet-4-20250514` to align with the existing
  `sdd-*` set. They are discoverable in OpenCode's agent tab via their
  `sdd-` prefix.

## [2.0.0] — 2026-05-10
### Added (BREAKING)
- **3 new SDD phase-specialist subagents** completing the 1:1 mapping
  with the four `/sdd-*` orchestrator commands:
  - **`sdd-specifier`** (v0.1.0) — pairs with `/sdd-specify`. Converts
    an informal stakeholder prompt into a tech-free PRD under
    `docs/specs/<NNN-slug>/prd.md` using `prd-template.md`. Surfaces
    ambiguity aggressively via `[NEEDS CLARIFICATION]` markers.
    Tools: `read, write, edit, glob, bash`.
  - **`sdd-tasker`** (v0.1.0) — pairs with `/sdd-tasks`. Decomposes an
    approved Plan into atomic `TASK-NNN` with Given/When/Then AC under
    `docs/specs/<NNN-slug>/tasks.md`. Enforces ≤1 day / 1–2 modules per
    TASK and a DAG of dependencies. Tools: `read, write, edit, glob,
    grep, bash`.
  - **`sdd-implementer`** (v0.1.0) — pairs with `/sdd-implement`.
    Executes ONE TASK per invocation: writes code + tests, runs builds,
    invokes `lg5-code-reviewer`, commits, flips `Status` to `done`.
    Refuses to batch multiple TASKs in a single run. Tools:
    `read, write, edit, glob, grep, bash`.

### Changed (BREAKING)
- **Subagent rename**: `lg5-planner` → `sdd-planner` (file renamed via
  `git mv` to preserve history; bumped 0.1.1 → 0.2.0). The body was
  rewritten to align strictly with the `/sdd-plan` phase: read approved
  PRD, generate `plan.md` + ADRs (+ `data-model.md` when applicable),
  cite constitutional rules by stable RULE-ID, fill the
  Constitutional-impact section in every ADR. Tool capabilities
  expanded from `read/glob/grep` to `read/write/edit/glob/grep` (the
  Plan phase writes markdown files under `docs/specs/<NNN-slug>/`).

### Migration from v1.0.1
- `@lg5-planner` invocations must be renamed to `@sdd-planner`.
- `commands/sdd-plan.md` already references the new name (updated in
  this release). No other command needs adjustment.
- The 3 cross-cutting subagents are unchanged: `lg5-code-reviewer`,
  `lg5-test-generator`, `lg5-ci-cd-engineer` keep the `lg5-` prefix
  intentionally — they are not phase-specific.

### Why MAJOR
Subagent name resolution in OpenCode (and most agent runtimes) keys on
the filename / `name:` frontmatter field; there is no alias mechanism.
Consumer prompts, slash commands, and any in-flight specs that mention
`@lg5-planner` will fail to resolve until updated. The break is
intentional and one-time; it locks in the SDD naming convention so
future SDD additions stay consistent.

## [1.0.1] — 2026-05-10
### Fixed
- **OpenCode compatibility** — all 4 subagents bumped `0.1.0 → 0.1.1`:
  - `tools` field changed from CSV string to YAML object form
    (`tools: { read: true, write: true, ... }`). OpenCode rejected the
    string form (`Expected object | undefined, got "..."`).
  - `model` field changed from bare `opus` to a real provider/model id
    (`anthropic/claude-sonnet-4-20250514`).
  - Added `mode: subagent` (required by OpenCode for non-primary agents).
  - Tool capabilities preserved per subagent:
    - `lg5-ci-cd-engineer` → `read, write, edit, glob, grep, bash`
    - `lg5-test-generator` → `read, write, edit, glob, grep, bash`
    - `lg5-code-reviewer`  → `read, glob, grep, bash`
    - `lg5-planner`        → `read, glob, grep`

### Notes
- This release adopts the **OpenCode dialect** of subagent frontmatter.
  Multi-client portability (Claude Code, Cursor, Continue) will be
  addressed in a future MAJOR with a neutral schema + per-client
  adapters in `install.sh`.

## [0.3.5] — 2026-05-10
### Added
- New subagent **`lg5-ci-cd-engineer`** (v0.1.0) — specialist for
  designing, implementing, debugging, and reviewing GitHub Actions
  CI/CD pipelines on lg5-spring services. Owns the canonical 11-job
  topology, the shared `setup-maven-credentials` composite action,
  the static-HTML OpenAPI/AsyncAPI doc sites, the Allure Report
  wiring, and supply-chain hardening (SHA-pinning per OpenSSF
  Scorecard / Codacy).
- The subagent loads `lg5-github-actions`, `lg5-api-docs`, and
  `lg5-allure-report` skills on demand and prefers the
  `/scaffold-ci-cd` command for net-new pipelines.
- An explicit **out-of-scope** section enumerates topics the
  subagent must refuse to author until the matching skill ships
  (container delivery, k8s manifests, GitOps, release automation,
  secrets, env promotion, perf, extra quality gates). Per RULE-018,
  the subagent will not invent patterns for those.
### Notes
- No existing subagent behavior changed.

## [0.3.2] — 2026-05-10
### Changed
- Framework SHA pin bumped from `af81c7c` to `d0d754a` (PATCH).
- Includes [`fix(testcontainers)`: in-network Kafka listener](https://github.com/lg-labs-pentagon/lg5-spring/pull/1)
  — surfaced while wiring the first downstream Kafka listener IT in
  `lg5-loyalty-ledger` TASK-009.
- Also pulls in [LG-83] Jib Maven plugin upgrade to 3.5.1 (transitive on
  the framework parent pom).
### Notes
- **No subagent behavior changed** in this release. Individual subagent
  versions are unchanged.

## [0.3.1] — 2026-05-10
### Changed
- Framework SHA pin bumped from `cbb6783` to `af81c7c` to honor RULE-001's
  Spring Boot 3.4.2 requirement (`cbb6783` actually shipped 3.3.5,
  discovered during consumer-service TASK-002 of `lg5-loyalty-ledger`).
- `bundle.version` in `manifest.yaml` bumped to `0.3.1` (PATCH; cross-bundle
  invariant requires every per-type manifest to agree).
### Notes
- **No subagent behavior changed** in this release. Individual subagent
  versions are unchanged.

## [0.2.0] — 2026-05-09
### Changed
- `manifest.yaml` `bundle.version` bumped to `0.3.0` to align with the
  rest of the bundle (cross-bundle invariant).
### Notes
- **No subagent content changed in this release.** All 3 subagents remain
  at individual version `0.1.0`.
- See `rules/CHANGELOG.md`, `specs/CHANGELOG.md`, and
  `commands/CHANGELOG.md` for the substantive 0.3.0 changes (constitution
  layer, SDD templates, SDD orchestrator commands).

## [0.1.0] — 2026-05-09
### Added
- `lg5-code-reviewer` — reviews diffs against the 18 hard rules and cites
  violations by stable RULE-ID.
- `lg5-test-generator` — generates IT/ATDD test scaffolds following
  RULE-012 (test profiles + base classes) and RULE-013 (Testcontainers gating).
- `lg5-planner` — decomposes a feature request into a step-by-step
  implementation plan grounded in the bundle's rules and skills.
### Notes
- Validated against `lg5-spring` SHA `cbb6783`.
- Subagents are written for OpenCode's agent format (YAML frontmatter with
  `description`, `tools`, `model`); they should be portable to Claude Code's
  subagent format with minor adaptation.
