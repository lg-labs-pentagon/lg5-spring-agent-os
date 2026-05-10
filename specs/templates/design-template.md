---
kind: template
name: design-template
version: 0.1.0
description: Detailed technical design derived from an approved Plan + ADRs. Owns concrete class signatures, REST contracts, Avro schemas, JPA model, configs. Used by /sdd-design. Consumed by /sdd-tasks. Pairs with data-model.md.
---

# Design — `<feature-name>`

> **Use this template via `/sdd-design`.** Replace every `<placeholder>`.
> The Design is the **how-at-the-class-level**: concrete signatures,
> contracts, schemas, configs, dependencies. By the time `/sdd-tasks`
> runs, every design choice must already live here.
>
> Anchor: [`plan.md`](plan.md), [`adr/`](adr/), [`data-model.md`](data-model.md).
> Constitutional rules cited by stable RULE-ID (see
> [`rules/CONSTITUTION.md`](../../../rules/CONSTITUTION.md)).

## 1. Scope and boundaries

What is in/out of this design. Reference the Plan's module map — every
section below must point at a concrete module under `<svc>-*`.

- **In design**: `<modules + REQ coverage>`
- **Out of design**: `<deferred or covered elsewhere>`

## 2. Domain model (sketch)

> Aggregates, entities, value objects, invariants. Full field-level
> detail lives in [`data-model.md`](data-model.md) §1; this section is
> the **navigable index**.

| Aggregate | Module | Invariants (1-liner) | Detailed in |
|-----------|--------|----------------------|-------------|
| `<Aggregate>` | `<svc>-domain-core` | `<rule>` | `data-model.md §1.1` |

## 3. REST contracts (RULE-006)

> Endpoints, HTTP verbs, request/response shapes, status codes, error
> envelopes. All `Content-Type: application/vnd.api.v1+json`.

| Endpoint | Verb | Module | Request DTO | Response DTO | Success | Errors |
|----------|------|--------|-------------|--------------|---------|--------|
| `/api/v1/<resource>` | `POST` | `<svc>-api` | `<Req>` | `<Resp>` | `201` | `400, 409, 422` |

DTO signatures (records — RULE-015):

```java
public record <Req>(<fields>) {}
public record <Resp>(<fields>) {}
```

## 4. Kafka contracts (RULE-007, RULE-010)

> Topics, payloads (Avro), partitioning, consumer group, batch semantics.
> Schemas are committed under `<svc>-message-model/src/main/resources/avro/`
> and indexed in [`data-model.md`](data-model.md) §3.

| Topic | Direction | Avro schema | Key | Partitions | Consumer group | Batch |
|-------|-----------|-------------|-----|-----------:|----------------|------:|
| `<svc>.<event>.v1` | out | `<EventNameAvro>.avsc` | `<aggregateId>` | `<n>` | — | — |
| `<other>.<event>.v1` | in | `<EventNameAvro>.avsc` | `<aggregateId>` | `<n>` | `<svc>-<purpose>-cg` | `<n>` |

NO-OP exception handling per RULE-010: `OptimisticLockingFailureException`
and not-found are swallowed; everything else escalates to the listener
container's default error handler.

## 5. Persistence model (RULE-008)

> JPA entities, tables, indices, FKs, Flyway migrations. Full DDL in
> [`data-model.md`](data-model.md) §4.

| Entity | Table | Module | Key migration | Notes |
|--------|-------|--------|---------------|-------|
| `<Entity>JpaEntity` | `<table>` | `<svc>-data-access` | `V<NNN>__<slug>.sql` | `<note>` |

Outbox (mandatory when publishing to Kafka — RULE-008): every aggregate
that emits events has a dedicated `*_outbox` table with `@Version` and
`OutboxStatus`.

## 6. Saga design (RULE-009) — _if applicable_

> For each `SagaStep<T>`: the type T, idempotency key, transitions,
> compensation. Skip the whole section if no saga (justify in §10).

