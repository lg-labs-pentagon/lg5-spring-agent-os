---
description: Scaffold the unified VitePress documentation site (lg5-vitepress-docs skill) into a consumer lg5-spring service — drops the `docs/site/` aggregator surface, the 6 docs CI jobs, and the Firebase config files into place. Idempotent; safe to re-run.
argument-hint: <service-name> <firebase-project-id>
allowed-tools: bash, read, write, edit, glob, grep
---

# /scaffold-docs

You are installing the unified VitePress documentation site into a consumer
lg5-spring microservice. This command operationalises the `lg5-vitepress-docs`
skill and assumes the upstream skills `lg5-api-docs`, `lg5-allure-report`, and
`lg5-github-actions` are already installed and producing artifacts.

## Inputs

- `<service-name>` — the consumer service name in lowercase-hyphen form (e.g.
  `loyalty-ledger`, `payment`). Drives sidebar titles, the `description` in
  `package.json`, and the runbook prose.
- `<firebase-project-id>` — the Firebase project ID where the two hosting
  sites live (e.g. `lglabs-loyalty`). Used in `.firebaserc`.

If the user did not provide both, ask for them BEFORE making any file changes.

## Pre-flight checks

1. Verify the consumer repo is at the root of the working directory (look for
   `pom.xml`).
2. Verify the bundle is installed at `.agent-os/skills/lg5-vitepress-docs/`.
   If not, ask the user to run `bin/install.sh` from the bundle first.
3. Verify `lg5-api-docs` skill is also installed (Swagger UI / AsyncAPI HTML
   wrappers are produced by its upstream `openapi` / `asyncapi` CI jobs).
4. Verify the canonical CI pipeline from `lg5-github-actions` is in place at
   `.github/workflows/c-integration.yml`. This command **adds 6 jobs to that
   workflow**; it does not create a new one.
5. Check whether `docs/site/`, `firebase.json`, `.firebaserc`, or the 6 docs
   jobs already exist. If yes, ask the user before overwriting.

## Steps

### 1) Drop the `docs/site/` scaffold

Copy without modification:

```bash
mkdir -p docs/site
cp -R .agent-os/skills/lg5-vitepress-docs/templates/docs/site/. docs/site/
```

This creates:
- `docs/site/package.json` (pinned vitepress 1.6.x, firebase-tools 15.x,
  linkinator 7.x, `packageManager: "pnpm@11.0.9"`).
- `docs/site/pnpm-workspace.yaml` with `allowBuilds: [esbuild, protobufjs, re2]`.
- `docs/site/.vitepress/config.ts` — reads `DOCS_BASE`, `COMMIT_SHA`,
  `BUILD_TIME`, `PR_NUMBER` from env.
- `docs/site/.vitepress/theme/{index.ts,SourceStateFooter.vue}` — the
  short-SHA-slicing footer.
- `docs/site/public/.gitkeep` — keeps the `public/` dir in git.
- `docs/site/{index,architecture/index,api/index,events/index,adr/index,runbook/index,glossary/index,releases/changelog}.md`
  — placeholder section indexes with the canonical CTAs (relative links to
  `./swagger-ui.html`, `./asyncapi.html`).
- `docs/site/{api,events,architecture}/_placeholder.md` — initial "not
  produced" copy; rewritten by `check-artifacts.mjs` on every build.
- `docs/site/scripts/{check-artifacts,linkinator-to-annotations}.mjs` — the
  two warn-don't-fail helpers.

### 2) Rewrite placeholders

```bash
# Replace <svc> in package.json description and runbook prose.
find docs/site -type f \( -name "*.md" -o -name "package.json" -o -name "config.ts" \) -print0 \
  | xargs -0 sed -i.bak "s|<svc>|<service-name>|g"
find docs/site -name "*.bak" -delete
```

Update `docs/site/.vitepress/config.ts`:
- `title: '<service-name>'`
- The 6 nav entries (`/architecture/`, `/api/`, `/events/`, `/adr/`,
  `/runbook/`, `/glossary/`) are kept verbatim; only the `title` changes
  per-service.

### 3) Drop the Firebase config

Copy:
```bash
cp .agent-os/skills/lg5-vitepress-docs/templates/firebase.json firebase.json
cp .agent-os/skills/lg5-vitepress-docs/templates/.firebaserc .firebaserc
```

Edit `.firebaserc`:
- Replace `<firebase-project-id>` with the user-supplied value (3
  occurrences: the project alias, the targets-key, both hosting target IDs).

The shipped `firebase.json` declares 2 hosting targets (`docs` rooted at
`docs/site/.vitepress/dist`, `allure` rooted at `<svc>-acceptance-test/target/site/allure-maven-plugin`).

