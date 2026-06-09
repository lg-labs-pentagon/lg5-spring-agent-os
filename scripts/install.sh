#!/usr/bin/env bash
# install.sh — wire a consumer repo to use lg5-spring-agent-os.
#
# Model (v1.0.0+):
#   The bundle is consumed as a git submodule mounted at .agent-os/. Artifacts
#   are NOT copied — the submodule itself IS the source of truth. OpenCode
#   reads agent context from .opencode/{skills,commands,agents}/ and
#   .opencode/AGENTS.md, so this script materializes that .opencode/ tree as
#   relative symlinks pointing back into .agent-os/.
#
#   .gitmodules + .agent-os (gitlink at a SHA) are committed.
#   .opencode/ is gitignored — re-create it after fresh clone with this script.
#
# Resulting layout in the consumer:
#
#   .agent-os/                       <- git submodule (HEAD-detached at vX.Y.Z)
#   ├── skills/
#   ├── commands/
#   ├── subagents/
#   ├── rules/
#   ├── specs/
#   ├── AGENTS.md
#   └── scripts/install.sh           <- this script
#
#   .opencode/                       <- generated, gitignored
#   ├── skills/                      <- real dir; one symlink per skill subdir
#   │   ├── lg5-saga      -> ../../.agent-os/skills/lg5-saga
#   │   └── …
#   ├── commands/                    <- real dir; one symlink per .md
#   │   ├── sdd-plan.md   -> ../../.agent-os/commands/sdd-plan.md
#   │   └── …
#   ├── agents/                      <- real dir; one symlink per .md (OpenCode's naming)
#   │   ├── sdd-planner.md -> ../../.agent-os/subagents/sdd-planner.md
#   │   └── …
#   └── AGENTS.md -> ../.agent-os/AGENTS.md
#
#   Bundle housekeeping files (`CHANGELOG.md`, `manifest.yaml`, `.DS_Store`) are
#   filtered out — see `meta_skip` below — so OpenCode does not discover them
#   as phantom agents/commands/skills (issue #15).
#
# Usage:
#
#   Consumer install (most common):
#     # 1. Add submodule from your service repo root
#     git submodule add -b main git@github.com:lg-labs-pentagon/lg5-spring-agent-os.git .agent-os
#     git -C .agent-os checkout vX.Y.Z
#     # 2. Wire OpenCode + .gitignore
#     .agent-os/scripts/install.sh
#
#   Upstream self-host (bundle authors only):
#     # From the lg5-spring-agent-os repo root
#     ./scripts/install.sh
#     # → creates .opencode/* symlinks pointing at the repo-root artifacts
#
#   Common flags:
#     --upgrade    update the submodule to the latest stable tag (vX.Y.Z)
#     --clean      remove .opencode/
#     --dry-run    show what would change without writing
#     -h | --help  print this header
#
# What it does NOT do (intentionally):
#   - Add the submodule for you. Run `git submodule add` yourself before
#     calling this script. The script verifies it's running from a submodule
#     mounted at .agent-os/ in the consumer's repo root.
#   - Touch AGENTS.md in the consumer root. The consumer owns its own
#     AGENTS.md. The bundle's AGENTS.md is exposed via .opencode/AGENTS.md
#     (symlink) so OpenCode picks it up; per-repo customizations live in
#     the consumer's root-level AGENTS.md (which OpenCode also reads).
#   - Copy files. Submodule = source of truth.
set -euo pipefail

# ─────────────────────────────────────────────────────────────────────────────
# Helpers
# ─────────────────────────────────────────────────────────────────────────────
red()    { printf "\033[31m%s\033[0m\n" "$*"; }
green()  { printf "\033[32m%s\033[0m\n" "$*"; }
yellow() { printf "\033[33m%s\033[0m\n" "$*"; }
blue()   { printf "\033[34m%s\033[0m\n" "$*"; }

err() { red "ERROR: $*" >&2; exit 1; }

