# lg5-spring-agent-os

> Versioned **agent operating system** for building microservices on top of the
> [`lg5-spring`](https://github.com/lg-labs-pentagon/lg5-spring) framework.

This repository ships a curated, validated set of **agent context artifacts**
— the things AI coding agents (OpenCode, Claude Code, Cursor, Continue,
Copilot, etc.) need to be productive on services that follow the lg5-spring
conventions.

Current bundle: **v0.3.2** · Validated against `lg5-spring` SHA: **`d0d754a`**.

---

## What's inside

```
lg5-spring-agent-os/
├── AGENTS.md                                  # always-loaded index + skill routing table + rule cheat sheet
├── skills/                                    # 7 thematic skills (load on demand)
│   ├── manifest.yaml
│   ├── CHANGELOG.md
│   ├── lg5-spring-overview/SKILL.md
│   ├── lg5-new-service/SKILL.md
│   ├── lg5-saga/SKILL.md
│   ├── lg5-outbox/SKILL.md
│   ├── lg5-kafka-avro/SKILL.md
│   ├── lg5-atdd/SKILL.md
│   └── food-ordering-system/SKILL.md
├── rules/                                     # 18 always-active hard rules (15 form the constitution)
│   ├── manifest.yaml
│   ├── CHANGELOG.md
│   ├── CONSTITUTION.md                        # index of constitutional rules + rules of engagement
│   └── RULE-001-stack-baseline.md … RULE-018-reference-projects.md
├── commands/                                  # 8 slash commands (4 SDD orchestrators + 4 building-blocks)
│   ├── manifest.yaml
│   ├── CHANGELOG.md
│   ├── sdd-specify.md                         # SDD: informal prompt → PRD
│   ├── sdd-plan.md                            # SDD: PRD → plan + ADRs + data-model
│   ├── sdd-tasks.md                           # SDD: plan → atomic TASK-NNN
│   ├── sdd-implement.md                       # SDD: execute one TASK-NNN end-to-end
│   ├── scaffold-service.md
│   ├── add-saga.md
│   ├── add-outbox.md
│   └── add-kafka-listener.md
├── subagents/                                 # 3 specialized subagents
│   ├── manifest.yaml
│   ├── CHANGELOG.md
│   ├── lg5-code-reviewer.md
│   ├── lg5-test-generator.md
│   └── lg5-planner.md
├── specs/                                     # spec-driven workflow templates + examples
│   ├── manifest.yaml
│   ├── CHANGELOG.md
│   ├── README.md                              # SDD workflow overview
│   ├── templates/
│   │   ├── prd-template.md
│   │   ├── adr-template.md
│   │   ├── plan-template.md
│   │   ├── tasks-template.md
│   │   ├── data-model-template.md
│   │   └── research-template.md
│   └── examples/loyalty-ledger/               # end-to-end SDD example (PRD+plan+tasks+ADRs+data-model)
├── scripts/
│   ├── validate.sh                            # CI / local sanity checks for all artifact types
│   └── install.sh                             # install into a consumer repo
├── .github/workflows/validate.yml             # CI runs validate.sh on push/PR
├── CONTRIBUTING.md
└── LICENSE
```

### Artifact type cheat sheet

| Artifact   | Format                                                  | When loaded         | What it does                                                  |
|------------|---------------------------------------------------------|---------------------|---------------------------------------------------------------|
| **rule**     | `<RULE-ID>-<slug>.md` with frontmatter (id, severity, scope) | Always-active   | Hard constraints, cited in PR review by stable ID.            |
| **skill**    | `<dir>/SKILL.md` with frontmatter                      | On demand by topic  | Deep recipes (saga, outbox, kafka, atdd, scaffolding, …).     |
| **command**  | `<name>.md` with frontmatter (description, argument-hint, allowed-tools) | On user `/invocation` | Repeatable workflows (scaffold service, add saga, etc.).  |
| **subagent** | `<name>.md` with frontmatter (name, description, tools, model) | Spawned by orchestrator | Delegated specialists (code-reviewer, test-generator, planner). |
| **spec**     | `<name>.md` with frontmatter (kind, name, version)     | Read at planning time | PRD/ADR templates + example spec for spec-driven workflow.   |

### Inventory at v0.3.2

- **18 rules** (15 constitutional / `severity: must`, 2 `should`, 1 `info`).
  Scopes: framework (4), architecture (5), kafka (2), outbox (2), saga (1),
  testing (2), style (1), build (1), reference (1). Indexed in
  [`rules/CONSTITUTION.md`](rules/CONSTITUTION.md).
- **7 skills** (`lg5-spring-overview`, `lg5-new-service`, `lg5-saga`,
  `lg5-outbox`, `lg5-kafka-avro`, `lg5-atdd`, `food-ordering-system`).
- **8 commands**:
  - 4 SDD orchestrators (`/sdd-specify`, `/sdd-plan`, `/sdd-tasks`, `/sdd-implement`)
  - 4 building blocks (`/scaffold-service`, `/add-saga`, `/add-outbox`, `/add-kafka-listener`)
- **3 subagents** (`lg5-code-reviewer`, `lg5-test-generator`, `lg5-planner`).
- **6 spec templates + 1 worked example**: `prd-template`, `plan-template`,
  `tasks-template`, `data-model-template`, `adr-template`, `research-template`,
  plus the end-to-end [`examples/loyalty-ledger/`](specs/examples/loyalty-ledger/)
  spec set.
- All artifacts validated against `lg5-spring` SHA `d0d754a`.

---

## Spec-Driven Development workflow

This bundle implements the **spec-anchored** SDD variant described by
[Fowler & Böckeler](https://martinfowler.com/articles/exploring-gen-ai/sdd-3-tools.html),
borrowing the four-phase command chain from
[GitHub spec-kit](https://github.com/github/spec-kit). Specs live alongside
the code they describe, are kept in sync with it, and remain editable —
they are not the single source of truth (which is still the code), but they
are the single source of **intent**.

```
   /sdd-specify     /sdd-plan         /sdd-tasks        /sdd-implement
       │                │                  │                  │
       ▼                ▼                  ▼                  ▼
     prd.md   ──►  plan.md + adr/  ──►  tasks.md   ──►   code + tests
                  + data-model.md       (TASK-NNN)        + commit (loop)
   (functional)   (technical)           (atomic)
       │                │                  │                  │
       └─ HUMAN ────────┴────── HUMAN ─────┴── HUMAN ────────►
          APPROVES        APPROVES          APPROVES
```

Per-feature artifacts live in the **consumer** repo at
`docs/specs/<NNN-slug>/` (e.g. `001-loyalty-ledger/`):

```
docs/specs/001-loyalty-ledger/
├── prd.md            # functional requirements (REQ-NNN), no technology
├── plan.md           # module map, dep graph, risks
├── tasks.md          # atomic TASK-NNN with Given/When/Then AC
├── data-model.md     # aggregates, events, outbox, REST DTOs, Avro, JPA
├── research.md       # (optional) time-boxed spike notes
└── adr/
    ├── ADR-001-<slug>.md
    └── ADR-002-<slug>.md
```

Approval gates exist **between phases**, not between individual TASKs.
Inside Build, `/sdd-implement TASK-NNN` is invoked per task and produces
exactly one commit (`feat(TASK-NNN): <title>`).

Read [`specs/README.md`](specs/README.md) for the full workflow guide and
[`specs/examples/loyalty-ledger/`](specs/examples/loyalty-ledger/) for an
end-to-end worked example.

### Constitution

The 15 rules with `severity: must` form the **constitution**: immutable
constraints that bind every PRD/Plan/Task/code change. ADRs that override a
constitutional rule must justify the override and time-box the deviation.
See [`rules/CONSTITUTION.md`](rules/CONSTITUTION.md).

---

## Why "agent OS"?

We follow the emerging convention (BuilderMethods'
[`agent-os`](https://github.com/buildermethods/agent-os), Anthropic's
[Agent Skills](https://www.anthropic.com/news/agent-skills)) of treating
these artifacts as a unified **operating layer** for AI agents — analogous
to how a traditional OS bundles kernel + shell + utilities + drivers. Naming
the repo after a single artifact type (`-skills`, `-rules`) would lock us in.

---

## Versioning

Follows [Semantic Versioning 2.0.0](https://semver.org/spec/v2.0.0.html):

- **MAJOR** — breaking re-organization (artifact renames/deletions, removal
  of mandatory rules, change in install layout).
- **MINOR** — new artifact, new artifact type, new section in an existing
  artifact, validation against a new framework SHA.
- **PATCH** — clarifications, anti-pattern additions, no recipe change.

Every release is tagged (`v0.1.0`, `v0.2.0`, `v0.3.0`, `v0.3.1`, `v0.3.2`, …) and pinned to a single
`lg5-spring-sha`. The `bundle.lg5-spring-sha` and `bundle.version` fields
are identical across all per-type `manifest.yaml` files (CI-enforced).

### Compatibility matrix

| Bundle version | lg5-spring SHA | Released   | Highlights |
|---------------:|----------------|------------|------------|
| `0.1.0`        | `cbb6783`      | 2026-05-09 | 7 skills only; bundle name `lg5-spring-skills`. |
| `0.2.0`        | `cbb6783`      | 2026-05-09 | Rebranded to `lg5-spring-agent-os`; added 18 rules + 4 commands + 3 subagents + 2 spec templates + 1 example spec. Same skill content as 0.1.0. |
| `0.3.0`        | `cbb6783`      | 2026-05-09 | SDD adoption: `CONSTITUTION.md` + `constitutional` rule frontmatter; 4 SDD orchestrator commands (`/sdd-{specify,plan,tasks,implement}`); specs reorg into `templates/` + per-feature folder example (`loyalty-ledger`); 4 new templates (plan/tasks/data-model/research). No skill content changes. |
| `0.3.1`        | `af81c7c`      | 2026-05-10 | PATCH: framework SHA pin bumped to honor RULE-001's Spring Boot 3.4.2 mandate (`cbb6783` actually shipped 3.3.5; discovered during consumer-service TASK-002 of `lg5-loyalty-ledger`). `af81c7c` bundles the Spring Boot 3.4.2 upgrade (`e5139d0`), `ConfluentKafkaContainerCustomConfig` (`5fb16aa`), and CI/docs updates. No rule/skill/command/subagent/spec contracts changed. |
| `0.3.2`        | `d0d754a`      | 2026-05-10 | PATCH: framework SHA pin bumped to ship the [`ConfluentKafkaContainerCustomConfig` in-network Kafka listener fix](https://github.com/lg-labs-pentagon/lg5-spring/pull/1) — companion containers (Schema Registry, app-in-container) can now reach the broker via `kafka:19092` instead of the host-mapped `localhost:<random-port>`. Also pulls in [LG-83] Jib Maven plugin upgrade to 3.5.1 (transitive on the framework parent pom). Surfaced while wiring the first downstream Kafka listener IT in `lg5-loyalty-ledger` TASK-009. No rule/skill/command/subagent/spec contracts changed. |

---

## How to consume from a microservice repo

Pick **one** of the three integration modes below.

### Mode A — Git submodule (recommended for monorepo-style governance)

```bash
cd your-microservice-repo
git submodule add -b main https://github.com/lg-labs-pentagon/lg5-spring-agent-os.git .lg5-agent-os
git submodule update --init

# Install into the agent's expected locations
.lg5-agent-os/scripts/install.sh .opencode

# Pin to a specific release
git -C .lg5-agent-os checkout v0.3.2
git add .gitmodules .lg5-agent-os && git commit -m "chore(agents): pin lg5-spring-agent-os v0.3.2"
```

Pros: explicit, audit-friendly, the consumer sees exactly which SHA is in use.
Cons: developers need `git submodule update --init --recursive` after clone.

### Mode B — Plain copy at a tag (no submodule overhead)

```bash
cd your-microservice-repo
curl -sL https://github.com/lg-labs-pentagon/lg5-spring-agent-os/archive/refs/tags/v0.3.2.tar.gz \
  | tar -xz -C /tmp
/tmp/lg5-spring-agent-os-0.3.2/scripts/install.sh .opencode
git add .opencode && git commit -m "chore(agents): install lg5-spring-agent-os@0.3.2"
```

Pros: zero submodule machinery; agent state is self-contained in the consumer.
Cons: harder to upgrade (re-run the install at the new tag, review diff).

### Mode C — Sparse checkout (large monorepos, partial install)

```bash
git clone --filter=blob:none --no-checkout https://github.com/lg-labs-pentagon/lg5-spring-agent-os.git .lg5-agent-os
git -C .lg5-agent-os sparse-checkout init --cone
git -C .lg5-agent-os sparse-checkout set rules skills/lg5-saga skills/lg5-outbox commands
git -C .lg5-agent-os checkout v0.3.2
.lg5-agent-os/scripts/install.sh .opencode
```

---

## Consumer install layout

`scripts/install.sh <opencode-dir>` produces:

```
<opencode-dir>/
├── skills/                 ← copied from this repo's skills/
├── rules/                  ← copied from this repo's rules/
├── commands/               ← copied from this repo's commands/
├── subagents/              ← copied from this repo's subagents/
├── specs/                  ← copied from this repo's specs/
└── .bundle-version         ← bundle version marker
```

`AGENTS.md` is **not** touched — the consumer repo owns it and merges
upstream rules manually (otherwise per-repo customizations would be wiped on
every upgrade). Use the upstream `AGENTS.md` in this repo as a template:
copy it, then add your service-specific overrides at the bottom.

---

## Validation

```bash
bash scripts/validate.sh
```

The validator runs one check function per artifact type that exists on
disk, plus cross-bundle invariants. Specifically:

- **skills** — `SKILL.md` + `CHANGELOG.md` per dir; YAML frontmatter
  (`name`, `version`, `lg5-spring-sha`, `description`); SemVer; name ↔
  directory match; bundle-wide `lg5-spring-sha` consistency; manifest ↔
  disk parity; no forbidden `/tmp/` paths in fenced code blocks (only
  `/tmp/lg5-study/` is allowed).
- **rules** — `RULE-NNN-<slug>.md` files; frontmatter (`id`, `slug`,
  `version`, `lg5-spring-sha`, `severity`, `scope`, `tags`, `description`);
  filename ↔ id+slug match; severity ∈ {`must`, `should`, `info`}; scope ∈
  9 known values; manifest ↔ disk parity.
- **commands** — `<name>.md` files; frontmatter (`description`,
  `argument-hint`, `allowed-tools`); manifest ↔ disk parity.
- **subagents** — `<name>.md` files; frontmatter (`name`, `description`,
  `tools`, `model`); name ↔ filename match; manifest ↔ disk parity.
- **specs** — templates and examples; frontmatter (`kind`, `name`,
  `version`, `description`); kind ∈ {`template`, `example`}.
- **cross-bundle** — every `<type>/manifest.yaml` declares the same
  `bundle.lg5-spring-sha` and `bundle.version`.

The same script runs in CI on every push and PR
(`.github/workflows/validate.yml`).

---

## Contributing

See [CONTRIBUTING.md](./CONTRIBUTING.md). TL;DR:

1. Branch off `main`.
2. Add or modify an artifact (mirror the existing structure for that type).
3. Update the relevant `<type>/CHANGELOG.md` and (if bumping the artifact's
   own version) the entry in `<type>/manifest.yaml`.
4. If this is a bundle-wide release, bump `bundle.version` in EVERY
   `<type>/manifest.yaml` and add a top-level entry in this README's
   compatibility matrix.
5. Run `bash scripts/validate.sh` until green.
6. Open a PR with a Conventional Commits title (e.g. `feat(rules): add
   RULE-019 …`).
7. Maintainer tags a new bundle release after merge.

---

## License

See [LICENSE](./LICENSE).
