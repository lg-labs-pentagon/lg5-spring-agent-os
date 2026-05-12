---
kind: template
name: quick-spec-template
version: 0.1.0
description: Compressed single-page spec for trivial changes (1 endpoint, 1 entity, 1 listener, or 1 field). Replaces Specify+Plan+Design+Tasks for changes that don't justify the full 7-phase workflow. Verify remains mandatory. Used by /sdd-quick.
---

# Quick Spec — `<change-name>`

> **Use this template via `/sdd-quick`.** Replace every `<placeholder>`.
> Hard cap: **40 lines of content** (excluding this preamble). If your
> change needs more, you don't have a quick change — use `/sdd-specify`.
>
> **Eligibility (must check ALL):**
> - [ ] Single bounded scope: 1 REST endpoint, OR 1 JPA entity + repo,
>       OR 1 Kafka listener, OR 1 field addition, OR 1 config change.
> - [ ] Touches 1 module (occasionally 2 if domain↔application coupling).
> - [ ] No saga, no new outbox, no new aggregate.
> - [ ] No new Avro schema (extending an existing one with a backward-
>       compatible field is OK).
> - [ ] No new module, no new external dependency.
>
> If ANY box is unchecked, abort and run `/sdd-specify` instead.

## 1. Change

One sentence: what changes and for whom.

## 2. Rationale

One sentence: why this is needed now. If you cannot state a concrete
observable outcome, the change is not ready.

## 3. Scope

| Item | Value |
|------|-------|
| Type | `endpoint` / `entity` / `listener` / `field` / `config` |
| Module(s) | `<svc>-application` / `<svc>-domain` / … |
| New files (expected) | `<count>` |
| Modified files (expected) | `<count>` |
| Constitutional rules in play | `RULE-NNN, RULE-NNN` |

## 4. Acceptance criteria (Given/When/Then)

> 1-3 ACs max. Each AC is testable via an existing test type (IT or ATDD).

- **AC-1**: Given `<state>`, when `<action>`, then `<observable outcome>`.
- **AC-2**: Given `<state>`, when `<action>`, then `<observable outcome>`.

## 5. Non-goals

- `<thing>` — _(reason: <why excluded>)_

## 6. Open questions

| Question | Decider | Due |
|---------|---------|-----|
| `<question>` | `<role>` | `<date>` |

## Definition of Done (Quick Spec)

- [ ] Eligibility checklist above: all 5 boxes ticked.
- [ ] Each AC is verifiable by an automated test that does not exist yet
      (the test is what `/sdd-implement` will add).
- [ ] Constitutional rules in §3 are explicitly named (no surprises).
- [ ] If any AC requires a new endpoint, RULE-006 media type honored.
- [ ] If any AC requires a new entity, RULE-008 outbox is NOT triggered
      (otherwise this is not a quick change — use `/sdd-specify`).
- [ ] No `[NEEDS CLARIFICATION]` left. Quick specs cannot ship with open
      questions; resolve them or upgrade to `/sdd-specify`.

## Next step

`/sdd-implement` directly using this quick-spec.md as the source of
truth. After implement, `/sdd-verify <NNN-slug>` is **mandatory** —
the verify gate is the same as for full SDD specs.
