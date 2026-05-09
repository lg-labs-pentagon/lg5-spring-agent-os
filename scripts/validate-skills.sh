#!/usr/bin/env bash
# validate-skills.sh — sanity checks for the .opencode/skills/ knowledge base.
#
# Runs locally and in CI. Validates:
#   1. Every skill directory contains SKILL.md and CHANGELOG.md.
#   2. Each SKILL.md has a YAML frontmatter with: name, version, lg5-spring-sha, description.
#   3. The frontmatter `name` matches the directory name.
#   4. All skills declare the SAME `lg5-spring-sha` (consistent bundle).
#   5. manifest.yaml exists and lists every skill present on disk.
#   6. No SKILL.md references absolute /tmp/ paths in code blocks (anti-pattern:
#      those refer to the framework checkout that must NOT be committed).
#      Note: prose mentions of /tmp/lg5-study/ are allowed; only fenced ```...```
#      code blocks are forbidden from referencing /tmp/.
#
# Exit codes:
#   0 — all checks passed
#   1 — one or more checks failed
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SKILLS_DIR="${ROOT}/skills"
fail=0

red()    { printf "\033[31m%s\033[0m\n" "$*"; }
green()  { printf "\033[32m%s\033[0m\n" "$*"; }
yellow() { printf "\033[33m%s\033[0m\n" "$*"; }

err() { red "  ✗ $*"; fail=1; }
ok()  { green "  ✓ $*"; }

if [[ ! -d "${SKILLS_DIR}" ]]; then
  red "skills directory not found: ${SKILLS_DIR}"
  exit 1
fi

echo "Validating skills in ${SKILLS_DIR}"

# Collect skill directories (exclude files at top level)
mapfile -t skill_dirs < <(find "${SKILLS_DIR}" -mindepth 1 -maxdepth 1 -type d | sort)

if [[ ${#skill_dirs[@]} -eq 0 ]]; then
  red "no skill directories found"
  exit 1
fi

declare -A shas_seen=()

for dir in "${skill_dirs[@]}"; do
  skill_name="$(basename "${dir}")"
  echo
  echo "→ ${skill_name}"

  skill_md="${dir}/SKILL.md"
  changelog="${dir}/CHANGELOG.md"

  if [[ ! -f "${skill_md}" ]]; then
    err "missing SKILL.md"
    continue
  fi
  ok "SKILL.md present"

  if [[ ! -f "${changelog}" ]]; then
    err "missing CHANGELOG.md"
  else
    ok "CHANGELOG.md present"
  fi

  # Extract frontmatter (between first two --- lines)
  fm="$(awk '/^---$/{c++; next} c==1{print} c==2{exit}' "${skill_md}")"
  if [[ -z "${fm}" ]]; then
    err "no YAML frontmatter found"
    continue
  fi

  for key in name version lg5-spring-sha description; do
    if ! grep -qE "^${key}:" <<<"${fm}"; then
      err "frontmatter missing '${key}'"
    fi
  done

  fm_name="$(grep -E '^name:' <<<"${fm}" | head -n1 | sed -E 's/^name:[[:space:]]*//;s/[[:space:]]+$//')"
  fm_version="$(grep -E '^version:' <<<"${fm}" | head -n1 | sed -E 's/^version:[[:space:]]*//;s/[[:space:]]+$//')"
  fm_sha="$(grep -E '^lg5-spring-sha:' <<<"${fm}" | head -n1 | sed -E 's/^lg5-spring-sha:[[:space:]]*//;s/[[:space:]]+$//')"

  if [[ "${fm_name}" != "${skill_name}" ]]; then
    err "frontmatter name '${fm_name}' != directory '${skill_name}'"
  else
    ok "name matches directory"
  fi

  if [[ ! "${fm_version}" =~ ^[0-9]+\.[0-9]+\.[0-9]+(-[A-Za-z0-9.-]+)?$ ]]; then
    err "version '${fm_version}' is not SemVer"
  else
    ok "version ${fm_version}"
  fi

  if [[ -z "${fm_sha}" ]]; then
    err "lg5-spring-sha is empty"
  else
    ok "lg5-spring-sha ${fm_sha}"
    shas_seen["${fm_sha}"]=1
  fi

  # Check for forbidden /tmp/ references inside fenced code blocks.
  # The convention is that /tmp/lg5-study/ IS allowed (it's the documented
  # location for the lg5-spring framework checkout used as a reference).
  # Any OTHER /tmp/ path inside a code block is forbidden — those would be
  # local-only paths that don't belong in versioned knowledge.
  if awk '
    /^```/ { inblock = !inblock; next }
    inblock && /\/tmp\// && !/\/tmp\/lg5-study(\/|[[:space:]]|$)/ { found=1; print NR": "$0 }
    END { exit found ? 1 : 0 }
  ' "${skill_md}" >/tmp/skill-tmp-refs.$$ 2>/dev/null; then
    ok "no forbidden /tmp/ references inside code blocks"
  else
    err "found forbidden /tmp/ references inside code blocks (only /tmp/lg5-study/ is allowed):"
    sed 's/^/      /' /tmp/skill-tmp-refs.$$
  fi
  rm -f /tmp/skill-tmp-refs.$$
done

echo
echo "→ bundle consistency"

if [[ ${#shas_seen[@]} -eq 0 ]]; then
  err "no lg5-spring-sha found anywhere"
elif [[ ${#shas_seen[@]} -gt 1 ]]; then
  err "skills declare DIFFERENT lg5-spring-sha values:"
  for s in "${!shas_seen[@]}"; do printf "      %s\n" "${s}"; done
else
  for s in "${!shas_seen[@]}"; do ok "all skills validated against ${s}"; done
fi

manifest="${SKILLS_DIR}/manifest.yaml"
if [[ ! -f "${manifest}" ]]; then
  err "manifest.yaml missing at ${manifest}"
else
  ok "manifest.yaml present"
  for dir in "${skill_dirs[@]}"; do
    skill_name="$(basename "${dir}")"
    if ! grep -qE "^[[:space:]]*-[[:space:]]*name:[[:space:]]*${skill_name}\b" "${manifest}"; then
      err "manifest.yaml does not list skill '${skill_name}'"
    fi
  done
fi

echo
if [[ ${fail} -eq 0 ]]; then
  green "All skill checks passed."
else
  red "Skill validation FAILED."
fi
exit "${fail}"
