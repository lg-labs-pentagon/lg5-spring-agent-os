# AGENTS.md — lg5-spring-agent-os (upstream template)

This file is the **upstream template** shipped by `lg5-spring-agent-os`.
Consumer repositories that install this bundle should copy or merge it into
their own root-level `AGENTS.md`.

> **Path convention.** This template assumes artifacts are installed at
> `.opencode/<artifact-type>/` in the consumer repo (the default target of
> `scripts/install.sh`). Adjust the path if your agent expects a different
> location (e.g. `.cursor/rules/`, `.continue/`).

---

## Hard rules (always-active)

The 18 hard rules below are **always active**. Each rule has its own
`rules/RULE-NNN-<slug>.md` file with full statement, rationale, examples,
anti-patterns, and references. Cite a rule by its ID in PR reviews
("violates RULE-008") so the conversation stays grounded.

| ID         | Scope         | Rule (one-liner)                                                          |
|------------|---------------|---------------------------------------------------------------------------|
| RULE-001   | framework     | Stack baseline: Spring Boot 3.4.2, Spring 6.2.2, JDK 21, Kotlin 21, Gradle/Maven. |
| RULE-002   | framework     | Parent POM `com.lg5.spring:lg5-spring-parent:1.0.0-alpha.<short-git-sha>`. |
| RULE-003   | architecture  | Hexagonal + DDD; domain core is Spring-free.                              |
| RULE-004   | architecture  | Mirror the `blank-service` module shape (8 modules).                      |
| RULE-005   | framework     | No custom framework annotations — stock Spring + Lombok only.             |
| RULE-006   | architecture  | REST controllers produce `application/vnd.api.v1+json`.                   |
| RULE-007   | kafka         | Kafka payloads must be Avro (`SpecificRecordBase`); schemas in `*-message-model`. |
| RULE-008   | outbox        | Transactional Outbox is mandatory; entity must have `@Version` + `OutboxStatus`. |
| RULE-009   | saga          | `SagaStep<T>` `@Component`; `process`/`rollback` `@Transactional` + idempotent. |
| RULE-010   | kafka         | Kafka listeners batch by default; swallow `OptimisticLock` + not-found as NO-OP. |
| RULE-011   | outbox        | Outbox scheduler implements `OutboxScheduler`, gated by `scheduling.enabled`. |
| RULE-012   | testing       | IT/ATDD: `@ActiveProfiles({"test","local"})` + extend `Lg5TestBoot[PortNone]`. |
| RULE-013   | testing       | Testcontainers opt-in via `testcontainers.<name>.enabled`.                |
| RULE-014   | framework     | Use canonical config prefixes (`kafka-config.*`, `<svc>-service.*`, …).   |
| RULE-015   | style         | `final` everywhere, records for DTOs, Kotlin only for interfaces/config.  |
| RULE-016   | architecture  | DDD building blocks come from `ddd-common-domain` (re-exported by `lg5-common-domain`). |
| RULE-017   | build         | Prefer Make targets (`make all-build`, `make run-apps`, `make run-acceptance-test`). |
| RULE-018   | reference     | Ground answers against `lg5-spring`, `food-ordering-system`, `blank-service` cloned in `/tmp/lg5-study/`. |

Severity legend: `must` (RULE-001 to 014, 016) · `should` (RULE-015, 017) · `info` (RULE-018).

---

## Skill routing table (load on demand)

When the user asks anything related to lg5-spring, building services, sagas,
outbox, kafka producers/consumers, acceptance tests, or generating new
modules, **load the relevant skill first**:

| Topic                                                       | Skill to load            |
|-------------------------------------------------------------|--------------------------|
| Overview, module map, recent changes, conventions           | `lg5-spring-overview`    |
| Scaffolding a brand-new microservice from `blank-service`   | `lg5-new-service`        |
| Implementing a `SagaStep` orchestration                     | `lg5-saga`               |
| Implementing the Transactional Outbox + scheduler           | `lg5-outbox`             |
| Kafka producer/consumer + Avro schemas                      | `lg5-kafka-avro`         |
| Acceptance tests (Cucumber + Testcontainers + Wiremock)     | `lg5-atdd`               |
| Real-world patterns from food-ordering-system               | `food-ordering-system`   |

---

## Command catalog (slash commands)

The bundle ships executable workflow commands under `commands/`. Invoke them
to drive repeatable scaffolding/refactoring tasks:

| Command                | What it does                                                        |
|------------------------|---------------------------------------------------------------------|
| `/scaffold-service`    | Scaffolds a new microservice from `blank-service` skeleton.         |
| `/add-saga`            | Adds a `SagaStep` end-to-end (publisher + listener + outbox + scheduler). |
| `/add-outbox`          | Adds an outbox (entity + DDL + helper + scheduler) for one event type. |
| `/add-kafka-listener`  | Adds a Kafka listener (batch + NO-OP exception handling per RULE-010). |

See `commands/<name>.md` for each command's full prompt and parameters.

---

## Subagent catalog (delegated specialists)

Specialized subagents the orchestrator can spawn:

| Subagent              | Purpose                                                          |
|-----------------------|------------------------------------------------------------------|
| `lg5-code-reviewer`   | Reviews diffs against the 18 hard rules; cites violations by ID. |
| `lg5-test-generator`  | Generates IT/ATDD test scaffolds following RULE-012/013 patterns. |
| `lg5-planner`         | Decomposes a feature request into rule-aligned implementation steps. |

See `subagents/<name>.md` for each subagent's role and toolset.

---

## Spec templates (spec-driven workflow)

Templates for planning artifacts under `specs/`:

| Template              | Purpose                                                          |
|-----------------------|------------------------------------------------------------------|
| `prd-template`        | Product Requirements Doc for a new service/feature.              |
| `adr-template`        | Architecture Decision Record (lightweight, lg5-aware).           |
| `microservice-spec`   | End-to-end spec example: PRD + ADR + module breakdown for a sample service. |

---

## When uncertain

- Cite the canonical source: framework path inside
  `/tmp/lg5-study/lg5-spring/...` or the real example under
  `/tmp/lg5-study/food-ordering-system/...` (RULE-018).
- Prefer copying patterns from `food-ordering-system/order-service` (the
  most complete example: REST + JPA + Kafka producer/consumer + Saga +
  Outbox + ATDD).
- Never invent framework classes. If a class isn't in the skill files, the
  rules, or the cloned repos, say so explicitly (RULE-005, RULE-018).
