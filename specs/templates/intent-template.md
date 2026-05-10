---
kind: template
name: intent-template
version: 0.1.0
description: Pre-PRD intent one-pager. Captures the WHY and the problem framing before /sdd-specify produces a functional PRD. Used by /sdd-intent. Optional but recommended.
---

# Intent — `<feature-name>`

> **Use this template via `/sdd-intent`.** Replace every `<placeholder>`.
> The Intent is a **one-pager** that frames the problem *before* writing
> a PRD. It captures the **why**, the **who**, and the **desired
> outcome** — never the **what** (that's the PRD's job) or the **how**
> (that's the Plan's job).
>
> Keep it tight: if you exceed one screen, you are over-specifying.
> Mark unresolved questions with `[NEEDS CLARIFICATION: <question>]`.

## 1. Problem statement

One sentence. What pain exists today, expressed from the user's
viewpoint? Avoid solution words ("we need to add X"); use observation
words ("users cannot Y", "we lose Z when W happens").

## 2. Who feels it

- **<user role 1>** — how the pain shows up for them.
- **<user role 2>** — how the pain shows up for them.
- **<internal role>** — operational pain, if any.

## 3. Why now

2-3 sentences. What is the trigger for solving this *now* rather than
later? Compliance deadline, churn signal, dependency unlock, strategic
bet? If "no urgency" is the honest answer, write that — it is a
legitimate reason to defer.

## 4. Desired outcome

Describe the world *after* this feature ships in **observable** terms,
without naming the solution. Good: "customers recover their money
without contacting a human within 24h". Bad: "we add a refund endpoint".

## 5. Success metrics

> Pick 1-3 metrics. If you cannot name a measurable signal, the intent
> is not ready — go back to step 1.

| Metric | Baseline | Target | Window |
|--------|---------:|-------:|--------|
| `<metric 1>` | `<n>` | `<n>` | `<window>` |
| `<metric 2>` | `<n>` | `<n>` | `<window>` |

## 6. Non-goals

Explicit list of what this intent does **not** cover. This is the most
valuable section: it prevents scope creep in the PRD phase.

- `<thing>` — _(reason: <why excluded>)_
- `<thing>` — _(reason: <why excluded>)_

## 7. Constraints and hints

Known boundaries from the business, legal, or operational context. Not
prescriptions — just facts the PRD writer must respect.

- `<constraint>` — _(source: <stakeholder/regulation/system>)_
- `<hint>` — _(rationale: <why this matters>)_

## 8. Open questions

> Mark with `[NEEDS CLARIFICATION: <question>]` inline in the sections
> above when you can. Use this table for questions whose answer changes
> the **shape** of the PRD.

| Question | Decider | Due |
|---------|---------|-----|
| `<question>` | `<role>` | `<date>` |

## Definition of Done (Intent)

- [ ] Problem statement is one sentence, observation-flavored (not solution-flavored).
- [ ] At least one user role identified with their specific pain.
- [ ] "Why now" honestly answered (urgency or its absence).
- [ ] Desired outcome described in observable terms, no solution naming.
- [ ] At least one measurable success metric with baseline + target.
- [ ] Non-goals list is explicit, not empty.
- [ ] Open questions tabled (or "none" with a one-line justification).
- [ ] Intent fits on one screen (~1 page).