# ─────────────────────────────────────────────────────────────────────────────
# Argument parsing
# ─────────────────────────────────────────────────────────────────────────────
mode="install"
for arg in "$@"; do
  case "${arg}" in
    --upgrade) mode="upgrade" ;;
    --clean)   mode="clean" ;;
    --dry-run) mode="dry-run" ;;
    -h|--help)
      sed -n '2,40p' "$0"
      exit 0
      ;;
    *) err "unknown argument: ${arg}" ;;
  esac
done

# ─────────────────────────────────────────────────────────────────────────────
# Locate paths
# ─────────────────────────────────────────────────────────────────────────────
# Two supported modes:
#
#   1) Consumer install: this script lives at <consumer>/.agent-os/scripts/install.sh
#      bundle_root   = <consumer>/.agent-os         (= submodule)
#      consumer_root = <consumer>                   (= where .opencode/ goes)
#      symlinks point at ../.agent-os/<artifact>
#
#   2) Upstream self-host: this script lives at <repo>/scripts/install.sh
#      bundle_root   = <repo>                       (= upstream working tree)
#      consumer_root = <repo>                       (same dir)
#      symlinks point at ../<artifact>
#
# We tell the two apart by checking whether bundle_root's basename is `.agent-os`.
bundle_root="$(cd "$(dirname "$0")/.." && pwd)"

if [[ "$(basename "${bundle_root}")" == ".agent-os" ]]; then
  install_mode="consumer"
  consumer_root="$(cd "${bundle_root}/.." && pwd)"
  link_prefix="../.agent-os"
else
  install_mode="self-host"
  consumer_root="${bundle_root}"
  link_prefix=".."
fi

# Sanity: consumer_root must be a git repo.
if [[ ! -d "${consumer_root}/.git" && ! -f "${consumer_root}/.git" ]]; then
  err "${consumer_root} is not a git repository"
fi

# Sanity: bundle artifacts must exist at bundle_root.
required=(skills commands subagents AGENTS.md)
for r in "${required[@]}"; do
  [[ -e "${bundle_root}/${r}" ]] || err "missing bundle artifact ${bundle_root}/${r}
       Is the submodule fully checked out? Try: git submodule update --init"
done

# ─────────────────────────────────────────────────────────────────────────────
# --upgrade (Consumer only)
# ─────────────────────────────────────────────────────────────────────────────
if [[ "${mode}" == "upgrade" ]]; then
  if [[ "${install_mode}" != "consumer" ]]; then
    err "--upgrade is only supported when running from a consumer repository (.agent-os submodule)"
  fi

  blue "Checking for the latest stable release..."
  
  # Fetch latest tags from the submodule's remote
  (cd "${bundle_root}" && git fetch --tags --quiet)
  
  # Get the latest tag matching v* (e.g., v4.5.0)
  latest_tag=$(cd "${bundle_root}" && git tag -l "v*" | sort -V | tail -n1)
  
  if [[ -z "${latest_tag}" ]]; then
    err "no stable tags (v*) found in ${bundle_root}"
  fi
  
  current_tag=$(cd "${bundle_root}" && git describe --tags --abbrev=0 2>/dev/null || echo "unknown")
  
  if [[ "${latest_tag}" == "${current_tag}" ]]; then
    green "  ✓ Already at the latest release: ${latest_tag}"
  else
    yellow "  → Upgrading from ${current_tag} to ${latest_tag}..."
    (cd "${bundle_root}" && git checkout "${latest_tag}" --quiet)
    green "  ✓ Upgraded .agent-os to ${latest_tag}"
  fi
  # Continue with the install logic to refresh symlinks
  mode="install"
fi

# Read bundle version from root manifest.yaml.
manifest="${bundle_root}/manifest.yaml"
[[ -f "${manifest}" ]] || err "${manifest} not found"
bundle_version="$(awk '
  /^bundle:/        { in_bundle=1; next }
  in_bundle && /^[a-zA-Z]/ { in_bundle=0 }
  in_bundle && /^[[:space:]]+version:/ {
    sub(/^[[:space:]]+version:[[:space:]]*/, ""); print; exit
  }
