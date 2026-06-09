---
name: lg5-vitepress-docs
version: 4.4.3
lg5-spring-sha: d0d754a
last-validated: 2026-05-12
description: How to publish a unified VitePress documentation site for an lg5-spring service — aggregates the OpenAPI/AsyncAPI viewers (from `lg5-api-docs`), Allure acceptance reports, architecture visualizations, ADRs, and runbooks under a single navigable surface. Covers dual-target deploy (GitHub Pages + Firebase Hosting), 7-day PR preview channels, source-state footer (short SHA + ISO timestamp + PR number), pnpm 11 build-script gating, VitePress `public/` static-asset wiring, base-aware relative links, and the `check-artifacts.mjs` warn-don't-fail pattern. Load this skill when the user asks about a documentation site, VitePress, Firebase Hosting + Pages dual deploy, docs preview channels, or how to aggregate API/AsyncAPI/Allure outputs into a single browseable surface.
---

# lg5-spring — Unified Documentation Site (VitePress aggregator)

> Reference impl:
> - `lg5-loyalty-ledger/docs/site/` (the canonical aggregator surface)
> - `lg5-loyalty-ledger/.github/workflows/c-integration.yml`
>   (jobs `docs-build-pages`, `docs-build-firebase`, `pages-deploy`,
>   `firebase-deploy-docs`, `firebase-deploy-allure`, `firebase-preview`)
> - SDD spec set: `lg5-loyalty-ledger/docs/specs/004-project-docs/`
>   (intent → prd → plan → design → tasks → 3 verify-reports).
>
> Complements:
> - **`lg5-api-docs`** — produces the standalone OpenAPI (Swagger UI) and
>   AsyncAPI (Studio look) viewers that this skill aggregates.
> - **`lg5-allure-report`** — produces the acceptance report artifact
>   that this skill links from the main navigation.
> - **`lg5-github-actions`** — owns the upstream `openapi`, `asyncapi`,
>   `allure`, `visualization` jobs whose artifacts this skill consumes.

## Why this exists

`lg5-api-docs` ships the **per-contract viewers** (one HTML page for
OpenAPI, one for AsyncAPI). `lg5-allure-report` ships the **per-run
acceptance report**. Neither, individually, gives a stakeholder a
single URL to land on that says "this is everything about the
loyalty-ledger service: architecture, sync contract, async contract,
acceptance status, decision history, runbook."

This skill captures the **aggregator** layer:

- A VitePress site under `docs/site/` whose Markdown lives next to the
  code and whose nav stitches the upstream artifacts into one
  navigable surface.
- **Dual deploy** so the org can choose:
  - GitHub Pages (free, `lg-labs.github.io/<service>/`) — the
    canonical-of-record location.
  - Firebase Hosting (`<project>-docs.web.app`) — supports per-PR
    preview channels with TTL.
- **PR preview channels** so reviewers can open the proposed docs at a
  shareable URL before approving.
- **Source-state footer** on every page (REQ-020 equivalent): short
  commit SHA + ISO timestamp + (for previews) PR number, so the
  reader always knows which trunk state they're looking at.

## Module layout (consumer side)

Mirror this in your service. **All Node tooling stays under
`docs/site/`** — the repository root stays Maven-pure.

```
docs/
  site/
    package.json                    # vitepress, firebase-tools, linkinator
    pnpm-workspace.yaml             # allowBuilds: [esbuild, protobufjs, re2]
    .vitepress/
      config.ts                     # base, nav, sidebar, search, define
      theme/
        index.ts                    # extends default theme
        SourceStateFooter.vue       # short-SHA + ISO + PR# footer
    public/                         # static assets served verbatim
      .gitkeep                      # keep the dir in git when empty
      # CI deposits at build time:
      #   api/swagger-ui.html
      #   api/openapi.yaml
      #   events/asyncapi.html
      #   events/asyncapi.yaml
      #   dependency-graph.png
      #   gource.mp4
    index.md                        # service overview (home)
    architecture/
      index.md                      # links to dependency-graph.png + gource.mp4
      _placeholder.md               # rewritten by check-artifacts.mjs
    api/
      index.md                      # CTA: ./swagger-ui.html (relative!)
      _placeholder.md
    events/
      index.md                      # CTA: ./asyncapi.html (relative!)
      _placeholder.md
    adr/
      index.md                      # ADR table-of-contents
    runbook/
      index.md                      # operator onboarding
    glossary/
      index.md
    releases/
      changelog.md
    scripts/
      check-artifacts.mjs           # placeholder writer (warn-not-fail)
      linkinator-to-annotations.mjs # broken-link surfacing (warn-not-fail)
firebase.json                       # 2 hosting targets: docs, allure
.firebaserc                         # project alias → hosting targets
```

