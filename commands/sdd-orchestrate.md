---
description: SDD orchestration helper. Inspect the state of docs/specs/<NNN-slug>/ and recommend the next SDD phase command. Use when the user says "what's next on feature X" or wants a multi-spec dashboard. Never produces feature artifacts itself — only inspects and dispatches.
argument-hint: [<NNN-feature-slug>]
allowed-tools: read, glob, grep, bash
---

# /sdd-orchestrate

You are running the **Orchestration** helper of Spec-Driven Development
for a service that consumes the `lg5-spring-agent-os` bundle.

This command does NOT produce intent, PRD, plan, design, tasks, code,
or verify artifacts. It only inspects what exists under
`docs/specs/<NNN-slug>/` and tells the user which phase comes next.

> Read first: the bundle's `AGENTS.md` (canonical phase order) and the
> headers + DoD checklists of every artifact in the target spec folder.

## Inputs

- `[<NNN-feature-slug>]` — optional. If absent, produce a multi-spec
  dashboard listing every feature under `docs/specs/` with its current
  phase.

## Pre-flight

1. Confirm `docs/specs/` exists. If empty: recommend
   `/sdd-intent <slug> "<idea>"` or `/sdd-specify <slug> "<desc>"`.
2. If a slug was given, confirm `docs/specs/<NNN-slug>/` exists. If
   not, report and recommend creating it via `/sdd-intent` or
   `/sdd-specify`.

## Steps

1. **Inspect artifacts**. For the target spec, record presence + DoD
   status of:
   - `intent.md` (DoD ticks)
   - `prd.md` (DoD ticks, `[NEEDS CLARIFICATION]` count)
   - `plan.md` (DoD ticks) + ADR count under `adr/`
   - `design.md` (DoD ticks)
   - `data-model.md` (present / absent / skipped-with-justification)
   - `tasks.md` (count by Status: todo, in_progress, done, total)
   - `verify-report.md` (gate verdict, if present)

2. **Apply the decision tree** (stop at first match):

   | State                                                              | Next phase           | Recommended command |
   |--------------------------------------------------------------------|----------------------|---------------------|
   | No spec folder                                                     | Intent or Specify    | `/sdd-intent <slug> "<idea>"` (or `/sdd-specify`) |
   | `intent.md` exists, no `prd.md`                                    | Specify              | `/sdd-specify <NNN-slug>` |
   | `prd.md` exists, DoD not all ticked or clarifications remain       | Human action         | resolve clarifications, re-run last phase |
   | `prd.md` complete, no `plan.md`                                    | Plan                 | `/sdd-plan <NNN-slug>` |
   | `plan.md` complete, no `design.md`                                 | Design               | `/sdd-design <NNN-slug>` |
   | `design.md` complete, no `tasks.md`                                | Tasks                | `/sdd-tasks <NNN-slug>` |
   | `tasks.md` has open TASKs                                          | Implement            | `/sdd-implement <next-priority-TASK>` |
   | All TASKs `done`, no `verify-report.md`                            | Verify               | `/sdd-verify <NNN-slug>` |
   | `verify-report.md` gate = ❌                                        | Re-open phase X      | re-run `/sdd-<phase>` named in report §8 |
   | `verify-report.md` gate = 🟡 (override)                             | Closed with debt     | review `tech-debt` ADR time-boxes |
   | `verify-report.md` gate = ✅                                         | Closed               | none — feature is done |

3. **Compute "next-priority TASK"** when in Implement phase: the lowest
   TASK-NNN with `Status: todo` whose dependencies are all `done`.

4. **Report to the user**:
   ```
   ## Orchestration: <NNN-slug>

   ### Current state
   - intent.md       : <present|absent> (DoD x/y)
   - prd.md          : <present|absent> (DoD x/y, clarif: n)
   - plan.md + ADRs  : <present|absent> (n ADRs)
   - design.md       : <present|absent>
   - data-model.md   : <present|absent|skipped>
   - tasks.md        : <present|absent> (todo: a, in_progress: b, done: c, total: n)
   - verify-report.md: <present|absent> (gate: <verdict>)

   ### Next phase: <name>
   ### Recommended command: <exact command>
   ### Blockers (if any): <list>
   ```

   If no slug was given:
   ```
   ## SDD dashboard

   | Spec | Phase | Blockers |
   |------|-------|----------|
   | 001-loyalty-ledger | implement (3 todo) | none |
   | 002-payment-refunds | design | PRD §8 unresolved |
   ```

## Anti-patterns to avoid

- DO NOT create files. This command is read-only.
- DO NOT skip phases. The order
  `intent → specify → plan → design → tasks → implement → verify` is
  fixed (Intent is the only optional phase).
- DO NOT auto-invoke another command. Recommend, never execute.
- DO NOT recommend two phases at once. Always one next-step command.

## References

- Subagent: `subagents/sdd-orchestrator.md`.
- Sibling commands: `commands/sdd-{intent,specify,plan,design,tasks,implement,verify}.md`.
- Workflow diagram: `AGENTS.md` §"Spec-Driven Development workflow".
