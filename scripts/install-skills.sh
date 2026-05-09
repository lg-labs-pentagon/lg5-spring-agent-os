#!/usr/bin/env bash
# install-skills.sh — install the lg5-spring-skills bundle into a consumer repo.
#
# Usage (run from a clone or submodule of lg5-spring-skills):
#   ./scripts/install-skills.sh <target-dir>
#
# Example:
#   .lg5-skills/scripts/install-skills.sh .opencode/skills
#
# What it does:
#   - Copies all `skills/*/` directories, manifest.yaml, and CHANGELOG.md into
#     <target-dir>.
#   - Writes <target-dir>/.bundle-version with the current bundle version (read
#     from skills/manifest.yaml).
#   - Refuses to overwrite an existing <target-dir> with a DIFFERENT bundle
#     version unless --force is passed (prevents accidental downgrade/upgrade).
#   - Does NOT touch AGENTS.md — the consumer repo owns that file and merges
#     the upstream rules manually (otherwise per-repo customizations would be
#     wiped on every upgrade).
set -euo pipefail

force=0
if [[ "${1:-}" == "--force" ]]; then
  force=1
  shift
fi

target="${1:-}"
if [[ -z "${target}" ]]; then
  echo "Usage: $0 [--force] <target-dir>" >&2
  exit 2
fi

src_root="$(cd "$(dirname "$0")/.." && pwd)"
src_skills="${src_root}/skills"

if [[ ! -d "${src_skills}" ]]; then
  echo "ERROR: skills/ not found at ${src_skills}" >&2
  exit 1
fi

# Read bundle version from manifest.yaml (line `  version: X.Y.Z` under `bundle:`)
bundle_version="$(awk '
  /^bundle:/        { in_bundle=1; next }
  in_bundle && /^[a-zA-Z]/ { in_bundle=0 }
  in_bundle && /^[[:space:]]+version:/ {
    sub(/^[[:space:]]+version:[[:space:]]*/, ""); print; exit
  }
' "${src_skills}/manifest.yaml")"

if [[ -z "${bundle_version}" ]]; then
  echo "ERROR: could not parse bundle version from manifest.yaml" >&2
  exit 1
fi

echo "Installing lg5-spring-skills@${bundle_version} into ${target}"

if [[ -d "${target}" && -f "${target}/.bundle-version" ]]; then
  current="$(cat "${target}/.bundle-version")"
  if [[ "${current}" != "${bundle_version}" && ${force} -eq 0 ]]; then
    echo "ERROR: ${target} already has bundle version ${current}." >&2
    echo "       Re-run with --force to overwrite with ${bundle_version}." >&2
    exit 1
  fi
fi

mkdir -p "${target}"

# Copy skill directories + top-level metadata files
for entry in "${src_skills}"/*; do
  name="$(basename "${entry}")"
  case "${name}" in
    .*) continue ;;          # skip hidden
  esac
  rm -rf "${target:?}/${name}"
  cp -R "${entry}" "${target}/"
done

echo "${bundle_version}" > "${target}/.bundle-version"

echo "Done. Installed bundle version ${bundle_version}."
echo "Review ${target}/CHANGELOG.md for what's new."
echo
echo "NOTE: AGENTS.md was not touched. Manually merge upstream rules from"
echo "      ${src_root}/AGENTS.md into your consumer repo's AGENTS.md."
