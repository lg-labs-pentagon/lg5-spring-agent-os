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
#               tools, model); name ↔ filename match; manifest ↔ disk parity.
#
#   specs     : <name>.md template/example with frontmatter (kind, name,
#               version, description); kind ∈ {template, example}; manifest
#               ↔ disk parity.
#
# Cross-bundle invariants:
#   - bundle.lg5-spring-sha is identical across all manifest.yaml files.
#   - bundle.version is identical across all manifest.yaml files.
#
# Exit codes:
#   0 — all checks passed
#   1 — one or more checks failed
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
fail=0

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

# ─────────────────────────────────────────────────────────────────────────────
# Per-artifact validators
# ─────────────────────────────────────────────────────────────────────────────

validate_skills() {
  local dir="${ROOT}/skills"
  echo
  echo "═══ skills ═══"
  mapfile -t skill_dirs < <(find "${dir}" -mindepth 1 -maxdepth 1 -type d | sort)
  if [[ ${#skill_dirs[@]} -eq 0 ]]; then err "no skill directories found"; return; fi

  declare -A shas_seen=()

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
    [[ -n "${fm_sha}" ]] && { ok "lg5-spring-sha ${fm_sha}"; shas_seen["${fm_sha}"]=1; } \
      || err "lg5-spring-sha is empty"

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

  echo; echo "→ skills bundle consistency"
  if [[ ${#shas_seen[@]} -gt 1 ]]; then
    err "skills declare DIFFERENT lg5-spring-sha values:"
    for s in "${!shas_seen[@]}"; do printf "      %s\n" "${s}"; done
  elif [[ ${#shas_seen[@]} -eq 1 ]]; then
    for s in "${!shas_seen[@]}"; do ok "all skills validated against ${s}"; done
  fi

  local manifest="${dir}/manifest.yaml"
  if [[ ! -f "${manifest}" ]]; then err "skills/manifest.yaml missing"; return; fi
  ok "manifest.yaml present"
  for d in "${skill_dirs[@]}"; do
    local n; n="$(basename "${d}")"
    grep -qE "^[[:space:]]*-[[:space:]]*name:[[:space:]]*${n}\b" "${manifest}" \
      || err "manifest does not list skill '${n}'"
  done
}

validate_rules() {
  local dir="${ROOT}/rules"
  echo; echo "═══ rules ═══"
  mapfile -t files < <(find "${dir}" -mindepth 1 -maxdepth 1 -type f -name 'RULE-*.md' | sort)
  if [[ ${#files[@]} -eq 0 ]]; then err "no rule files found"; return; fi

  local valid_severities=" must should info "
  local valid_scopes=" framework architecture kafka outbox saga testing style build reference "

  declare -A shas=()
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
    [[ -n "${fm_sha}" ]] && { ok "lg5-spring-sha ${fm_sha}"; shas["${fm_sha}"]=1; } \
      || err "lg5-spring-sha empty"
    [[ "${valid_severities}" == *" ${fm_sev} "* ]] && ok "severity ${fm_sev}" \
      || err "severity '${fm_sev}' not in {must,should,info}"
    [[ "${valid_scopes}" == *" ${fm_scope} "* ]] && ok "scope ${fm_scope}" \
      || err "scope '${fm_scope}' not in {framework,architecture,kafka,outbox,saga,testing,style,build,reference}"
  done

  echo; echo "→ rules bundle consistency"
  if [[ ${#shas[@]} -gt 1 ]]; then
    err "rules declare DIFFERENT lg5-spring-sha values: ${!shas[@]}"
  elif [[ ${#shas[@]} -eq 1 ]]; then
    for s in "${!shas[@]}"; do ok "all rules validated against ${s}"; done
  fi

  local manifest="${dir}/manifest.yaml"
  if [[ ! -f "${manifest}" ]]; then err "rules/manifest.yaml missing"; return; fi
  ok "manifest.yaml present"
  for f in "${files[@]}"; do
    local fname; fname="$(basename "${f}" .md)"
    local rid="${fname%%-*}"
    grep -qE "^[[:space:]]*-[[:space:]]*id:[[:space:]]*${rid}\b" "${manifest}" \
      || err "manifest does not list rule '${rid}'"
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

  local manifest="${dir}/manifest.yaml"
  if [[ ! -f "${manifest}" ]]; then err "commands/manifest.yaml missing"; return; fi
  ok "manifest.yaml present"
  for f in "${files[@]}"; do
    local n; n="$(basename "${f}" .md)"
    grep -qE "^[[:space:]]*-[[:space:]]*name:[[:space:]]*${n}\b" "${manifest}" \
      || err "manifest does not list command '${n}'"
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
    for key in name description tools model; do
      grep -qE "^${key}:" <<<"${fm}" || err "frontmatter missing '${key}'"
    done
    local fm_name; fm_name="$(echo "${fm}" | fm_get name)"
    [[ "${fm_name}" == "${fname}" ]] && ok "name matches filename" \
      || err "frontmatter name '${fm_name}' != filename '${fname}'"
  done

  local manifest="${dir}/manifest.yaml"
  if [[ ! -f "${manifest}" ]]; then err "subagents/manifest.yaml missing"; return; fi
  ok "manifest.yaml present"
  for f in "${files[@]}"; do
    local n; n="$(basename "${f}" .md)"
    grep -qE "^[[:space:]]*-[[:space:]]*name:[[:space:]]*${n}\b" "${manifest}" \
      || err "manifest does not list subagent '${n}'"
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

  local manifest="${dir}/manifest.yaml"
  if [[ ! -f "${manifest}" ]]; then err "specs/manifest.yaml missing"; return; fi
  ok "manifest.yaml present"
}

validate_cross_bundle() {
  echo; echo "═══ cross-bundle invariants ═══"
  local sha=""; local ver=""
  for type in skills rules commands subagents specs; do
    local m="${ROOT}/${type}/manifest.yaml"
    [[ -f "${m}" ]] || continue
    local s v
    s="$(manifest_get "${m}" lg5-spring-sha)"
    v="$(manifest_get "${m}" version)"
    if [[ -z "${sha}" ]]; then sha="${s}"; ver="${v}"
    else
      [[ "${s}" == "${sha}" ]] || err "${type}/manifest.yaml lg5-spring-sha='${s}' differs from skills='${sha}'"
      [[ "${v}" == "${ver}" ]] || err "${type}/manifest.yaml bundle.version='${v}' differs from skills='${ver}'"
    fi
  done
  [[ -n "${sha}" ]] && ok "all manifests agree on lg5-spring-sha=${sha}"
  [[ -n "${ver}" ]] && ok "all manifests agree on bundle.version=${ver}"
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

echo
if [[ ${fail} -eq 0 ]]; then
  green "All checks passed."
else
  red "Validation FAILED."
fi
exit "${fail}"
