# Contributing to Agent OS

Thank you for your interest in contributing to the `lg5-spring-agent-os` project! Whether you're fixing a bug, adding a new skill, or improving documentation, your help is welcome.

## How to Contribute

1.  **Find an issue** or propose a new feature/rule by opening a GitHub Issue.
2.  **Fork the repository** (or create a branch if you're a collaborator).
3.  **Implement your changes** following the Conventional Commits guidelines.
4.  **Run validation** locally: `bash scripts/validate.sh`.
5.  **Submit a Pull Request**.

## Branching Strategy

- `main` is protected. All changes must go through Pull Requests.
- Branch names should follow the pattern:
    - `feat/<scope>-<desc>`
    - `fix/<scope>-<desc>`
    - `docs/<scope>-<desc>`

## Commit Conventions

We use [Conventional Commits](https://www.conventionalcommits.org/). This helps us automate versioning and release notes.

- `feat(scope): ...` for new features or skills.
- `fix(scope): ...` for bug fixes.
- `docs(scope): ...` for documentation changes.
- `chore(tooling): ...` for script or CI updates.

## Versioning & Release Policy

The project uses a **Hybrid Versioning** system:

- **Official Stable Releases**: To trigger a clean version (e.g., `v4.6.0`), increment the version in `manifest.yaml`.
- **Continuous Pre-releases**: If you merge with the `release` label without bumping the version, the system appends a short commit SHA (e.g., `v4.5.1.a1b2c3d`).

### Decision Matrix

| Change Type | Version Component | Example |
| :--- | :--- | :--- |
| **Breaking Change** | MAJOR | `4.5.1` → `5.0.0` |
| **New Feature / Skill** | MINOR | `4.5.1` → `4.6.0` |
| **Bug Fix / Docs** | PATCH | `4.5.1` → `4.5.2` |
| **WIP / Mid-feature** | SHA Suffix | `4.5.1` → `4.5.1.a1b2c3d` |

## Local Validation

Before submitting your PR, ensure all artifacts follow the project's rules:

```bash
bash scripts/validate.sh
```

This script checks for:
- Correct frontmatter in all skills, rules, and commands.
- Consistency between artifact versions and the root `manifest.yaml`.
- SHA compatibility with the `lg5-spring` framework.
- Security checks on code blocks.

---

*Note: For detailed technical requirements, see the full [CONTRIBUTING.md](https://github.com/lg-labs-pentagon/lg5-spring-agent-os/blob/main/CONTRIBUTING.md) in the repository root.*
