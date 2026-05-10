---
description: SDD Verify phase. Cross-check every PRD acceptance criterion against test evidence after all TASKs are done. Produces verify-report.md with AC↔evidence matrix, coverage summary, constitutional check, and a gate decision (VERIFIED / VERIFIED WITH OVERRIDE / NOT VERIFIED). A red gate blocks spec closure unless overridden by a tech-debt ADR.
argument-hint: <NNN-feature-slug>
allowed-tools: bash, read, write, edit, glob, grep
---

# /sdd-verify

You are running the **Verify** phase of Spec-Driven Development for a
service that consumes the `lg5-spring-agent-os` bundle. This is the
**closing gate**: a spec is not "done" until its verify-report is
green (or yellow with an explicit override ADR).

> Read first: the bundle's `specs/README.md` (workflow shape),
> `specs/templates/verify-report-template.md` (canonical report shape),
> and `rules/CONSTITUTION.md` (rules verified in §5).

## Inputs

- `<NNN-feature-slug>` — folder under `docs/specs/`.

If missing, ask the user.

## Pre-flight

1. Verify `docs/specs/<NNN-slug>/{prd,plan,design,tasks}.md` all exist.
2. Verify EVERY TASK in `tasks.md` is `Status: done`. If any are still
   `todo` or `in_progress`, STOP — Verify is for completed specs only.
3. Ensure the working tree is clean (or that uncommitted changes belong
   to the verify report itself).

## Steps

1. **Build the AC inventory** from `prd.md` §5. One row per REQ-NNN per
   acceptance scenario (a REQ with 3 Given/When/Then scenarios becomes
   3 rows).

2. **Build the TASK ↔ REQ map** from `tasks.md`. For each REQ-NNN, list
   the TASKs that implemented it and the TASKs that added its tests.

3. **Run the builds** (RULE-017):
   ```
   make all-build
   make run-acceptance-test
   ```
   Capture exit codes. Note artifact locations:
   - Surefire XML: `**/target/surefire-reports/*.xml`
   - Failsafe XML: `**/target/failsafe-reports/*.xml`
   - Cucumber JSON: `<svc>-acceptance-test/target/cucumber-report.json`
   - Allure results: `<svc>-acceptance-test/target/allure-results/`

4. **Cross-check each AC against evidence**. For every row in the AC
   inventory, set status:
   - ✅ **pass** — test exists, ran, passed.
   - ⚠ **flaky** — test exists but was unstable in this run.
   - ❌ **fail** — test exists but failed.
   - ⚪ **uncovered** — no test references this AC.
   - 🟡 **manual** — covered by a runbook procedure (list in §4).

5. **Constitutional check (§5)**. For every `severity: must` rule the
   spec's PRD/Plan/Design touched, spot-check the implementation
   (controllers `produces=`, Avro schemas, outbox fields, listener
   exception handling, scheduler gating, test profiles, config
   prefixes). Verdict ✅ / ⚠ / ❌ / n/a per rule.

6. **Write the report** by copying the template and filling every
   section:
   ```
   cp .agent-os/specs/templates/verify-report-template.md \
      docs/specs/<NNN-slug>/verify-report.md
   ```
   Every non-✅ entry in §1, §3, or §5 must appear in §6 with a
   remediation decision (open follow-up TASK, accept manual review, or
   open a `tech-debt` ADR).

7. **Decide the gate (§7)**:
   - ✅ **VERIFIED** if all AC ✅ (or ⚠ accepted) AND all RULE ✅.
   - 🟡 **VERIFIED WITH OVERRIDE** if any non-✅ but covered by a
     `tech-debt` ADR under `docs/specs/<NNN-slug>/adr/` with explicit
     time-box.
   - ❌ **NOT VERIFIED** otherwise. **Spec cannot be closed.**

8. **Diff report**: print to the user
   - Path of generated verify-report.
   - Build status (`make all-build`, `make run-acceptance-test`).
   - Coverage summary (counts of ✅⚠❌⚪🟡).
   - Constitutional verdict counts.
   - Gate decision.
   - Recommended follow-ups per gap.

9. **Commit**:
   ```
   git add docs/specs/<NNN-slug>/verify-report.md
   git commit -m "verify(<NNN-slug>): gate=<VERIFIED|OVERRIDE|NOT VERIFIED>"
   ```

## Anti-patterns to avoid

- DO NOT modify production code while verifying. If you find bugs,
  surface them — do NOT fix them.
- DO NOT pass the gate without evidence. "It probably works" is ⚪.
- DO NOT silently downgrade ❌ to 🟡 without a pre-existing tech-debt
  ADR file. The ADR must exist on disk before the override is valid.
- DO NOT amend a previously merged verify-report. Generate a new
  report with the new run timestamp.
- DO NOT proceed past Verify. There is no phase 8.

## References

- Template: `specs/templates/verify-report-template.md`.
- Sibling subagent: `subagents/sdd-verifier.md`.
- Constitution: `rules/CONSTITUTION.md` + every `rules/RULE-*.md`.
- Cross-cutting: `subagents/lg5-code-reviewer.md` can be invoked for
  RULE-001..RULE-015 spot-checks.