## Critical wiring rules

### Rule 1 — VitePress `public/` for non-Markdown content

**Any HTML/PNG/MP4/PDF that you want VitePress to serve verbatim MUST
live under `docs/site/public/`.** VitePress silently drops sibling
`.html` files placed next to `.md` sources during build — they never
reach `dist/`. This is non-obvious; many implementers (including this
one) hit it first.

CI copies upstream artifacts as:

```yaml
- name: Download openapi-doc
  uses: actions/download-artifact@v4
  with:
    name: openapi-doc
    path: ${{ runner.temp }}/openapi-artifact
- name: Place swagger-ui.html into docs/site/public/api/
  run: |
    mkdir -p docs/site/public/api
    cp "${{ runner.temp }}/openapi-artifact/index.html"  docs/site/public/api/swagger-ui.html
    cp "${{ runner.temp }}/openapi-artifact/openapi.yaml" docs/site/public/api/openapi.yaml
```

The Markdown landing page then links **relatively**:

```markdown
# API (synchronous contract)

[**Open the Swagger UI →**](./swagger-ui.html){target="_blank"}
```

### Rule 2 — Relative links for base-aware rewriting

Absolute Markdown links (`/api/swagger-ui.html`) are **not rewritten**
by VitePress when `base` is non-root (`/lg5-loyalty-ledger/`). They
produce `<a href="/api/swagger-ui.html">` which 404s on GitHub Pages.
Always use `./` relative links from within section indexes.

### Rule 3 — Dual base-path build

The same source tree is built twice, with different `DOCS_BASE`:

```bash
# Pages build (org-scoped repo URL):
DOCS_BASE='/lg5-loyalty-ledger/' pnpm run docs:build

# Firebase build (root domain):
DOCS_BASE='/' pnpm run docs:build
```

`.vitepress/config.ts` reads `process.env.DOCS_BASE` with `'/'`
default. Two `docs-build-*` CI jobs, two `upload-artifact`, two
deploy targets. Never try to make a single build serve both.

### Rule 4 — Source-state footer env injection

The footer reads `__COMMIT_SHA__`, `__BUILD_TIME__`, `__PR_NUMBER__`
from Vite `define`. These are populated from `process.env` at config
time. CI **must** inject them in every `docs-build-*` step:

```yaml
- name: Build VitePress site (Pages base)
  env:
    COMMIT_SHA: ${{ github.sha }}
    PR_NUMBER: ${{ github.event.pull_request.number }}
  run: |
    BUILD_TIME="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    export BUILD_TIME
    make docs-build-pages
```

The component slices to 7 chars for display (REQ-020 short identifier):

```vue
const fullSha = __COMMIT_SHA__;
const sha = fullSha.length > 7 ? fullSha.slice(0, 7) : fullSha;
```

### Rule 5 — pnpm 11 build-script gating

pnpm 11 dropped `npm_config_strict_dep_builds`. Declare allowed
post-install scripts in `docs/site/pnpm-workspace.yaml`:

```yaml
allowBuilds:
  - esbuild
  - protobufjs
  - re2
```

Without this, `pnpm install --frozen-lockfile` warns about unbuilt
deps and esbuild silently fails to extract its native binary.

### Rule 6 — Warn-don't-fail artifact handling

The two helper scripts under `docs/site/scripts/` are designed so
that **a missing upstream artifact never fails the build** — it
surfaces as a GitHub Actions `::warning` annotation instead. This
preserves the docs-as-mirror invariant: the surface always reflects
the latest trunk state, even when one upstream job is broken.

- `check-artifacts.mjs` rewrites `<section>/_placeholder.md` with a
  blockquote ("not produced in the most recent CI run") for each
  missing artifact, and emits `::warning file=...` on stdout.
- `linkinator-to-annotations.mjs` runs linkinator over the built
  `dist/` and converts each broken link into a `::warning` (never
  exit code).