' "${manifest}")"
[[ -n "${bundle_version}" ]] || err "could not parse bundle version from ${manifest}"

# Append short SHA if not on a tagged release (dirty or ahead).
# In consumer mode, we check the .agent-os submodule.
if [[ -d "${bundle_root}/.git" || -f "${bundle_root}/.git" ]]; then
  # check if the current commit has an exact tag match
  if ! (cd "${bundle_root}" && git describe --tags --exact-match >/dev/null 2>&1); then
    short_sha=$(cd "${bundle_root}" && git rev-parse --short HEAD)
    bundle_version="${bundle_version}.${short_sha}"
  fi
fi

opencode_dir="${consumer_root}/.opencode"
gitignore="${consumer_root}/.gitignore"

# ─────────────────────────────────────────────────────────────────────────────
# --clean
# ─────────────────────────────────────────────────────────────────────────────
if [[ "${mode}" == "clean" ]]; then
  if [[ -e "${opencode_dir}" || -L "${opencode_dir}" ]]; then
    rm -rf "${opencode_dir}"
    green "Removed ${opencode_dir}"
  else
    yellow "${opencode_dir} does not exist — nothing to clean"
  fi
  exit 0
fi

# ─────────────────────────────────────────────────────────────────────────────
# Plan
# ─────────────────────────────────────────────────────────────────────────────
# Two kinds of links are produced:
#
#   1) Per-artifact directories (skills, commands, agents): created as REAL
#      directories under .opencode/, populated with one symlink per real
#      artifact entry. Bundle housekeeping files (CHANGELOG.md, manifest.yaml,
#      .DS_Store) are filtered out so OpenCode does not load them as phantom
#      agents/commands/skills (issue #15).
#
#   2) Single-file links (AGENTS.md): created directly as a file symlink.
#
# `link_prefix` already points at .agent-os (consumer) or .. (self-host).
# Per-file links live one extra level deep (under .opencode/<dir>/<entry>),
# so their target prefix needs an additional "../".
per_file_prefix="../${link_prefix}"

# Filenames inside artifact dirs that must NOT be exposed to OpenCode.
# Keep this list in sync with scripts/validate.sh (when issue #17 ships).
meta_skip=("CHANGELOG.md" "manifest.yaml" ".DS_Store")

is_meta() {
  local name="$1"
  for skip in "${meta_skip[@]}"; do
    [[ "${name}" == "${skip}" ]] && return 0
  done
  return 1
}

# Per-artifact directory plan: <opencode-dir-name>:<bundle-source-dir-name>
declare -a artifact_dirs=(
  "skills:skills"
  "commands:commands"
  "agents:subagents"
)

# Single-file link plan: <opencode-name>:<bundle-source-relative-to-bundle-root>
declare -a file_links=(
  "AGENTS.md:AGENTS.md"
)

# ─────────────────────────────────────────────────────────────────────────────
# --dry-run
# ─────────────────────────────────────────────────────────────────────────────
if [[ "${mode}" == "dry-run" ]]; then
  blue "Would install lg5-spring-agent-os@${bundle_version} (mode: ${install_mode}) into ${consumer_root}"
  echo "  Per-artifact directories under ${opencode_dir}:"
  for entry in "${artifact_dirs[@]}"; do
    name="${entry%%:*}"; src_dir="${entry#*:}"
    echo "    .opencode/${name}/   (real dir, populated from .agent-os/${src_dir}/)"
    while IFS= read -r -d '' item; do
      base="$(basename "${item}")"
      if is_meta "${base}"; then
        echo "      · skip ${base} (bundle meta)"
      else
        echo "      ✓ link ${base} -> ${per_file_prefix}/${src_dir}/${base}"
      fi
    done < <(find "${bundle_root}/${src_dir}" -mindepth 1 -maxdepth 1 -print0 | sort -z)
  done
  echo "  Single-file links under ${opencode_dir}:"
  for entry in "${file_links[@]}"; do
    name="${entry%%:*}"; src="${entry#*:}"
    echo "    .opencode/${name} -> ${link_prefix}/${src}"
  done
  if ! grep -qxF ".opencode/" "${gitignore}" 2>/dev/null; then
    echo "  Would add '.opencode/' to ${gitignore}"
  else
    echo "  ${gitignore} already ignores .opencode/"
  fi
  exit 0
