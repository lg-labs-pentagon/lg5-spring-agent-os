---
kind: example
name: microservice-spec-example
version: 0.1.0
description: End-to-end spec example for a hypothetical `loyalty-ledger` service combining PRD + ADRs + module breakdown using the lg5-spring conventions.
---

# Example spec — `loyalty-ledger` service

This is an **illustrative example** of how a complete spec for a new
lg5-spring microservice looks when combining the PRD template, two ADRs,
and a module/implementation plan. The `loyalty-ledger` service is fictional
— it is included only to show the shape; do not implement it as-is.

---

## A — PRD

> Filled out from `specs/prd-template.md`.

### 1. Summary

The `loyalty-ledger` service stores customer loyalty point balances and
emits append-only ledger entries on every credit/debit. It exposes a small
REST API for read-only balance queries and consumes `OrderPaidEvent` from
the existing `order-service` to credit points automatically.

### 2. Problem

Today, loyalty points are calculated on-the-fly in the order-service when
an order is paid, and there is no source of truth for "current balance"
or "ledger history". Customer Support cannot answer "why did my balance
drop?" without a manual SQL trip through the orders DB.

### 3. Users

- **Customer (read-only)** — wants to check balance from the mobile app.
- **Customer Support agent** — wants to view a per-customer ledger.
- **order-service (system)** — needs a fire-and-forget way to credit points.

### 4. Success metrics

| Metric                              | Baseline | Target  | Window |
|-------------------------------------|---------:|--------:|--------|
| Balance read p95 latency            | N/A      | <50ms   | 30d    |
| % of OrderPaid events credited      | N/A      | >99.5%  | 30d    |
| Support tickets "wrong balance"     | 12/wk    | <2/wk   | 60d    |

### 5. Scope (in)

- [ ] `GET /loyalty/balances/{customerId}` (vendor media type — RULE-006).
- [ ] `GET /loyalty/ledger/{customerId}?from=&to=` (paginated).
- [ ] Kafka consumer for `order-paid` topic.
- [ ] Outbox-driven `points-credited` event emission.
- [ ] ATDD scenarios for credit, double-credit (idempotent), and
  not-found customer cases.

### 6. Scope (out)

- Point **debit** flow (purchases with points) — _(reason: needs a saga
  with order-service; v2)_.
- UI for Customer Support — _(reason: backend only this iteration)_.
- Multi-currency / multi-tier loyalty programs — _(reason: single
  flat-rate rule for v1)_.

### 7. Architecture / dependencies

- New microservice with the canonical 8-module shape (RULE-004).
- Consumer of `order-paid` Kafka topic (RULE-007 — Avro schema lives in
  `order-service-message-model`; we re-use the generated class via the
  `order-service-message-model` Maven dependency).
- Producer of `points-credited` Kafka topic (RULE-007 — new schema in
  `loyalty-ledger-message-model`).
- Outbox-only emission for `points-credited` (no saga; RULE-008).
- New Postgres schema `"loyalty"` with `balance` and `ledger_entry` tables.

| Dependency           | Type         | Owner   | Status |
|----------------------|--------------|---------|--------|
| `order-paid` topic   | upstream     | orders  | ready  |
| `order-service-message-model` | maven dep | orders | ready  |
| Confluent SR         | infra        | platform | ready |

### 8. Acceptance criteria

- [ ] `make install-skip-test` succeeds.
- [ ] ATDD: "Crediting points on OrderPaid" scenario green.
- [ ] ATDD: "Double-delivered OrderPaid is idempotent" scenario green
  (exercises RULE-009 idempotency + RULE-010 NO-OP path).
- [ ] ATDD: "Balance not found returns 404" scenario green.
- [ ] No `must` violations reported by `lg5-code-reviewer` subagent.
- [ ] `points-credited` event is observed on Kafka after a credit.

### 9. Open questions

| Question | Decider | Due |
|---------|---------|-----|
| Points-per-dollar rate (v1 hard-coded? config? table?) | Product | <date> |
| Retention policy for `ledger_entry` table | Compliance | <date> |
| Topic partitioning key (customerId vs orderId)? | Platform | <date> |

### 10. Implementation plan reference

See section **C** below.

---

## B — ADRs

### ADR-001: Outbox-only emission, no saga participation in v1

- **Status:** Accepted
- **Date:** <YYYY-MM-DD>

#### Context

The credit operation triggered by `OrderPaidEvent` has no compensating
write to issue if the downstream `points-credited` event fails to publish:
the ledger entry is the source of truth and a missing publish only delays
the marketing-side notifications, which is acceptable.

#### Decision

We use the Transactional Outbox pattern (RULE-008) to persist
`points-credited` events alongside the ledger entry, but we do **not**
make the credit a SagaStep (no `SagaStep<T>`, no orchestrator, no
rollback path).

#### Alternatives considered

- **Saga with order-service compensation** — pros: end-to-end consistency
  with order state. Cons: order-service does not need to know about
  loyalty; introduces unnecessary cross-service coupling. Why not chosen:
  no business need for compensation in v1.
- **Direct Kafka publish from the @Transactional credit method** — pros:
  fewer moving parts. Cons: violates RULE-008 (atomicity loss). Why not
  chosen: rule-blocked.

#### Consequences