### 6.1 `<SagaStepName>Step` : `SagaStep<<T>>`

- **Module**: `<svc>-domain-core` (interface) + `<svc>-application-service` (impl).
- **Trigger**: `<event or REST call>`.
- **Idempotency key**: `<aggregateId + sagaId + step>`.
- **Process transaction**: `<state-A>` → `<state-B>`; emits `<EventX>`.
- **Rollback transaction**: `<state-B>` → `<state-A>`; emits `<EventXCancelled>`.
- **Failure modes**: timeout (consumer retries by NO-OP), invalid state
  transition (swallowed as NO-OP — RULE-010).

## 7. Configuration (RULE-014)

> Canonical prefixes only. List the new/changed properties.

```yaml
<svc>-service:
  <feature>:
    <key>: <default>   # <purpose>
kafka-config:
  <producer or consumer override>
scheduling:
  enabled: true        # gates outbox scheduler (RULE-011)
```

| Property | Default | Required | Profile | Scope |
|----------|---------|---------:|---------|-------|
| `<svc>-service.<feature>.<key>` | `<value>` | yes/no | `<test/local/prod>` | `<purpose>` |

## 8. Module dependency graph

```
<svc>-api ──► <svc>-application-service ──► <svc>-domain-core
                       │                            ▲
                       ▼                            │
                <svc>-data-access ─────────────────-┘
                       ▲
<svc>-message-core ────┘
        ▲
<svc>-message-model
```

Justify any new edge that the Plan did not already anticipate.

## 9. Test design (guidance for `/sdd-tasks`)

> Maps each REQ-NNN to its test home. `sdd-tasker` uses this to
> generate TASKs; `sdd-verifier` uses it to cross-check AC coverage.

| REQ | Test type | Lives in | Asserts |
|-----|-----------|----------|---------|
| REQ-001 | unit (JUnit) | `<svc>-domain-core/src/test/...` | invariant `<X>` holds |
| REQ-002 | IT (`Lg5TestBoot`) | `<svc>-application-service/src/test/...` | `<saga step transitions>` |
| REQ-003 | ATDD (Cucumber) | `<svc>-acceptance-test/.../features/...` | end-to-end via REST + Kafka |

Test profiles: `@ActiveProfiles({"test","local"})` + base class
`Lg5TestBoot[PortNone]` (RULE-012). Testcontainers opt-in via
`testcontainers.<name>.enabled` (RULE-013).

## 10. Skipped sections (with justification)

> Use this to record sections that **do not apply** to this feature.
> Empty sections are confusing; explicit skips are honest.

- `<section>` — _(reason: <why N/A>)_

## 11. Open questions

> Anything that surfaced during design that the PRD/Plan did not foresee.
> If a question changes a Plan ADR, STOP and re-run `/sdd-plan`.

| Question | Impact (PRD/Plan/Design) | Decider | Due |
|---------|--------------------------|---------|-----|
| `<question>` | `<which artifact>` | `<role>` | `<date>` |

## Definition of Done (Design)

- [ ] Every REQ-NNN from the PRD maps to ≥1 section (model/REST/Kafka/...).
- [ ] Every section either has content or appears in §10 with justification.
- [ ] All constitutional rules touched are cited by stable RULE-ID.
- [ ] All DTOs are records (RULE-015); all production classes are final-ready.
- [ ] All Kafka payloads have an Avro schema referenced (RULE-007).
- [ ] Every event-emitting aggregate has an outbox entry referenced (RULE-008).
- [ ] Every `SagaStep<T>` (if any) has process + rollback semantics defined (RULE-009).
- [ ] Module dependency graph has no cycles and matches RULE-004.
- [ ] Configuration uses canonical prefixes (RULE-014).
- [ ] Test design maps every REQ-NNN to a concrete test home.
- [ ] Open questions explicitly listed (or "none").
- [ ] [`data-model.md`](data-model.md) cross-references resolved (every §
      that delegates field detail points at the right `data-model.md` §).
