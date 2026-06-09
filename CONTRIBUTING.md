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

## Versioning & Release Policy

We use a **Hybrid Versioning** system to balance stability with continuous delivery:

1.  **Stable Releases (Clean Version)**:
    - To create an official stable release (e.g., `v4.6.0`), you **must** manually increment the `version` field in the root `manifest.yaml` in your PR.
    - When the PR is merged with the `release` label, the system checks if that tag already exists. If it's new, it creates a clean, official release.

2.  **Continuous Releases (SHA-suffixed)**:
    - If you merge a PR with the `release` label **without** incrementing the version in `manifest.yaml`, the automation will automatically append the short commit SHA (e.g., `v4.5.1.a1b2c3d`).
    - This allows for "early-access" releases that can be tested in consumer services immediately without forcing a formal version bump for every small change.

### SemVer decision matrix

| Change Type | Version Component | Example |
| :--- | :--- | :--- |
| **Breaking Change** | MAJOR | `4.5.1` → `5.0.0` |
| **New Feature / Skill** | MINOR | `4.5.1` → `4.6.0` |
| **Bug Fix / Docs** | PATCH | `4.5.1` → `4.5.2` |
| **WIP / Mid-feature** | SHA Suffix | `4.5.1` → `4.5.1.a1b2c3d` |

## PR checklist

Before requesting review:

- [ ] (Optional) Root `manifest.yaml` version bumped if you want a **stable** release.
- [ ] PR has the **`release`** label if you want to trigger the automated release/tagging.
- [ ] Artifact's `CHANGELOG.md` updated under `## [Unreleased]`.
- [ ] `lg5-spring-sha` updated if the change was validated against a new SHA.
- [ ] `bash scripts/validate.sh` is green locally.
- [ ] PR title follows Conventional Commits.

## Release flow

After a PR is merged to `main`:

1.  **Automated release**: The merge itself triggers the `Release Automation` workflow if the `release` label is present. It handles tag creation and version naming (clean or SHA-suffixed).
2.  **Automatic Docs**: Documentation is automatically redeployed to GitHub Pages only after a successful release.
3.  **Consumer side**: Developers can use `.agent-os/scripts/install.sh --upgrade` in their services to pull the latest tag (stable or SHA-suffixed).

## How artifacts are validated


`scripts/validate.sh` checks:

- Each artifact has the required frontmatter.
- `version` and `lg5-spring-sha` match the root `manifest.yaml`.
- All skills declare the **same** `lg5-spring-sha` (consistent bundle).
- No forbidden local paths inside fenced code blocks (only `/tmp/lg5-study/`
  is allowed).

CI runs the same script on every PR (`.github/workflows/validate.yml`).
