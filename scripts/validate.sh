#!/usr/bin/env bash
# validate.sh — sanity checks for the lg5-spring-agent-os bundle.
#
# Single CI/local entry point. Runs one validator per artifact type that
# exists on disk. Validates:
#
#   skills    : SKILL.md + CHANGELOG.md per dir; YAML frontmatter with
#               name, version, lg5-spring-sha, description; SemVer; name ↔
#               directory match; bundle-wide lg5-spring-sha consistency;
#               manifest ↔ disk parity; no forbidden /tmp/ paths in fenced
#               code blocks (only /tmp/lg5-study/ is allowed).
#
#   rules     : <ID>-<slug>.md per rule with frontmatter (id, version,
#               lg5-spring-sha, severity, scope, tags, description); id ↔
#               filename match; severity ∈ {must, should, info}; manifest
#               ↔ disk parity.
#
#   commands  : <name>.md per command with frontmatter (description,
#               argument-hint, allowed-tools); manifest ↔ disk parity.
#
#   subagents : <name>.md per subagent with frontmatter (name, description,
#               tools); name ↔ filename match; manifest ↔ disk parity.
#               `model:` is intentionally NOT required — bundle is provider-agnostic
#               (consumer's default model is used).
#
#   specs     : <name>.md template/example with frontmatter (kind, name,
#               version, description); kind ∈ {template, example}; manifest
#               ↔ disk parity.
#
# Cross-bundle invariants:
#   - bundle.lg5-spring-sha is identical across all manifest.yaml files.
#   - bundle.version is identical across all manifest.yaml files.
#
# Optional install-output check (--install):
#   Runs scripts/install.sh against a disposable temp consumer fixture and
#   asserts that the resulting .opencode/{agents,commands,skills}/ trees
#   contain no bundle housekeeping files (CHANGELOG.md, manifest.yaml,
#   .DS_Store) and that every .md under agents/ and commands/ has YAML
#   frontmatter. This is the regression test for issue #15 and is gated
#   behind --install because it materializes a temp filesystem (slower,
#   and unnecessary for the artifact-side checks).
#
# Exit codes:
#   0 — all checks passed
#   1 — one or more checks failed
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
fail=0

# Filenames that must NOT appear under .opencode/{agents,commands,skills}/.
# Keep in sync with scripts/install.sh `meta_skip`.
META_SKIP=("CHANGELOG.md" "manifest.yaml" ".DS_Store")

# Argument parsing
run_install_check=0
for arg in "$@"; do
  case "${arg}" in
    --install) run_install_check=1 ;;
    -h|--help)
      sed -n '2,40p' "$0"
      exit 0
      ;;
    *) printf "ERROR: unknown argument: %s\n" "${arg}" >&2; exit 2 ;;
  esac
done

red()    { printf "\033[31m%s\033[0m\n" "$*"; }
green()  { printf "\033[32m%s\033[0m\n" "$*"; }
yellow() { printf "\033[33m%s\033[0m\n" "$*"; }

err() { red "  ✗ $*"; fail=1; }
ok()  { green "  ✓ $*"; }

# ─────────────────────────────────────────────────────────────────────────────
# Helpers
# ─────────────────────────────────────────────────────────────────────────────

# Extract YAML frontmatter (text between the first two `---` lines) of a file.
extract_frontmatter() {
  awk '/^---$/{c++; next} c==1{print} c==2{exit}' "$1"
}

# Extract a top-level YAML key value from a frontmatter block (passed via stdin).
fm_get() {
  local key="$1"
  grep -E "^${key}:" | head -n1 | sed -E "s/^${key}:[[:space:]]*//;s/[[:space:]]+$//;s/^[\"']//;s/[\"']\$//"
}

# Read `bundle.<key>: value` from a manifest.yaml.
manifest_get() {
  local manifest="$1" key="$2"
  awk -v k="${key}" '
    /^bundle:/        { in_bundle=1; next }
    in_bundle && /^[a-zA-Z]/ { in_bundle=0 }
    in_bundle && $1 == (k":") { sub(/^[[:space:]]*[a-zA-Z0-9_-]+:[[:space:]]*/, ""); print; exit }
  ' "${manifest}"
}

semver_ok() {
  [[ "$1" =~ ^[0-9]+\.[0-9]+\.[0-9]+(-[A-Za-z0-9.-]+)?$ ]]
}

# Get global values from root manifest
GLOBAL_MANIFEST="${ROOT}/manifest.yaml"
if [[ ! -f "${GLOBAL_MANIFEST}" ]]; then
  echo "ERROR: root manifest.yaml missing at ${GLOBAL_MANIFEST}"
  exit 1
