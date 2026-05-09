# lg5-spring-skills

> Versioned agent knowledge base for building microservices on top of the
> [`lg5-spring`](https://github.com/lg-labs-pentagon/lg5-spring) framework.

This repository ships a curated set of **agent skills** (markdown files with YAML
frontmatter) plus an `AGENTS.md` rule set, designed to be consumed by AI coding
agents (OpenCode, Claude Code, Cursor, Continue, Copilot, etc.) when working on
services that follow the lg5-spring conventions.

## What's inside

```
lg5-spring-skills/
├── AGENTS.md                    # Always-loaded rules + skill routing table
├── skills/
│   ├── manifest.yaml            # SSoT for installed skill versions
│   ├── CHANGELOG.md             # Bundle-level changelog
│   ├── lg5-spring-overview/
│   │   ├── SKILL.md
│   │   └── CHANGELOG.md
│   ├── lg5-new-service/
│   ├── lg5-saga/
│   ├── lg5-outbox/
│   ├── lg5-kafka-avro/
│   ├── lg5-atdd/
│   └── food-ordering-system/
├── scripts/
│   ├── validate-skills.sh       # CI / local sanity checks
│   └── install-skills.sh        # Install into a consumer repo
├── .github/workflows/validate.yml
├── CONTRIBUTING.md
└── LICENSE
```

## Versioning

This bundle follows [Semantic Versioning 2.0.0](https://semver.org/spec/v2.0.0.html):

- **MAJOR** — breaking re-organization (skill renames/deletions, removed mandatory rules).
- **MINOR** — new skill, new section in an existing skill, validation against a new framework SHA.
- **PATCH** — clarifications, anti-pattern additions, no recipe change.

Every release is tagged (`v0.1.0`, `v0.2.0`, …) and pinned to a single
`lg5-spring-sha` (the framework commit it was validated against).
See `skills/manifest.yaml` and `skills/CHANGELOG.md`.

## Compatibility matrix

| Bundle version | lg5-spring SHA | Released   |
|---------------:|----------------|------------|
| `0.1.0`        | `cbb6783`      | 2026-05-09 |

When the framework moves to a new commit, the next bundle release re-validates
all skills and bumps the `lg5-spring-sha` field in every frontmatter + manifest.

## How to consume from a microservice repo

Pick **one** of the three integration modes below.

### Mode A — Git submodule (recommended for monorepo-style governance)

```bash
cd your-microservice-repo
git submodule add -b main https://github.com/lg-labs-pentagon/lg5-spring-skills.git .lg5-skills
git submodule update --init

# Install into the agent's expected location
.lg5-skills/scripts/install-skills.sh .opencode/skills

# Pin to a specific release
git -C .lg5-skills checkout v0.1.0
git add .gitmodules .lg5-skills && git commit -m "chore(agents): pin lg5-spring-skills v0.1.0"
```

Pros: explicit, audit-friendly, the consumer sees exactly which SHA is in use.
Cons: developers need `git submodule update --init --recursive` after clone.

### Mode B — Plain copy at a tag (no submodule overhead)

```bash
cd your-microservice-repo
curl -sL https://github.com/lg-labs-pentagon/lg5-spring-skills/archive/refs/tags/v0.1.0.tar.gz \
  | tar -xz -C /tmp
/tmp/lg5-spring-skills-0.1.0/scripts/install-skills.sh .opencode/skills
echo "0.1.0" > .opencode/skills/.bundle-version
git add .opencode/skills && git commit -m "chore(agents): install lg5-spring-skills@0.1.0"
```

Pros: zero submodule machinery; agent state is self-contained in the consumer.
Cons: harder to upgrade (re-run the install at the new tag, review diff).

### Mode C — Sparse checkout (large monorepos, partial install)

```bash
git clone --filter=blob:none --no-checkout https://github.com/lg-labs-pentagon/lg5-spring-skills.git .lg5-skills
git -C .lg5-skills sparse-checkout init --cone
git -C .lg5-skills sparse-checkout set skills/lg5-saga skills/lg5-outbox
git -C .lg5-skills checkout v0.1.0
.lg5-skills/scripts/install-skills.sh .opencode/skills
```

## Validation

```bash
bash scripts/validate-skills.sh
```

Checks: required frontmatter fields, SemVer format, name↔directory match,
single bundle-wide `lg5-spring-sha`, manifest consistency, no stray local paths
inside fenced code blocks. The same script runs in CI on every push and PR.

## Contributing

See [CONTRIBUTING.md](./CONTRIBUTING.md). TL;DR:

1. Branch off `main`.
2. Edit a skill or add a new one (mirror the existing structure).
3. Update the skill's `CHANGELOG.md` and the bundle `skills/CHANGELOG.md`.
4. Bump the relevant `version` in the skill's frontmatter and in `manifest.yaml`.
5. Run `bash scripts/validate-skills.sh` until green.
6. Open a PR with a Conventional Commits title (e.g. `feat(saga): …`).
7. Maintainer tags a new bundle release after merge.

## License

See [LICENSE](./LICENSE).
