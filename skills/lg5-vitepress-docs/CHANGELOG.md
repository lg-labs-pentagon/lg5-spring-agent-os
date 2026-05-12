# Changelog — lg5-vitepress-docs

All notable changes to this skill are documented in this file.
The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this skill adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

The compatibility marker `lg5-spring-sha:` in the frontmatter pins the framework
commit against which the skill was last validated.

## [Unreleased]

## [0.1.0] — 2026-05-12
### Added
- Initial skill capturing the VitePress aggregator surface that stitches the
  per-contract viewers (from `lg5-api-docs`), Allure acceptance reports (from
  `lg5-allure-report`), architecture visualizations, ADRs, and runbooks into a
  single navigable surface.
- Dual-deploy pattern: GitHub Pages (canonical-of-record) + Firebase Hosting
  (with per-PR preview channels, 7-day TTL).
- 6 critical wiring rules, distilled from the canonical implementation in
  `lg5-loyalty-ledger` (SDD spec set `004-project-docs`):
  - **Rule 1** — `docs/site/public/` for any non-Markdown content VitePress
    must serve verbatim. Sibling `.html` files of `.md` sources are silently
    dropped during build.
  - **Rule 2** — relative-only Markdown links (`./swagger-ui.html`) inside
    section indexes so base-aware rewriting works for both `DOCS_BASE` values.
  - **Rule 3** — dual base-path build: two `docs-build-*` jobs, same source,
    different `DOCS_BASE` env. Never try to single-build both targets.
  - **Rule 4** — source-state footer env injection: CI must export
    `COMMIT_SHA`, `BUILD_TIME`, `PR_NUMBER` to every build step; the Vue
    component slices SHA to 7 chars for display.
  - **Rule 5** — pnpm 11 build-script gating via
    `docs/site/pnpm-workspace.yaml` (`allowBuilds:` replaces
    `npm_config_strict_dep_builds`).
  - **Rule 6** — `check-artifacts.mjs` + `linkinator-to-annotations.mjs`:
    warn-don't-fail surfacing of missing upstream artifacts and broken links.
- CI pipeline shape: 6 jobs on top of the canonical 11-job CI from
  `lg5-github-actions` (`docs-build-pages`, `docs-build-firebase`,
  `pages-deploy`, `firebase-deploy-docs`, `firebase-deploy-allure`,
  `firebase-preview`).
- Firebase project setup checklist (one-time, per service): 2 hosting targets
  in `.firebaserc`, service account JSON in GitHub secret, `docs/preview`
  label.
- REQ traceability table covering 9 recurring documentation-related
  requirements.
- "Common pitfalls" catalogue, including the 4 post-merge bugs surfaced
  during feat 004 verification (footer rendering `dev`, footer rendering
  full 40-char SHA, viewers placed in wrong directory, absolute links
  breaking under non-root base).

### Compatibility
- `lg5-spring-sha: d0d754a` — framework commit against which the canonical
  implementation in `lg5-loyalty-ledger` was validated.
- Complements: `lg5-api-docs` (>=0.1.0), `lg5-allure-report` (>=0.1.0),
  `lg5-github-actions` (>=0.1.1).
