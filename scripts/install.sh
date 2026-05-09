#!/usr/bin/env bash
# install.sh — install the lg5-spring-agent-os bundle into a consumer repo.
#
# Usage (run from a clone or submodule of lg5-spring-agent-os):
#   ./scripts/install.sh <target-dir>
#
# Example:
#   .lg5-agent-os/scripts/install.sh .opencode
#
# What it does:
#   - Copies every present artifact directory (skills/, rules/, commands/,
#     subagents/, specs/, hooks/) into <target-dir>/<artifact-type>/.
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

# Read bundle version from skills/manifest.yaml (line `  version: X.Y.Z` under `bundle:`)
manifest="${src_root}/skills/manifest.yaml"
if [[ ! -f "${manifest}" ]]; then
  echo "ERROR: ${manifest} not found" >&2
  exit 1
fi

bundle_version="$(awk '
  /^bundle:/        { in_bundle=1; next }
  in_bundle && /^[a-zA-Z]/ { in_bundle=0 }
  in_bundle && /^[[:space:]]+version:/ {
    sub(/^[[:space:]]+version:[[:space:]]*/, ""); print; exit
  }
' "${manifest}")"

if [[ -z "${bundle_version}" ]]; then
  echo "ERROR: could not parse bundle version from ${manifest}" >&2
  exit 1
fi

echo "Installing lg5-spring-agent-os@${bundle_version} into ${target}"

if [[ -d "${target}" && -f "${target}/.bundle-version" ]]; then
  current="$(cat "${target}/.bundle-version")"
  if [[ "${current}" != "${bundle_version}" && ${force} -eq 0 ]]; then
    echo "ERROR: ${target} already has bundle version ${current}." >&2
    echo "       Re-run with --force to overwrite with ${bundle_version}." >&2
    exit 1
  fi
fi

mkdir -p "${target}"

# Known artifact types — copy each one if it exists in the source tree.
artifact_types=(skills rules commands subagents specs hooks)

installed_count=0
for type in "${artifact_types[@]}"; do
  src="${src_root}/${type}"
  if [[ -d "${src}" ]]; then
    rm -rf "${target:?}/${type}"
    cp -R "${src}" "${target}/"
    echo "  ✓ installed ${type}/"
    installed_count=$((installed_count + 1))
  fi
done

if [[ ${installed_count} -eq 0 ]]; then
  echo "ERROR: no artifact directories found in ${src_root}" >&2
  exit 1
fi

echo "${bundle_version}" > "${target}/.bundle-version"

echo
echo "Done. Installed bundle version ${bundle_version} (${installed_count} artifact type(s))."
echo "Review ${target}/skills/CHANGELOG.md (and others, when present) for what's new."
echo
echo "NOTE: AGENTS.md was not touched. Manually merge upstream rules from"
echo "      ${src_root}/AGENTS.md into your consumer repo's AGENTS.md."
