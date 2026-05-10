---
description: SDD Design phase. Read an approved Plan + ADRs and produce design.md + data-model.md under docs/specs/<NNN-slug>/ with concrete class signatures, REST contracts, Avro schemas, JPA model, configs, and module dependency graph. Sits between /sdd-plan (architecture) and /sdd-tasks (atomic backlog).
argument-hint: <NNN-feature-slug>
allowed-tools: bash, read, write, edit, glob, grep
---

# /sdd-design

You are running the **Design** phase of Spec-Driven Development for a
service that consumes the `lg5-spring-agent-os` bundle.

This phase exists to **separate architectural decisions from detailed
design**. The Plan decides the strategic forks (saga? sync vs async?
modules? ADRs?). The Design pins down everything below that line:
class signatures, REST endpoints, Avro schemas, JPA tables, configs,
module dependencies. By the time `/sdd-tasks` runs, every design
decision must already live in `design.md`.

> Read first: the bundle's `specs/README.md` (workflow shape),
> `specs/templates/design-template.md` (canonical design shape),
> `specs/templates/data-model-template.md` (data shapes),
> and `rules/CONSTITUTION.md` (rules cited by stable RULE-ID).
>
> Read the relevant skill(s) under `.agent-os/skills/` for canonical
> patterns to copy: `lg5-saga`, `lg5-outbox`, `lg5-kafka-avro`,
> `lg5-atdd`, `lg5-api-docs`. NEVER invent framework classes.

## Inputs

- `<NNN-feature-slug>` — folder under `docs/specs/`.

If missing, ask the user.

## Pre-flight

1. Verify `docs/specs/<NNN-slug>/{prd,plan}.md` exist and their DoD
   checklists are fully ticked. If not, STOP and ask the human to close
   the upstream phase.
2. Read every ADR under `docs/specs/<NNN-slug>/adr/`. ADR decisions
   are **inputs you cannot override** — if an ADR says "use saga", you
   design a saga.
3. Read all skill files relevant to the ADRs (e.g. ADR says "Outbox"
   → read `skills/lg5-outbox/SKILL.md`).

## Steps

1. **Copy the templates**:
   ```
   cp .agent-os/specs/templates/design-template.md \
      docs/specs/<NNN-slug>/design.md
   cp .agent-os/specs/templates/data-model-template.md \
      docs/specs/<NNN-slug>/data-model.md
   ```
   (Skip `data-model.md` if the feature has no persistent state, no
   events, no DTOs, no schemas. Record the skip in `design.md` §10.)

2. **Fill in `design.md`**. Rules:
   - Every §1-§9 must either have content or be moved to §10 with a
     one-line skip justification. Empty sections are FORBIDDEN.
   - Every REQ-NNN from the PRD maps to ≥1 section. Verify in §1.
   - All Java/Kotlin signatures shown respect RULE-015 (records for
     DTOs, `final` ready).
   - All REST endpoints produce `application/vnd.api.v1+json` (RULE-006).
   - All Kafka payloads reference an Avro schema (RULE-007).
   - Every event-emitting aggregate has an outbox entry (RULE-008).
   - Every `SagaStep<T>` has process + rollback semantics (RULE-009).
   - Listener semantics call out NO-OP exception handling (RULE-010).
   - Configuration uses canonical prefixes (RULE-014).
   - Module dependency graph (§8) is acyclic and respects RULE-004.

3. **Fill in `data-model.md`** (if produced):
   - Aggregates with field-level detail + invariants.
   - Domain events with semantics.
   - Avro schema sketches (namespace, fields, defaults, evolution).
   - JPA tables (DDL-level: columns, types, FKs, indices).
   - Outbox payload shape per aggregate (RULE-008).
   - REST DTO records (RULE-006 + RULE-015).

4. **Run the Design Definition-of-Done checklist** at the end of
   `design.md`. Tick what you can validate; flag the rest.

5. **Diff report**: print to the user
   - Path of generated `design.md` (+ `data-model.md` or skip reason).
   - REQ ↔ design-section coverage matrix.
   - Constitutional rules touched (by stable RULE-ID).
   - Open questions surfaced during design.
   - Unchecked DoD items (with reasons).
   - Suggested next command: `/sdd-tasks <NNN-slug>` once the user
     approves.

6. **Commit**:
   ```
   git add docs/specs/<NNN-slug>/design.md docs/specs/<NNN-slug>/data-model.md
   git commit -m "design(<NNN-slug>): detailed technical design"
   ```

## Anti-patterns to avoid

- DO NOT modify the PRD, Plan, or ADRs. If you find them incomplete,
  STOP and report; the human re-runs the upstream phase.
- DO NOT write production code. `design.md` is markdown.
- DO NOT invent framework classes or annotations (RULE-005, RULE-018).
  If a pattern is not in `lg5-spring`, `food-ordering-system`,
  `blank-service`, or a skill, say so explicitly.
- DO NOT leave a design section empty. Either fill it or skip it in §10.
- DO NOT proceed to `/sdd-tasks` automatically — Design ends at the
  human-approval gate.
- DO NOT produce a 500-line design for a 3-REQ feature. Over-design is
  the Verschlimmbesserung trap.

## References

- Templates: `specs/templates/{design,data-model}-template.md`.
- Sibling subagent: `subagents/sdd-designer.md`.
- Constitution: `rules/CONSTITUTION.md` + every `rules/RULE-*.md`.
- Skills: `skills/lg5-{saga,outbox,kafka-avro,atdd,api-docs}/SKILL.md`.
- Why this phase exists: separating strategic architecture (Plan) from
  tactical design (Design) prevents `sdd-tasker` from improvising
  decisions hidden inside TASK descriptions.
