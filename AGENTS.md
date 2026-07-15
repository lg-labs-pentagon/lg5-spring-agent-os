# AGENTS.md — lg5-spring-agent-os (upstream template)

This file is the **upstream template** shipped by `lg5-spring-agent-os`.
Consumer repositories that install this bundle should copy or merge it
into their own root-level `AGENTS.md`.

> **Path convention.** This template assumes artifacts are mounted at
> `.agent-os/` in the consumer repo (the default target of git-submodule
> integration). Adjust if your agent expects a different location.

---

## Spec-Driven Development workflow (read this if doing a feature)

This bundle implements the **spec-anchored** variant of SDD described by
[Fowler & Böckeler](https://martinfowler.com/articles/exploring-gen-ai/sdd-3-tools.html),
borrowing structural ideas from
[GitHub spec-kit](https://github.com/github/spec-kit).

```
  /sdd-intent    /sdd-specify   /sdd-plan       /sdd-design       /sdd-tasks    /sdd-implement   /sdd-verify
   (optional)
      │              │              │                 │                │              │              │
      ▼              ▼              ▼                 ▼                ▼              ▼              ▼
   intent.md  ►   prd.md     ►  plan.md + adr/  ►  design.md      ►  tasks.md   ►  code + tests ►  verify-report.md
   (why,          (what,        (architecture)     + data-model.md   (atomic)       + commit       (AC ✓/✗ per REQ,
    framing)       functional)                     (detailed how)    (TASK-NNN)     (per task,      gate decision)
                                                                                     loop)
      │              │              │                 │                │              │              │
      └── HUMAN ─────┴── HUMAN ─────┴── HUMAN ────────┴── HUMAN ──────┴── HUMAN ────┴── HUMAN ──────►
          APPROVES       APPROVES       APPROVES          APPROVES        APPROVES       APPROVES
```

### Quick-path (for trivial changes)

```
  /sdd-quick                                                              /sdd-implement   /sdd-verify
      │                                                                          │              │
      ▼                                                                          ▼              ▼
   quick-spec.md  ──────────────────────────────────────────────────────►  code + tests  ►  verify-report.md
   (compressed                                                                + commit       (mandatory gate)
    ~40 lines)
      │                                                                          │              │
      └─────────────────────────── HUMAN ───────────────────────────────────────┴── HUMAN ─────►
                                   APPROVES                                       APPROVES
```

> **Intent** (phase 0) is **optional** — skip when the idea is mature.
> **Verify** (phase 6) is **mandatory and bloqueante** for BOTH paths —
> a red gate blocks spec closure unless overridden by an explicit
> `tech-debt` ADR.
>
> **Quick-path** is for **trivial changes only** (1 endpoint, 1 entity,
> 1 listener, 1 field, 1 config). The `/sdd-quick` command enforces a
> 10-criterion eligibility gate: sagas, new outboxes, new aggregates,
> new Avro schemas, multi-module changes, and breaking API changes are
> all rejected and routed to the full path.
>
> Use `/sdd-orchestrate <NNN-slug>` (or with no arg, for a multi-spec
> dashboard) to inspect a spec's state and get the recommended next phase.

Per-feature artifacts live under `docs/specs/<NNN-slug>/` in the consumer
repo. See [`specs/README.md`](specs/README.md) for the full layout and
[`specs/examples/loyalty-ledger/`](specs/examples/loyalty-ledger/) for an
end-to-end example.

---

## Constitution (15 immutable rules)

The 15 rules with `severity: must` form the **constitution**. They are
immutable and bind every PRD/Plan/Task/code change. See
[`rules/CONSTITUTION.md`](rules/CONSTITUTION.md) for the full index +
rules of engagement, and [`rules/RULE-NNN-*.md`](rules/) for each rule's
statement, rationale, examples, and anti-patterns.

| ID         | Const? | Scope         | One-liner                                                                  |
|------------|:------:|---------------|----------------------------------------------------------------------------|
| RULE-001   | ✅ | framework     | Stack baseline: Spring Boot 4.0.0, Spring 7.0.1, JDK 25, Kotlin JVM 21, Gradle/Maven. |
| RULE-002   | ✅ | framework     | Parent POM `com.lg5.spring:lg5-spring-parent:1.0.0-alpha.<short-git-sha>`. |
| RULE-003   | ✅ | architecture  | Hexagonal + DDD; domain core is Spring-free.                               |
| RULE-004   | ✅ | architecture  | Mirror the `blank-service` module shape (8 modules).                       |
| RULE-005   | ✅ | framework     | No custom framework annotations — stock Spring + Lombok only.              |
| RULE-006   | ✅ | architecture  | REST controllers produce `application/vnd.api.v1+json`.                    |
| RULE-007   | ✅ | kafka         | Kafka payloads must be Avro (`SpecificRecordBase`); schemas in `*-message-model`. |
| RULE-008   | ✅ | outbox        | Transactional Outbox is mandatory; entity must have `@Version` + `OutboxStatus`. |
| RULE-009   | ✅ | saga          | `SagaStep<T>` `@Component`; `process`/`rollback` `@Transactional` + idempotent. |
| RULE-010   | ✅ | kafka         | Kafka listeners batch by default; swallow `OptimisticLock` + not-found as NO-OP. |
| RULE-011   | ✅ | outbox        | Outbox scheduler implements `OutboxScheduler`, gated by `scheduling.enabled`. |
| RULE-012   | ✅ | testing       | IT/ATDD: `@ActiveProfiles({"test","local"})` + extend `Lg5TestBoot[PortNone]`. |
| RULE-013   | ✅ | testing       | Testcontainers opt-in via `testcontainers.<name>.enabled`.                 |
| RULE-014   | ✅ | framework     | Use canonical config prefixes (`kafka-config.*`, `<svc>-service.*`, …).    |
| RULE-015   | ⚠ | style         | `final` everywhere, records for DTOs, Kotlin only for interfaces/config.   |
| RULE-016   | ✅ | architecture  | DDD blocks come from `ddd-common-domain` (re-exported by `lg5-common-domain`). |
| RULE-017   | ⚠ | build         | Prefer Make targets (`make all-build`, `make run-apps`, `make run-acceptance-test`). |
| RULE-018   | ⚠ | reference     | Ground answers against `lg5-spring`, `food-ordering-system`, `blank-service` cloned in `/tmp/lg5-study/`. |

Legend: ✅ constitutional (`severity: must`) · ⚠ advisory (`should`/`info`).

---

## Skill routing table (load on demand)

When the user asks anything related to lg5-spring, **load the relevant skill**:

| Topic                                                       | Skill                    |
|-------------------------------------------------------------|--------------------------|
| Overview, module map, recent changes, conventions           | `lg5-spring-overview`    |
| Scaffolding a brand-new microservice from `blank-service`   | `lg5-new-service`        |
| Implementing a `SagaStep` orchestration                     | `lg5-saga`               |
| Implementing the Transactional Outbox + scheduler           | `lg5-outbox`             |
| Kafka producer/consumer + Avro schemas                      | `lg5-kafka-avro`         |
| Acceptance tests (Cucumber + Testcontainers + Wiremock)     | `lg5-atdd`               |
| Real-world patterns from food-ordering-system               | `food-ordering-system`   |
| GitHub Actions CI pipeline + Maven-credentials action       | `lg5-github-actions`     |
| OpenAPI / AsyncAPI HTML doc sites (Swagger UI + Studio)     | `lg5-api-docs`           |
| Allure Report wiring (Cucumber 7 + JUnit Platform)          | `lg5-allure-report`      |
| Unified VitePress docs site (Pages + Firebase + previews)   | `lg5-vitepress-docs`     |

---

## Command catalog

Two categories: **SDD orchestrators** drive the workflow phases;
**building blocks** are invoked from inside `/sdd-implement` to actually
generate code.

### SDD orchestrators

| Command                          | Phase     | What it does                                                            |
|----------------------------------|-----------|-------------------------------------------------------------------------|
| `/sdd-intent <slug> "<idea>"`    | 0 (opt.)  | Frame an informal idea as a one-page intent (why, who, outcome, non-goals). |
| `/sdd-specify <slug> "<desc>"`   | 1         | Convert informal prompt (or approved intent) → functional PRD (tech-free). |
| `/sdd-plan <NNN-slug>`           | 2         | Generate `plan.md` + ADRs (architecture only) from approved PRD.        |
| `/sdd-design <NNN-slug>`         | 3         | Generate `design.md` + `data-model.md` (detailed contracts, schemas, configs). |
| `/sdd-tasks <NNN-slug>`          | 4         | Decompose Design into atomic `TASK-NNN` with Given/When/Then AC.        |
| `/sdd-implement <TASK-NNN>`      | 5         | Execute ONE task (code + tests + commit). Loops by re-invocation.       |
| `/sdd-verify <NNN-slug>`         | 6         | Cross-check every AC against test evidence; gate decision blocks closure. |
| `/sdd-orchestrate [<NNN-slug>]`  | meta      | Inspect spec state; recommend the next phase command. Read-only helper. |
| `/sdd-quick <slug> "<desc>"`     | quick     | Quick-path for trivial changes — 1 endpoint, 1 entity, 1 listener, 1 field, or 1 config. Compressed quick-spec.md (~40 lines); rejects sagas/outboxes/multi-module changes; goes directly to `/sdd-implement`. `/sdd-verify` mandatory. |

### Building blocks (called from inside /sdd-implement)

| Command                | What it does                                                          |
|------------------------|-----------------------------------------------------------------------|
| `/scaffold-service`    | Scaffolds a new microservice from `blank-service` skeleton.           |
| `/add-saga`            | Adds a `SagaStep` end-to-end (publisher + listener + outbox + scheduler). |
| `/add-outbox`          | Adds an outbox (entity + DDL + helper + scheduler) for one event type. |
| `/add-kafka-listener`  | Adds a Kafka listener (batch + NO-OP exception handling per RULE-010). |
| `/scaffold-ci-cd`      | Installs the canonical CI pipeline (workflow + composite action + API doc templates + Allure wiring) into a consumer service. |
| `/scaffold-docs`       | Installs the unified VitePress documentation site (`docs/site/` aggregator + 6 CI jobs + Firebase config) into a consumer service. |
| `/add-rest-endpoint`   | Adds a REST endpoint (controller method + DTOs + service port + handler + mapper + OpenAPI fragment + IT) per RULE-003/004/005/006/012. |
| `/add-jpa-entity`      | Adds a JPA aggregate (domain entity + value-object id + repository port + JPA entity + Spring Data repo + adapter + MapStruct mapper + Liquibase changelog + IT) per RULE-003/004/015/016. |

See `commands/<name>.md` for each command's full prompt and parameters.

---

## How to invoke the bundle's agents

All bundle subagents have `mode: subagent` — they're specialists invoked from
within an SDD phase, not primary chat partners. That has two practical
consequences in OpenCode:

- **Tab does NOT cycle through bundle subagents.** Tab is for `primary`
  agents only (Build, Plan, plus any custom primary you configure in
  `.opencode/agent.toml`). Pressing Tab after installing the bundle and
  seeing nothing new is **expected**.
- **Use `@` mentions to invoke bundle subagents.** Type `@` from any
  primary-agent chat to surface the subagent picker: `@sdd-planner help me
  plan feature 001`. The picker reads `.opencode/agents/` (which this bundle
  populates via `install.sh`).

In practice you rarely `@`-mention manually — the `/sdd-*` slash commands
automatically dispatch to the right subagent under the hood (`/sdd-plan`
invokes `sdd-planner`, `/sdd-tasks` invokes `sdd-tasker`, etc.). The three
cross-cutting subagents (`lg5-code-reviewer`, `lg5-test-generator`,
`lg5-ci-cd-engineer`) are the typical `@`-mention targets when you need a
spot-check outside the SDD flow.

> **Troubleshooting.** If `@<tab>` surfaces a phantom `CHANGELOG` entry
> instead of the real subagents, you're on a pre-`4.1.1` install — that
> bug (issue #15) was fixed by switching from folder-level symlinks to
> per-entry symlinks under `.opencode/{agents,commands,skills}/`. Re-run
> `.agent-os/scripts/install.sh` against bundle `>= 4.1.1` to refresh.

> **Model selection (since v4.3.0).** Bundle subagents intentionally do
> **not** declare a `model:` field — they inherit the consumer's
> **default model** at invocation time. This makes the bundle portable
> across providers (Anthropic, OpenAI, Gemini, GitHub Copilot, …). If
> you see `Model not found: …` errors on a pre-`4.3.0` install,
> upgrade to `>= v4.4.0` (latest release). To pin a specific model for a specific
> subagent, edit the symlinked file in your fork of `.agent-os/subagents/`
> and add `model: <provider>/<id>` to the frontmatter — the validator
> allows either presence (any string) or absence.

See [opencode.ai/docs/agents](https://opencode.ai/docs/agents/) for the
upstream documentation of `primary` vs `subagent` modes.

---

## Subagent catalog

Cross-cutting (apply to any phase):

| Subagent              | Purpose                                                          |
|-----------------------|------------------------------------------------------------------|
| `lg5-code-reviewer`   | Reviews diffs against the 18 rules; cites violations by RULE-ID. |
| `lg5-test-generator`  | Generates IT/ATDD test scaffolds (RULE-012/013 patterns).        |
| `lg5-ci-cd-engineer`  | Specialist for CI/CD pipelines (GitHub Actions topology, Maven-creds action, API docs, Allure, supply-chain hardening). |

SDD phase specialists (1:1 with the seven `/sdd-*` phase commands plus
a meta-orchestrator):

| Subagent           | Phase       | Pairs with           | Purpose                                                                                          |
|--------------------|-------------|----------------------|--------------------------------------------------------------------------------------------------|
| `sdd-intender`     | Intent (0)  | `/sdd-intent`        | Informal idea → one-page `intent.md` (problem, users, outcome, non-goals). Optional first phase. |
| `sdd-specifier`    | Specify (1) | `/sdd-specify`       | Informal prompt (or approved intent) → tech-free PRD with REQ-NNN + clarifications.              |
| `sdd-planner`      | Plan (2)    | `/sdd-plan`          | PRD → `plan.md` + ADRs (architecture only; cites RULE-NNN).                                      |
| `sdd-designer`     | Design (3)  | `/sdd-design`        | Plan + ADRs → `design.md` + `data-model.md` (concrete contracts, schemas, JPA, configs).         |
| `sdd-tasker`       | Tasks (4)   | `/sdd-tasks`         | Design → atomic `TASK-NNN` with Given/When/Then AC.                                              |
| `sdd-implementer`  | Implement (5) | `/sdd-implement`   | One TASK → code + tests + `lg5-code-reviewer` + commit.                                          |
| `sdd-verifier`     | Verify (6)  | `/sdd-verify`        | Cross-check every AC against test evidence; produce gate decision (VERIFIED / OVERRIDE / NOT).   |
| `sdd-orchestrator` | meta        | `/sdd-orchestrate`   | Inspect spec state; recommend next phase. Read-only. Never produces feature artifacts.           |
| `sdd-quicker`      | Quick       | `/sdd-quick`         | Trivial-change Quick-path. Produces `quick-spec.md` (~40 lines); enforces 10-criterion eligibility gate. Rejects sagas, new outboxes, new aggregates, new Avro schemas, multi-module changes. |

---

## Spec templates

Under [`specs/templates/`](specs/templates/):

| Template                   | Used by             | Purpose                                                  |
|----------------------------|---------------------|----------------------------------------------------------|
| `intent-template`          | `/sdd-intent`       | One-page intent: problem, users, outcome, non-goals (pre-PRD framing). |
| `quick-spec-template`      | `/sdd-quick`        | Compressed single-page spec (~40 lines) for trivial changes. Replaces Specify+Plan+Design+Tasks. |
| `prd-template`             | `/sdd-specify`      | Functional PRD (REQ-NNN with AC; tech-free).             |
| `plan-template`            | `/sdd-plan`         | Module map, ADR index, dep graph, risks (architecture only). |
| `adr-template`             | `/sdd-plan`         | Lightweight ADR with constitutional impact section.      |
| `design-template`          | `/sdd-design`       | Detailed contracts, schemas, JPA, configs, module graph. |
| `data-model-template`      | `/sdd-design`       | Aggregates, events, outbox, REST DTOs, Avro, JPA.        |
| `tasks-template`           | `/sdd-tasks`        | Atomic TASK-NNN with Given/When/Then AC + DoD checklist. |
| `verify-report-template`   | `/sdd-verify`       | AC↔evidence matrix, constitutional check, gate decision. |
| `research-template`        | (manual)            | Optional time-boxed spike doc.                           |

End-to-end example: [`specs/examples/loyalty-ledger/`](specs/examples/loyalty-ledger/).

---

## When uncertain

- Cite the canonical source: framework path inside
  `/tmp/lg5-study/lg5-spring/...` or the real example under
  `/tmp/lg5-study/food-ordering-system/...` (RULE-018).
- Prefer copying patterns from `food-ordering-system/order-service` (the
  most complete example: REST + JPA + Kafka producer/consumer + Saga +
  Outbox + ATDD).
- Never invent framework classes. If a class isn't in the skill files,
  the rules, or the cloned repos, say so explicitly (RULE-005, RULE-018).
- Never override a constitutional rule (`severity: must`) without a
  dedicated ADR justifying the override and time-boxing the deviation.