fi
GLOBAL_VERSION="$(manifest_get "${GLOBAL_MANIFEST}" version)"
GLOBAL_SHA="$(manifest_get "${GLOBAL_MANIFEST}" lg5-spring-sha)"

# ─────────────────────────────────────────────────────────────────────────────
# Per-artifact validators
# ─────────────────────────────────────────────────────────────────────────────

validate_skills() {
  local dir="${ROOT}/skills"
  echo
  echo "═══ skills ═══"
  mapfile -t skill_dirs < <(find "${dir}" -mindepth 1 -maxdepth 1 -type d | sort)
  if [[ ${#skill_dirs[@]} -eq 0 ]]; then err "no skill directories found"; return; fi

  for d in "${skill_dirs[@]}"; do
    local name; name="$(basename "${d}")"
    echo; echo "→ ${name}"

    [[ -f "${d}/SKILL.md"     ]] && ok "SKILL.md present"     || { err "missing SKILL.md"; continue; }
    [[ -f "${d}/CHANGELOG.md" ]] && ok "CHANGELOG.md present" || err "missing CHANGELOG.md"

    local fm; fm="$(extract_frontmatter "${d}/SKILL.md")"
    if [[ -z "${fm}" ]]; then err "no YAML frontmatter"; continue; fi

    for key in name version lg5-spring-sha description; do
      grep -qE "^${key}:" <<<"${fm}" || err "frontmatter missing '${key}'"
    done

    local fm_name fm_ver fm_sha
    fm_name="$(echo "${fm}" | fm_get name)"
    fm_ver="$(echo "${fm}" | fm_get version)"
    fm_sha="$(echo "${fm}" | fm_get lg5-spring-sha)"

    [[ "${fm_name}" == "${name}" ]] && ok "name matches directory" \
      || err "frontmatter name '${fm_name}' != directory '${name}'"
    semver_ok "${fm_ver}" && ok "version ${fm_ver}" \
      || err "version '${fm_ver}' is not SemVer"
    
    [[ "${fm_ver}" == "${GLOBAL_VERSION}" ]] && ok "version matches root manifest" \
      || err "version '${fm_ver}' != global '${GLOBAL_VERSION}'"
    
    [[ "${fm_sha}" == "${GLOBAL_SHA}" ]] && ok "lg5-spring-sha matches root manifest" \
      || err "lg5-spring-sha '${fm_sha}' != global '${GLOBAL_SHA}'"

    if awk '
      /^```/ { inblock = !inblock; next }
      inblock && /\/tmp\// && !/\/tmp\/lg5-study(\/|[[:space:]]|$)/ { found=1; print NR": "$0 }
      END { exit found ? 1 : 0 }
    ' "${d}/SKILL.md" >/tmp/skill-tmp-refs.$$ 2>/dev/null; then
      ok "no forbidden /tmp/ references in code blocks"
    else
      err "forbidden /tmp/ references in code blocks (only /tmp/lg5-study/ allowed):"
      sed 's/^/      /' /tmp/skill-tmp-refs.$$
    fi
    rm -f /tmp/skill-tmp-refs.$$
  done
}

validate_rules() {
  local dir="${ROOT}/rules"
  echo; echo "═══ rules ═══"
  mapfile -t files < <(find "${dir}" -mindepth 1 -maxdepth 1 -type f -name 'RULE-*.md' | sort)
  if [[ ${#files[@]} -eq 0 ]]; then err "no rule files found"; return; fi

  local valid_severities=" must should info "
  local valid_scopes=" framework architecture kafka outbox saga testing style build reference "

  for f in "${files[@]}"; do
    local fname; fname="$(basename "${f}" .md)"
    echo; echo "→ ${fname}"
    local fm; fm="$(extract_frontmatter "${f}")"
    if [[ -z "${fm}" ]]; then err "no frontmatter"; continue; fi

    for key in id slug version lg5-spring-sha severity scope tags description; do
      grep -qE "^${key}:" <<<"${fm}" || err "frontmatter missing '${key}'"
    done

    local fm_id fm_slug fm_ver fm_sha fm_sev fm_scope
    fm_id="$(echo "${fm}"    | fm_get id)"
    fm_slug="$(echo "${fm}"  | fm_get slug)"
    fm_ver="$(echo "${fm}"   | fm_get version)"
    fm_sha="$(echo "${fm}"   | fm_get lg5-spring-sha)"
    fm_sev="$(echo "${fm}"   | fm_get severity)"
    fm_scope="$(echo "${fm}" | fm_get scope)"

    [[ "${fname}" == "${fm_id}-${fm_slug}" ]] && ok "filename matches id+slug" \
      || err "filename '${fname}' != '${fm_id}-${fm_slug}'"
    semver_ok "${fm_ver}" && ok "version ${fm_ver}" || err "version '${fm_ver}' not SemVer"
    
    [[ "${fm_ver}" == "${GLOBAL_VERSION}" ]] && ok "version matches root manifest" \
      || err "version '${fm_ver}' != global '${GLOBAL_VERSION}'"
    
    [[ "${fm_sha}" == "${GLOBAL_SHA}" ]] && ok "lg5-spring-sha matches root manifest" \
      || err "lg5-spring-sha '${fm_sha}' != global '${GLOBAL_SHA}'"

    [[ "${valid_severities}" == *" ${fm_sev} "* ]] && ok "severity ${fm_sev}" \
      || err "severity '${fm_sev}' not in {must,should,info}"
    [[ "${valid_scopes}" == *" ${fm_scope} "* ]] && ok "scope ${fm_scope}" \
      || err "scope '${fm_scope}' not in {framework,architecture,kafka,outbox,saga,testing,style,build,reference}"
  done
}

validate_commands() {
  local dir="${ROOT}/commands"
  echo; echo "═══ commands ═══"
  mapfile -t files < <(find "${dir}" -mindepth 1 -maxdepth 1 -type f -name '*.md' \
                        ! -name 'CHANGELOG.md' | sort)
  if [[ ${#files[@]} -eq 0 ]]; then err "no command files found"; return; fi

  for f in "${files[@]}"; do
    local fname; fname="$(basename "${f}" .md)"
    echo; echo "→ /${fname}"
    local fm; fm="$(extract_frontmatter "${f}")"
    if [[ -z "${fm}" ]]; then err "no frontmatter"; continue; fi
    for key in description argument-hint allowed-tools; do
      grep -qE "^${key}:" <<<"${fm}" || err "frontmatter missing '${key}'"
    done
    grep -qE '^[[:space:]]*\S' <<<"$(echo "${fm}" | fm_get description)" \
      && ok "description present" || err "description empty"
  done
}

validate_subagents() {
  local dir="${ROOT}/subagents"
  echo; echo "═══ subagents ═══"
  mapfile -t files < <(find "${dir}" -mindepth 1 -maxdepth 1 -type f -name '*.md' \
                        ! -name 'CHANGELOG.md' | sort)
  if [[ ${#files[@]} -eq 0 ]]; then err "no subagent files found"; return; fi

  for f in "${files[@]}"; do
    local fname; fname="$(basename "${f}" .md)"
    echo; echo "→ ${fname}"
    local fm; fm="$(extract_frontmatter "${f}")"
    if [[ -z "${fm}" ]]; then err "no frontmatter"; continue; fi
    for key in name description tools; do
      grep -qE "^${key}:" <<<"${fm}" || err "frontmatter missing '${key}'"
    done
    local fm_name; fm_name="$(echo "${fm}" | fm_get name)"
    [[ "${fm_name}" == "${fname}" ]] && ok "name matches filename" \
      || err "frontmatter name '${fm_name}' != filename '${fname}'"
  done
}

validate_specs() {
  local dir="${ROOT}/specs"
  echo; echo "═══ specs ═══"
  # Templates under templates/ + every .md under examples/<feature>/**
  mapfile -t files < <(
    {
      [[ -d "${dir}/templates" ]] && find "${dir}/templates" -mindepth 1 -maxdepth 1 -type f -name '*.md'
      [[ -d "${dir}/examples"  ]] && find "${dir}/examples"  -mindepth 2 -type f -name '*.md'
    } | sort
  )
  if [[ ${#files[@]} -eq 0 ]]; then err "no spec files found"; return; fi

  local valid_kinds=" template example example-prd example-adr example-plan example-tasks example-data-model example-research example-readme "
  for f in "${files[@]}"; do
    local rel="${f#${dir}/}"
    echo; echo "→ ${rel}"
    local fm; fm="$(extract_frontmatter "${f}")"
    if [[ -z "${fm}" ]]; then err "no frontmatter"; continue; fi
    for key in kind version description; do
      grep -qE "^${key}:" <<<"${fm}" || err "frontmatter missing '${key}'"
    done
    local fm_kind fm_ver
    fm_kind="$(echo "${fm}" | fm_get kind)"
    fm_ver="$(echo "${fm}"  | fm_get version)"
    [[ "${valid_kinds}" == *" ${fm_kind} "* ]] && ok "kind ${fm_kind}" \
      || err "kind '${fm_kind}' not in {template,example,example-*}"
    semver_ok "${fm_ver}" && ok "version ${fm_ver}" || err "version '${fm_ver}' not SemVer"
  done
}

validate_cross_bundle() {
  echo; echo "═══ cross-bundle invariants ═══"
  if [[ -n "${GLOBAL_VERSION}" && -n "${GLOBAL_SHA}" ]]; then
    ok "root manifest.yaml: version=${GLOBAL_VERSION}, lg5-spring-sha=${GLOBAL_SHA}"
  else
    err "root manifest.yaml missing version or lg5-spring-sha"
  fi
}

# Run scripts/install.sh against a disposable temp consumer fixture and
# assert that no bundle housekeeping file leaks into the .opencode/ tree
# that OpenCode discovers. Regression test for issue #15.
validate_install_output() {
  echo; echo "═══ install output (--install) ═══"

  local installer="${ROOT}/scripts/install.sh"
  [[ -x "${installer}" ]] || { err "scripts/install.sh missing or not executable"; return; }

  # Disposable fake consumer: a temp dir with a fake .git marker and the
  # bundle linked at .agent-os/ (so install.sh runs in 'consumer' mode,
  # which is the layout downstream services use in practice).
  local fixture; fixture="$(mktemp -d -t lg5-agent-os-install-XXXXXX)"
  # shellcheck disable=SC2064
  trap "rm -rf '${fixture}'" RETURN

  mkdir -p "${fixture}/.git"
  ln -s "${ROOT}" "${fixture}/.agent-os"

  if ! "${fixture}/.agent-os/scripts/install.sh" >/dev/null 2>&1; then
    err "install.sh failed against fixture ${fixture}"
    return
  fi
  ok "install.sh ran against fixture (consumer mode)"

  local opencode="${fixture}/.opencode"
  for sub in agents commands skills; do
    local target="${opencode}/${sub}"
    if [[ ! -d "${target}" ]]; then
      err ".opencode/${sub} is not a real directory (got: $(file -b "${target}" 2>/dev/null || echo missing))"
      continue
    fi
    ok ".opencode/${sub}/ is a real directory"

    # Forbidden files at the top level of each artifact dir.
    for skip in "${META_SKIP[@]}"; do
      if [[ -e "${target}/${skip}" || -L "${target}/${skip}" ]]; then
        err ".opencode/${sub}/${skip} leaked (regression of #15)"
      fi
    done

    # Sanity: every .md at the top level must have YAML frontmatter
    # (skips skills/ because skills are directories, not .md files).
    if [[ "${sub}" == "agents" || "${sub}" == "commands" ]]; then
      local bad=0
      while IFS= read -r -d '' md; do
        local first; first="$(head -n1 "${md}")"
        if [[ "${first}" != "---" ]]; then
          err "$(basename "${md}") in .opencode/${sub}/ has no YAML frontmatter"
          bad=1
        fi
      done < <(find "${target}" -mindepth 1 -maxdepth 1 -type l -name '*.md' -print0)
      [[ ${bad} -eq 0 ]] && ok "all .md under .opencode/${sub}/ have frontmatter"
    fi
  done

  # Confirm at least one real entry per artifact dir (catches an install
  # that silently produced empty trees).
  for sub in agents commands skills; do
    local n; n="$(find "${opencode}/${sub}" -mindepth 1 -maxdepth 1 | wc -l | tr -d ' ')"
    if [[ "${n}" -lt 1 ]]; then
      err ".opencode/${sub}/ is empty"
    else
      ok ".opencode/${sub}/ has ${n} real entries"
    fi
  done
}

# ─────────────────────────────────────────────────────────────────────────────
# Main
# ─────────────────────────────────────────────────────────────────────────────

echo "Validating bundle at ${ROOT}"

[[ -d "${ROOT}/skills"    ]] && validate_skills
[[ -d "${ROOT}/rules"     ]] && validate_rules
[[ -d "${ROOT}/commands"  ]] && validate_commands
[[ -d "${ROOT}/subagents" ]] && validate_subagents
[[ -d "${ROOT}/specs"     ]] && validate_specs

validate_cross_bundle

if [[ ${run_install_check} -eq 1 ]]; then
  validate_install_output
fi

echo
if [[ ${fail} -eq 0 ]]; then
  green "All checks passed."
else
  red "Validation FAILED."
fi
exit "${fail}"