- **Positive:** simpler implementation; ~50% fewer files than a full saga.
- **Negative:** if we later need compensation, we must refactor to
  `SagaStep<T>` and add an orchestrator — that refactor is non-trivial.
- **Neutral:** still uses `OutboxStatus` and the standard scheduler so
  the migration to a saga is a localized change.

#### lg5 rule cross-references

- RULE-008 — confirms (we use the outbox).
- RULE-009 — opts out (no SagaStep). Tech-debt item: revisit if compensation
  becomes a requirement.
- RULE-011 — confirms (standard scheduler).

### ADR-002: Reuse `order-service-message-model` for the consumed Avro schema

- **Status:** Accepted
- **Date:** <YYYY-MM-DD>

#### Context

`order-paid` events are produced by `order-service` from a schema declared
in `order-service-message-model`. We need to deserialize the same shape on
the consumer side.

#### Decision

We add `order-service-message-model` as a Maven dependency in
`loyalty-ledger-message-core` and use the generated
`OrderPaidAvroModel` class directly.

#### Alternatives considered

- **Re-declare the schema in `loyalty-ledger-message-model`** — pros:
  zero coupling to order-service's repo. Cons: schema drift risk; two
  sources of truth for the same wire shape. Why not chosen: violates
  the spirit of RULE-007 (single source of truth for the Avro schema).

#### Consequences

- **Positive:** schema drift impossible; consumer breaks at compile-time
  if the producer changes the schema in a backwards-incompatible way.
- **Negative:** introduces a Maven dependency on `order-service-message-model`,
  which transitively depends on Confluent libraries — should be fine
  since we already need them.

#### lg5 rule cross-references

- RULE-007 — confirms (Avro is the contract).
- RULE-014 — irrelevant (no new config keys).

---

## C — Module breakdown / implementation plan

> Generated by `lg5-planner` subagent.

### Plan

1. **Scaffold service** — module: all 8 — rules: RULE-002, RULE-004 — skill: `lg5-new-service` — command: `/scaffold-service loyalty-ledger com.example.loyalty` — acceptance: `make install-skip-test` green.
2. **Add Avro consumer of OrderPaidEvent** — module: `loyalty-ledger-message-core` — rules: RULE-007, RULE-010 — skill: `lg5-kafka-avro` — command: `/add-kafka-listener loyalty-ledger order-paid OrderPaidAvroModel` — acceptance: IT consumes a sample message.
3. **Define domain model: Balance + LedgerEntry aggregates** — module: `loyalty-ledger-domain-core` — rules: RULE-003, RULE-005, RULE-016 — skill: `lg5-spring-overview` — command: (none) — acceptance: unit tests for credit/debit invariants pass.
4. **Add JPA persistence** — module: `loyalty-ledger-data-access` — rules: RULE-008 (DDL ↔ JPA asymmetry) — skill: `lg5-outbox` — command: (none) — acceptance: Flyway migration green; repo IT passes.
5. **Add outbox for `points-credited`** — module: `loyalty-ledger-application-service` + `loyalty-ledger-data-access` — rules: RULE-008, RULE-011, RULE-014 — skill: `lg5-outbox` — command: `/add-outbox loyalty-ledger PointsCredited` — acceptance: outbox row written atomically with credit; scheduler publishes.
6. **Wire the credit use case in the listener** — module: `loyalty-ledger-application-service` — rules: RULE-008 (helper pattern), RULE-009 (idempotency guard) — skill: `lg5-saga` (idempotency section even though no saga) — command: (none) — acceptance: IT for double-delivery is idempotent.
7. **Add REST balance + ledger endpoints** — module: `loyalty-ledger-api` — rules: RULE-005, RULE-006 — skill: `lg5-spring-overview` — command: (none) — acceptance: REST IT green for both endpoints with vendor media type.
8. **ATDD scenarios** — module: `loyalty-ledger-acceptance-test` — rules: RULE-012, RULE-013 — skill: `lg5-atdd` — command: (no slash command; `lg5-test-generator` subagent) — acceptance: 3 scenarios green (credit, double-credit, not-found).
9. **Code review pass** — module: all — rules: all — skill: (none) — command: (no slash; `lg5-code-reviewer` subagent) — acceptance: 0 `must` violations.

### Dependencies

- Step 2 depends on Step 1.
- Steps 3 and 7 depend on Step 1; can run in parallel.
- Step 4 depends on Step 3.
- Step 5 depends on Steps 3 and 4.
- Step 6 depends on Steps 2, 3, 5.
- Step 8 depends on Steps 6 and 7.
- Step 9 depends on Step 8.

### Cross-cutting concerns

- Topic creation: confirm `points-credited` is auto-created or pre-provisioned
  by Platform team before deploying.
- Schema registry registration: `PointsCreditedAvroModel` must be registered
  with `BACKWARD` compatibility from day 1.
- Operational dashboards: define `outbox_status='STARTED'` row count alert
  (lag indicator).

### Risks / open questions

- **Risk:** order-service's Avro schema evolves before we go live — mitigation:
  pin to a specific commit of `order-service-message-model` in the Maven
  dependency, upgrade explicitly.
- **Open:** Should the ledger include a free-text reason field? — Decider: Product.

### Estimated artifact count

- New files: ~38
- Modified files: ~6 (mostly application.yaml + parent pom)
- New tests: ~12 (unit + IT + ATDD)