### 4) Add Make targets

Append to the existing service `Makefile` (no overwrite; check existence first):

```makefile
.PHONY: docs-install docs-build-pages docs-build-firebase docs-dev docs-clean docs-preview

docs-install:
	cd docs/site && pnpm install --frozen-lockfile

docs-build-pages: docs-install
	cd docs/site && DOCS_BASE='/<service-name>/' pnpm run docs:build

docs-build-firebase: docs-install
	cd docs/site && DOCS_BASE='/' pnpm run docs:build

docs-dev: docs-install
	cd docs/site && pnpm run docs:dev

docs-clean:
	rm -rf docs/site/.vitepress/dist docs/site/node_modules

docs-preview: docs-build-firebase
	cd docs/site && pnpm exec firebase hosting:channel:deploy preview-local --only docs --expires 1d
```

### 5) Append 6 jobs to `c-integration.yml`

Read `.agent-os/skills/lg5-vitepress-docs/templates/.github/workflows/docs-jobs.snippet.yml`
and append it to the existing `.github/workflows/c-integration.yml` after the
existing `allure-report` job. The snippet defines:

| Job | Trigger gate | Depends on |
|---|---|---|
| `docs-build-pages` | every push/PR | `openapi`, `asyncapi`, `visualization`, `allure-report` |
| `docs-build-firebase` | every push/PR | same |
| `pages-deploy` | `main` push only | `docs-build-pages` |
| `firebase-deploy-docs` | `main` push only | `docs-build-firebase` |
| `firebase-deploy-allure` | `main` push only | `allure-report` |
| `firebase-preview` | PR with label `docs/preview` | `docs-build-firebase` |

All 4 deploy/preview jobs use the Firebase secret
`FIREBASE_SERVICE_ACCOUNT_<UPPERCASE_PROJECT_ID>`; replace `<UPPERCASE_PROJECT_ID>`
in the snippet with the user-supplied value uppercased and hyphens turned to
underscores (e.g. `lglabs-loyalty` → `LGLABS_LOYALTY`).

The `docs-build-*` jobs include the `env:` block injecting `COMMIT_SHA`,
`BUILD_TIME` (shell-derived), and `PR_NUMBER`. DO NOT remove this block — it
is the fix for the BUG-1 / BUG-3 / REQ-020 pitfalls catalogued in the skill.

### 6) `.gitignore` additions

Append (no overwrite):

```
# VitePress docs build artifacts
docs/site/node_modules/
docs/site/.vitepress/dist/
docs/site/.vitepress/cache/
```

### 7) Manual setup (operator action; print as final output)

Print this checklist for the operator to complete after merge:

```
Manual setup (do this once, in the GitHub repo settings):

1. Create Firebase project `<firebase-project-id>` with 2 hosting sites:
   - `<firebase-project-id>-docs`
   - `<firebase-project-id>-allure`

2. Generate a service account JSON with `Firebase Hosting Admin` role.

3. In the GitHub repo settings → Secrets and variables → Actions:
   - Add secret `FIREBASE_SERVICE_ACCOUNT_<UPPERCASE>` with the JSON contents.

4. In the GitHub repo settings → Pages:
   - Source: GitHub Actions.

5. In the GitHub repo → Labels:
   - Create label `docs/preview` (any color).

6. The first push to main after these steps will produce:
   - https://<repo-owner>.github.io/<repo-name>/      (Pages)
   - https://<firebase-project-id>-docs.web.app/      (Firebase docs)
   - https://<firebase-project-id>-allure.web.app/    (Firebase allure)
```

## Post-conditions

- `docs/site/` exists with full scaffold.
- `firebase.json` + `.firebaserc` at repo root with correct project ID.
- `Makefile` has 6 new docs targets.
- `c-integration.yml` has 6 new jobs after `allure-report`.
- `.gitignore` excludes VitePress build artifacts.
- The next PR will produce GitHub Actions `::warning` annotations for any
  upstream artifact not yet wired (e.g. if `dependency-graph.png` job is
  missing), but the build will succeed.

## Verification

After the operator completes step 7 above and a push to main happens, verify:

1. `pages-deploy` job → success → Pages URL serves 200.
2. `firebase-deploy-docs` job → success → Firebase docs URL serves 200.
3. Open `/api/` → footer reads `Built from <7-char-sha> · <ISO>`, page shows
   "Open the Swagger UI →" CTA, click resolves to `./swagger-ui.html`
   (relative). Same for `/events/`.
4. Open a throwaway PR, add label `docs/preview`. After ≤10min, bot comment
   on the PR with the preview URL; footer additionally shows `(PR #<n>)`.
