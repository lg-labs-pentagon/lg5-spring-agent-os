# Changelog — lg5-spring-agent-os subagents bundle

All notable changes to the **subagents** artifact set are documented here.
Uses [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and
[SemVer 2.0.0](https://semver.org/spec/v2.0.0.html).

## [0.2.0] — 2026-05-09
### Changed
- `manifest.yaml` `bundle.version` bumped to `0.3.0` to align with the
  rest of the bundle (cross-bundle invariant).
### Notes
- **No subagent content changed in this release.** All 3 subagents remain
  at individual version `0.1.0`.
- See `rules/CHANGELOG.md`, `specs/CHANGELOG.md`, and
  `commands/CHANGELOG.md` for the substantive 0.3.0 changes (constitution
  layer, SDD templates, SDD orchestrator commands).

## [0.1.0] — 2026-05-09
### Added
- `lg5-code-reviewer` — reviews diffs against the 18 hard rules and cites
  violations by stable RULE-ID.
- `lg5-test-generator` — generates IT/ATDD test scaffolds following
  RULE-012 (test profiles + base classes) and RULE-013 (Testcontainers gating).
- `lg5-planner` — decomposes a feature request into a step-by-step
  implementation plan grounded in the bundle's rules and skills.
### Notes
- Validated against `lg5-spring` SHA `cbb6783`.
- Subagents are written for OpenCode's agent format (YAML frontmatter with
  `description`, `tools`, `model`); they should be portable to Claude Code's
  subagent format with minor adaptation.
