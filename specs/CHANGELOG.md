# Changelog — lg5-spring-agent-os specs bundle

All notable changes to the **specs** artifact set are documented here.
Uses [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and
[SemVer 2.0.0](https://semver.org/spec/v2.0.0.html).

## [0.1.0] — 2026-05-09
### Added
- `prd-template.md` — Product Requirements Document template with sections
  for problem, users, success metrics, scope, out-of-scope, dependencies,
  and acceptance criteria.
- `adr-template.md` — Lightweight ADR template (context, decision,
  alternatives, consequences) with a "lg5 rule cross-references" section.
- `examples/microservice-spec-example.md` — End-to-end spec example for a
  hypothetical `loyalty-ledger` service combining the PRD + ADRs + module
  breakdown.
### Notes
- Validated against `lg5-spring` SHA `cbb6783`.
- Spec format is plain markdown with YAML frontmatter (`kind`, `version`,
  `description`); designed to be filled in by humans or by the
  `lg5-planner` subagent.
