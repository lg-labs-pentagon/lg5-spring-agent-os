# Changelog — lg5-spring-agent-os rules bundle

All notable changes to the **rules** artifact set are documented here.
This file uses [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and
[SemVer 2.0.0](https://semver.org/spec/v2.0.0.html).

The version below tracks the rules bundle as a whole, independently of
individual rule versions in their own frontmatter.

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
