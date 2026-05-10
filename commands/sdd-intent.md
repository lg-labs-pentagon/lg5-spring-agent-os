---
description: SDD Intent phase (optional). Convert an informal idea into a one-page intent.md under docs/specs/<NNN-slug>/, capturing problem, users, why now, desired outcome, success metrics, non-goals, constraints, and open questions. Pre-PRD framing — never mentions technology or solution words.
argument-hint: <feature-slug> "<one-line idea>"
allowed-tools: bash, read, write, edit, glob
---

# /sdd-intent

You are running the **Intent** phase of Spec-Driven Development for a
service that consumes the `lg5-spring-agent-os` bundle.

Intent is the **optional first phase**: it captures the *why* and the
*problem framing* before a PRD describes the *what*. Use it when:

- The stakeholder's idea is fuzzy ("tengo una idea sobre reembolsos").
- Multiple PRDs might fall out of the same idea.
- You suspect scope creep and want non-goals locked in early.

> Read first: the bundle's `specs/README.md` (workflow shape) and
> `specs/templates/intent-template.md` (canonical intent shape).

## Inputs

- `<feature-slug>` — kebab-case slug (e.g. `payment-refunds`).
- `"<one-line idea>"` — the stakeholder's pitch in their own words.

If either is missing, ask the user before doing anything. An intent
without a stakeholder line is fiction.

## Pre-flight

1. Locate the bundle: `.agent-os/` (submodule) or installed copy.
2. Determine the next feature number `NNN` by scanning
   `docs/specs/` for existing `NNN-*` folders. Use `001` if empty.
3. Create `docs/specs/<NNN>-<feature-slug>/` and an empty `adr/` subdir.
4. Create the feature branch:
   `git switch -c feature/<NNN>-<feature-slug>`.

## Steps

1. **Copy the template**:
   ```
   cp .agent-os/specs/templates/intent-template.md \
      docs/specs/<NNN>-<feature-slug>/intent.md
   ```

2. **Fill in the Intent** by Socratic discovery (ask the human or
   yourself):
   - **Problem statement**: one sentence, observation-flavored. "Users
     cannot Y" not "we need to add X".
   - **Who feels it**: 1-3 user/internal roles with their specific pain.
   - **Why now**: trigger for solving this now. Honest "no urgency" is
     allowed and surfaces deferral as the real recommendation.
   - **Desired outcome**: world-after, observable terms, no solution
     words.
   - **Success metrics**: 1-3 measurable signals with baseline + target
     + window. Refuse to write the intent without at least one metric.
   - **Non-goals**: explicit list — the most valuable section.
   - **Constraints/hints**: business/legal/operational facts the PRD
     writer must respect.
   - **Open questions**: `[NEEDS CLARIFICATION: <question>]` for
     everything ambiguous.

3. **Run the Intent Definition-of-Done checklist** at the end of the
   template. Tick what you can validate; flag the rest.

4. **Diff report**: print to the user
   - Path of the generated intent.
   - Frame summary (problem, primary user, outcome, top metric).
   - Number of `[NEEDS CLARIFICATION]` markers.
   - Number of unchecked DoD items (with reasons).
   - Suggested next command: `/sdd-specify <NNN>-<feature-slug>` once
     the user has resolved the clarifications.

5. **Commit**:
   ```
   git add docs/specs/<NNN>-<feature-slug>/intent.md
   git commit -m "intent(<NNN>-<feature-slug>): frame the problem"
   ```

## Anti-patterns to avoid

- DO NOT mention technology (Spring, Kafka, REST, Postgres, Avro, JPA).
- DO NOT use solution words ("we will add", "implement an X").
- DO NOT exceed ~120 lines. If bigger, split into multiple intents.
- DO NOT skip `[NEEDS CLARIFICATION]` markers. Surfacing unknowns is the
  whole point of Intent.
- DO NOT proceed to `/sdd-specify` automatically — Intent ends at the
  human-approval gate.

## References

- Template: `specs/templates/intent-template.md`.
- Sibling subagent: `subagents/sdd-intender.md`.
- Workflow: `specs/README.md`.
- Why: Fowler & Böckeler, _Understanding Spec-Driven Development_,
  https://martinfowler.com/articles/exploring-gen-ai/sdd-3-tools.html.