## CI pipeline shape (deltas on top of `lg5-github-actions`)

Add **6 jobs** to the existing `c-integration.yml`:

| Job | Trigger | Depends on | Action |
|---|---|---|---|
| `docs-build-pages` | every push/PR | `openapi`, `asyncapi`, `visualization`, `allure-report` | `make docs-build-pages` → upload `docs-dist-pages` |
| `docs-build-firebase` | every push/PR | same | `make docs-build-firebase` → upload `docs-dist-firebase` |
| `pages-deploy` | `main` push only | `docs-build-pages` | `actions/deploy-pages@v4` |
| `firebase-deploy-docs` | `main` push only | `docs-build-firebase` | `FirebaseExtended/action-hosting-deploy@v0` (channelId: `live`) |
| `firebase-deploy-allure` | `main` push only | `allure-report` | `FirebaseExtended/action-hosting-deploy@v0` (target: `allure`) |
| `firebase-preview` | PR with label `docs/preview` | `docs-build-firebase` | `FirebaseExtended/action-hosting-deploy@v0` (expires: `7d`) |

## Firebase project setup (one-time, per service)

1. Create Firebase project, e.g. `<orgname>-<servicename>` (max 30 chars).
2. Create 2 hosting sites in that project:
   - `<orgname>-<servicename>-docs` (for the aggregator)
   - `<orgname>-<servicename>-allure` (for the acceptance report)
3. Map them as targets in `.firebaserc`:
   ```json
   {
     "projects": { "default": "<orgname>-<servicename>" },
     "targets": {
       "<orgname>-<servicename>": {
         "hosting": {
           "docs":   ["<orgname>-<servicename>-docs"],
           "allure": ["<orgname>-<servicename>-allure"]
         }
       }
     }
   }
   ```
4. Generate a service account JSON with **Firebase Hosting Admin**
   role; store as GitHub repo secret
   `FIREBASE_SERVICE_ACCOUNT_<UPPERCASE_PROJECT>`.
5. Create the label `docs/preview` in the GitHub repo (used to
   opt-in PR preview channels).

## REQ traceability (canonical mapping)

Use this skill to satisfy these recurring requirements when present
in a service's PRD:

| REQ pattern | How this skill satisfies it |
|---|---|
| "Single landing surface for the service" | `index.md` + nav with all 6 entries |
| "Sync contract reachable" | `api/swagger-ui.html` from `public/` |
| "Async contract reachable" | `events/asyncapi.html` from `public/` |
| "Acceptance report reachable" | nav link to Firebase allure site |
| "Architecture visualization" | `architecture/` linking `public/{dependency-graph.png,gource.mp4}` |
| "Mirrors latest trunk state, no manual republication" | CI runs on every push to main |
| "Source-state visible on every page" | `SourceStateFooter.vue` short SHA + ISO |
| "PR-scoped preview" | Firebase preview channel, 7d TTL |
| "Preview shows which PR it reflects" | footer `PR_NUMBER` segment |

## Common pitfalls (catalogued from feat 004)

1. **Footer renders `dev`**: `COMMIT_SHA` env not injected in CI build
   step (Rule 4).
2. **Footer renders full 40-char SHA**: component forgot to `.slice(0, 7)`.
3. **API/Events pages render only `<h1>`**: viewer HTML placed in
   `docs/site/api/` instead of `docs/site/public/api/` (Rule 1).
4. **Pages 404 on viewer link**: absolute Markdown link instead of
   relative (Rule 2).
5. **`pnpm install` warns about unbuilt deps**: missing
   `pnpm-workspace.yaml` with `allowBuilds` (Rule 5).
6. **Spec doc cites wrong org URL**: GitHub Pages serves at
   `<repo-owner>.github.io/<repo-name>/`, not the org-vanity URL.
   Always derive from `${{ github.repository }}`.

## When to use this skill

- Greenfield service: combine with `lg5-new-service` + `lg5-api-docs`
  + `lg5-github-actions` + `lg5-allure-report` to ship a complete
  service with docs from day one.
- Existing service: invoke `/scaffold-docs` to drop the `docs/site/`
  scaffold and the 6 CI jobs in place. Idempotent; safe to re-run.
- Diagnosing a broken docs surface: this skill's "Common pitfalls"
  section is the first place to look.
