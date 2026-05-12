---
description: SDD Quick-path command. For trivial changes (1 endpoint, 1 entity, 1 listener, 1 field, or 1 config) that don't justify the full 7-phase workflow. Produces a compressed quick-spec.md (~40 lines) under docs/specs/<NNN-slug>/. Enforces strict eligibility — rejects sagas, new outboxes, new aggregates, new Avro schemas, multi-module changes. Goes directly to /sdd-implement after approval. /sdd-verify remains mandatory.
argument-hint: <change-slug> "<informal description>"
allowed-tools: bash, read, write, edit, glob, grep
---

# /sdd-quick

You are running the **Quick-path** of Spec-Driven Development for a
service that consumes the `lg5-spring-agent-os` bundle.

> Read first: the bundle's `specs/README.md` (workflow shape) and
> `specs/templates/quick-spec-template.md` (canonical quick-spec shape).
> Read also: `rules/CONSTITUTION.md` so you know which rules constrain
> the change — name them in §3.

## When to use this command

Use `/sdd-quick` when ALL of the following are true:

- The change is a single bounded scope: 1 REST endpoint, OR 1 JPA entity,
  OR 1 Kafka listener, OR 1 field addition, OR 1 config change.
- It touches at most 2 modules.
- It does NOT involve a saga, a new outbox, a new aggregate, or a new
  Avro schema.
- It does NOT require a new external dependency or a new module.

If you are not sure, run `/sdd-specify` instead. The cost of false
positives (using quick path for a saga) is much higher than the cost
of false negatives (going full SDD for something simple).

## Inputs

- `<change-slug>` — kebab-case (e.g. `add-customer-email-field`,
  `expose-order-status-endpoint`).
- `"<informal description>"` — 1-5 sentences in natural language.

If either is missing, ask the user before doing anything.

## Pre-flight (eligibility gate)

Before creating ANY file, run the 10-criterion eligibility check from
the `sdd-quicker` subagent. The criteria reject anything involving:

1. Saga (new or modified).
2. New outbox.
3. New aggregate root.
4. New Avro schema (extending existing is OK).
5. Multi-module change (> 2 modules).
6. New Maven module.
7. New external dependency.
8. Cross-service change.
9. Breaking API change.
10. Performance- or security-critical change.

If ANY criterion fails, STOP. Reply to the user:

```markdown
## /sdd-quick rejected

This change is NOT eligible for the quick path because:
- <reason 1>
- <reason 2>

Recommended next step: `/sdd-specify <slug> "<description>"`.
```

Do NOT create files. Do NOT create a branch. The human must explicitly
re-invoke with `/sdd-specify`.

## Steps (when eligible)

1. **Spec folder setup**:
   - Locate the bundle (`.agent-os/`).
   - Determine next `NNN` by scanning `docs/specs/`. Use `001` if empty.
   - Create `docs/specs/<NNN>-<change-slug>/`.
   - Create branch: `git switch -c feature/<NNN>-<change-slug>`.

2. **Copy the template**:
   ```
   cp .agent-os/specs/templates/quick-spec-template.md \
      docs/specs/<NNN>-<change-slug>/quick-spec.md
   ```

3. **Fill in the quick-spec** following the `sdd-quicker` subagent's
   operating procedure (sections §1-§6 + DoD checklist).

4. **Validate hard cap**: 40 content lines max (excluding frontmatter
   and the preamble blockquote). If exceeded, STOP and recommend
   `/sdd-specify`.

5. **Run the Quick Spec DoD checklist** at the end of the template.
   ALL boxes must be tickable.

6. **Diff report** to the user:
   - Path of the generated quick-spec.
   - Type of change, modules affected, file count estimate.
   - RULE-NNNs in play.
   - ACs (verbatim).
   - Suggested next command: `/sdd-implement` against this quick-spec,
     then `/sdd-verify <NNN>-<change-slug>` (MANDATORY).

7. **Commit**:
   ```
   git add docs/specs/<NNN>-<change-slug>/quick-spec.md
   git commit -m "quick(<NNN>-<change-slug>): initial quick-spec draft"
   ```

## Anti-patterns to avoid

- DO NOT create `prd.md`, `plan.md`, `design.md`, or `tasks.md` in a
  quick-spec folder. The point is compression — those phases are skipped.
- DO NOT exceed 40 content lines in the quick-spec. If the change needs
  more, it is not a quick change — abort and recommend `/sdd-specify`.
- DO NOT skip the eligibility gate. Liberal use of the quick path erodes
  SDD discipline; strict gating preserves it.
- DO NOT mark `/sdd-verify` as optional. Verify is mandatory for BOTH
  paths — that is what keeps the spec canonical (Fowler's SDD essence).
- DO NOT fabricate ACs the user did not imply (Verschlimmbesserung trap).
- DO NOT proceed automatically to `/sdd-implement` — Quick ends at the
  human-approval gate, same as Specify in the full path.

## References

- Subagent: `subagents/sdd-quicker.md`.
- Template: `specs/templates/quick-spec-template.md`.
- Workflow: `specs/README.md`.
- Sibling SDD commands: `commands/sdd-{intent,specify,plan,design,tasks,implement,verify,orchestrate}.md`.
- Why a quick path: friction-to-value ratio. SDD's essence is "the spec
  is canonical and code is derived from it"; the number of phases is an
  implementation choice. A sanctioned quick path with mandatory verify
  beats an unsanctioned bypass with no verify.
