# Contributing to lg5-spring-agent-os

Thanks for helping keep this knowledge base accurate. This file documents the
review process, commit conventions, and release flow.

## Branching

- `main` is protected; all changes go through PRs.
- Branch names: `feat/<scope>-<short-desc>`, `fix/<scope>-<short-desc>`,
  `docs/<scope>-<short-desc>`.

## Commit messages — Conventional Commits

We follow [Conventional Commits 1.0.0](https://www.conventionalcommits.org/en/v1.0.0/):

```
<type>(<scope>): <subject>

[optional body]

[optional footer(s)]
```

### Types

| Type      | When to use                                                               |
|-----------|---------------------------------------------------------------------------|
| `feat`    | A new skill, new section in an existing skill, new framework rule         |
| `fix`     | Correcting a wrong recipe, broken example, outdated rule                  |
| `docs`    | Pure documentation (README, manual CHANGELOG edits)                       |
| `chore`   | Tooling, scripts, gitignore, editorconfig, CI config                      |
| `refactor`| Reorganizing existing skill content with no semantic change               |
| `test`    | Adding/fixing the validate-skills.sh script or future skill tests         |
| `ci`      | CI pipeline changes                                                       |

### Scopes

Use the skill name (or `bundle` / `agents` / `tooling`):

- `overview`, `new-service`, `saga`, `outbox`, `kafka-avro`, `atdd`, `food-ordering-system`
- `bundle` — changes affecting the whole bundle (manifest, global CHANGELOG)
- `agents` — `AGENTS.md` rules
- `tooling` — scripts, CI, gitignore

### Examples

```
feat(saga): add command-handler / helper split pattern
fix(outbox): correct payload column type (jsonb in DDL, String in JPA)
docs(bundle): document skill versioning policy
chore(tooling): add validate-skills.sh CI script
refactor(kafka-avro): split listener and producer sections
feat(saga)!: rename SagaStatus.PROCESSING to IN_FLIGHT
```

## PR checklist

Before requesting review:

- [ ] Artifact `version` bumped (SemVer rules below).
- [ ] Artifact's `CHANGELOG.md` updated under `## [Unreleased]`.
- [ ] Root `manifest.yaml` version aligned with the artifact frontmatter.
- [ ] `lg5-spring-sha` updated if the change was validated against a new SHA.
- [ ] `bash scripts/validate.sh` is green locally.
- [ ] PR title follows Conventional Commits.

## Versioning policy

Per-artifact SemVer:

- `feat`  → MINOR bump in the bundle version
- `fix`   → PATCH bump in the bundle version
- `feat!` / `BREAKING CHANGE:` → MAJOR bump

The **bundle** version (`manifest.yaml > bundle.version`) is the single source of truth.

## Release flow

After a PR is merged to `main`:

1. Maintainer moves `[Unreleased]` to `[X.Y.Z] — YYYY-MM-DD` in the relevant `CHANGELOG.md`.
2. Aligns `bundle.version` and `released:` in root `manifest.yaml`.
3. Updates the compatibility matrix in `README.md`.
4. Automated release: The merge itself triggers the `Release Automation` workflow if the `release` label is present.
5. Manual release (backup): Tags: `git tag -a vX.Y.Z -m "lg5-spring-agent-os vX.Y.Z"` and `git push --tags`.

## How artifacts are validated

`scripts/validate.sh` checks:

- Each artifact has the required frontmatter.
- `version` and `lg5-spring-sha` match the root `manifest.yaml`.
- All skills declare the **same** `lg5-spring-sha` (consistent bundle).
- No forbidden local paths inside fenced code blocks (only `/tmp/lg5-study/`
  is allowed).

CI runs the same script on every PR (`.github/workflows/validate.yml`).
