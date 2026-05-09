# Changelog — lg5-spring-agent-os rules bundle

All notable changes to the **rules** artifact set are documented here.
This file uses [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and
[SemVer 2.0.0](https://semver.org/spec/v2.0.0.html).

The version below tracks the rules bundle as a whole, independently of
individual rule versions in their own frontmatter.

## [0.2.0] — 2026-05-09
### Added
- **Constitution layer** (concept borrowed from spec-kit). 15 of the 18 rules
  (those with `severity: must`) are now flagged as **constitutional** — i.e.
  immutable architectural laws that any consumer service must respect or
  explicitly justify in an ADR.
- New `constitutional: bool` field in every rule's frontmatter.
- New `rules/CONSTITUTION.md` document: index of the 15 constitutional rules
  with their one-liner, plus rules of engagement (how PRDs/Plans/Tasks should
  reference the constitution).
- New `constitution: CONSTITUTION.md` field in `manifest.yaml`.
- Per-rule `constitutional: <bool>` echoed in `manifest.yaml` for fast lookup.
### Notes
- No rule wording changed. This is a metadata + documentation enhancement.
- Bundle bumped to `0.3.0` because (a) the SDD-aligned commands and templates
  introduced in the same release require this metadata, and (b) the
  cross-bundle invariant requires `bundle.version` to match across types.

## [0.1.0] — 2026-05-09
### Added
- Initial extraction of the 18 always-active hard rules from the workspace
  `AGENTS.md` into individual `RULE-NNN-<slug>.md` files. Each rule carries
  YAML frontmatter (`id`, `version`, `lg5-spring-sha`, `severity`, `scope`,
  `tags`, `description`) so agents and CI can address them by stable ID.
- `manifest.yaml` listing all 18 rules with id ↔ slug ↔ severity ↔ scope.
- `AGENTS.md` was rewritten to be a thin index that delegates the full rule
  texts to this directory.
### Notes
- Validated against `lg5-spring` SHA `cbb6783`.
- Severity vocabulary: `must` (hard), `should` (default), `info` (reference).
- Scope vocabulary: `framework`, `architecture`, `kafka`, `outbox`, `saga`,
  `testing`, `style`, `build`, `reference`.