fi

# ─────────────────────────────────────────────────────────────────────────────
# Install
# ─────────────────────────────────────────────────────────────────────────────
blue "Installing lg5-spring-agent-os@${bundle_version} (mode: ${install_mode}) into ${consumer_root}"

mkdir -p "${opencode_dir}"

# Per-artifact directories: replace any pre-existing entry (could be the legacy
# folder-level symlink from v4.1.0 and earlier) with a fresh real directory of
# per-entry symlinks.
for entry in "${artifact_dirs[@]}"; do
  name="${entry%%:*}"
  src_dir="${entry#*:}"
  link_dir="${opencode_dir}/${name}"

  if [[ -e "${link_dir}" || -L "${link_dir}" ]]; then
    rm -rf "${link_dir}"
  fi
  mkdir -p "${link_dir}"

  linked=0
  skipped=0
  while IFS= read -r -d '' item; do
    base="$(basename "${item}")"
    if is_meta "${base}"; then
      skipped=$((skipped + 1))
      continue
    fi
    ln -s "${per_file_prefix}/${src_dir}/${base}" "${link_dir}/${base}"
    linked=$((linked + 1))
  done < <(find "${bundle_root}/${src_dir}" -mindepth 1 -maxdepth 1 -print0 | sort -z)

  green "  ✓ .opencode/${name}/ (${linked} linked, ${skipped} meta skipped)"
done

# Single-file links.
for entry in "${file_links[@]}"; do
  name="${entry%%:*}"
  src="${entry#*:}"
  link="${opencode_dir}/${name}"

  if [[ -e "${link}" || -L "${link}" ]]; then
    rm -rf "${link}"
  fi

  ln -s "${link_prefix}/${src}" "${link}"
  green "  ✓ .opencode/${name} -> ${link_prefix}/${src}"
done

# Ensure .opencode/ is gitignored.
if [[ ! -f "${gitignore}" ]]; then
  printf ".opencode/\n" > "${gitignore}"
  green "  ✓ created ${gitignore} with .opencode/"
elif ! grep -qxF ".opencode/" "${gitignore}"; then
  # Append with a leading newline if file doesn't end with one.
  if [[ -s "${gitignore}" && -n "$(tail -c1 "${gitignore}")" ]]; then
    printf "\n" >> "${gitignore}"
  fi
  printf "\n# Generated by .agent-os/scripts/install.sh — OpenCode symlinks back into .agent-os/\n.opencode/\n" >> "${gitignore}"
  green "  ✓ added .opencode/ to ${gitignore}"
else
  yellow "  · ${gitignore} already ignores .opencode/"
fi

echo
green "Done. Bundle ${bundle_version} wired (mode: ${install_mode})."
echo

if [[ "${install_mode}" == "consumer" ]]; then
  echo "Commit the submodule pin (if you just added it):"
  echo "  git add .gitmodules .agent-os .gitignore"
  echo "  git commit -m \"chore(agent-os): pin lg5-spring-agent-os@${bundle_version}\""
  echo
  echo "OpenCode running from ${consumer_root} will now load:"
  echo "  • skills via .opencode/skills/    -> .agent-os/skills/"
  echo "  • commands via .opencode/commands/ -> .agent-os/commands/"
  echo "  • subagents via .opencode/agents/  -> .agent-os/subagents/"
  echo "  • bundle rules via .opencode/AGENTS.md -> .agent-os/AGENTS.md"
  echo
  echo "Per-repo overrides go in ${consumer_root}/AGENTS.md (root). Both files"
  echo "are read by OpenCode; the consumer one takes precedence."
else
  echo "Self-host mode: OpenCode running from ${consumer_root} (the upstream"
  echo "working tree) will now load skills/commands/subagents/AGENTS.md from"
  echo "the repo root via the .opencode/ symlinks. .opencode/ is gitignored."
fi
