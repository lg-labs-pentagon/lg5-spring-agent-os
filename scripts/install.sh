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
#   ├── skills/                      <- dir of per-skill symlinks (filters CHANGELOG.md, manifest.yaml)
#   │   ├── lg5-saga    -> ../../.agent-os/skills/lg5-saga
#   │   └── ...
#   ├── commands/                    <- dir of per-command symlinks (filters CHANGELOG.md, manifest.yaml)
#   │   ├── sdd-plan.md -> ../../.agent-os/commands/sdd-plan.md
#   │   └── ...
#   ├── agents/                      <- dir of per-subagent symlinks (filters CHANGELOG.md, manifest.yaml)
#   │   ├── sdd-planner.md -> ../../.agent-os/subagents/sdd-planner.md
#   │   └── ...
#   └── AGENTS.md -> ../.agent-os/AGENTS.md
#
# Why per-file symlinks instead of one big folder symlink?
#   OpenCode discovers agents/commands/skills by listing the matching directory
#   and treating every entry as a definition. If we symlinked the whole
#   `subagents/` folder, the bundle's housekeeping files (`CHANGELOG.md`,
#   `manifest.yaml`) would surface as bogus "agents" in the @-mention menu (the
#   `CHANGELOG.md` one is particularly confusing because it lacks frontmatter
#   yet still shows up). Per-file symlinks let us filter at install time.
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

# Read bundle version from skills/manifest.yaml.
manifest="${bundle_root}/skills/manifest.yaml"
[[ -f "${manifest}" ]] || err "${manifest} not found"
bundle_version="$(awk '
  /^bundle:/        { in_bundle=1; next }
  in_bundle && /^[a-zA-Z]/ { in_bundle=0 }
  in_bundle && /^[[:space:]]+version:/ {
    sub(/^[[:space:]]+version:[[:space:]]*/, ""); print; exit
  }
' "${manifest}")"
[[ -n "${bundle_version}" ]] || err "could not parse bundle version from ${manifest}"

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
# Plan: artifact folders to wire as per-file symlink trees, plus
#       top-level file symlinks (AGENTS.md).
#
# For each (consumer_dirname : bundle_subdir) entry we create a directory under
# .opencode/ and populate it with one symlink per real entry in the bundle
# subdir, SKIPPING the housekeeping files `CHANGELOG.md` and `manifest.yaml`
# (and any future meta-file matching ${meta_skip}). This avoids leaking those
# files into OpenCode's agent/command/skill discovery loops.
# ─────────────────────────────────────────────────────────────────────────────
declare -a artifact_dirs=(
  "skills:skills"
  "commands:commands"
  "agents:subagents"
)

declare -a file_links=(
  "AGENTS.md:${link_prefix}/AGENTS.md"
)

# Glob patterns (one per line) of bundle entries that must NOT be symlinked
# into .opencode/. Bash extended globs would work too but plain shell case
# patterns keep us POSIX-leaning and portable to macOS's stock bash 3.2.
meta_skip='CHANGELOG.md
manifest.yaml
.DS_Store'

is_meta() {
  local name="$1"
  while IFS= read -r pat; do
    [[ -z "${pat}" ]] && continue
    [[ "${name}" == "${pat}" ]] && return 0
  done <<< "${meta_skip}"
  return 1
}

# ─────────────────────────────────────────────────────────────────────────────
# --dry-run
# ─────────────────────────────────────────────────────────────────────────────
if [[ "${mode}" == "dry-run" ]]; then
  blue "Would install lg5-spring-agent-os@${bundle_version} (mode: ${install_mode}) into ${consumer_root}"
  echo "  Per-artifact symlink trees under ${opencode_dir}:"
  for entry in "${artifact_dirs[@]}"; do
    consumer_name="${entry%%:*}"
    bundle_subdir="${entry#*:}"
    src_dir="${bundle_root}/${bundle_subdir}"
    if [[ ! -d "${src_dir}" ]]; then
      yellow "    .opencode/${consumer_name}/   (skipped — ${src_dir} missing)"
      continue
    fi
    echo "    .opencode/${consumer_name}/"
    for src_entry in "${src_dir}"/*; do
      [[ -e "${src_entry}" ]] || continue
      base="$(basename "${src_entry}")"
      if is_meta "${base}"; then
        echo "      · skip ${base} (meta-file)"
      else
        echo "      ✓ ${base} -> ${link_prefix}/${bundle_subdir}/${base}"
      fi
    done
  done
  echo "  Top-level symlinks under ${opencode_dir}:"
  for entry in "${file_links[@]}"; do
    name="${entry%%:*}"; src="${entry#*:}"
    echo "    .opencode/${name} -> ${src}"
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

# 1) Per-artifact symlink trees (skills/, commands/, agents/).
for entry in "${artifact_dirs[@]}"; do
  consumer_name="${entry%%:*}"
  bundle_subdir="${entry#*:}"
  src_dir="${bundle_root}/${bundle_subdir}"
  target_dir="${opencode_dir}/${consumer_name}"

  if [[ ! -d "${src_dir}" ]]; then
    yellow "  · skipping .opencode/${consumer_name}/ — ${src_dir} missing"
    continue
  fi

  # Replace any pre-existing entry at the target path with a fresh dir. This
  # handles upgrades from older bundle versions that used a single folder
  # symlink (e.g., .opencode/agents -> ../.agent-os/subagents).
  if [[ -e "${target_dir}" || -L "${target_dir}" ]]; then
    rm -rf "${target_dir}"
  fi
  mkdir -p "${target_dir}"

  skipped=0
  linked=0
  for src_entry in "${src_dir}"/*; do
    [[ -e "${src_entry}" ]] || continue
    base="$(basename "${src_entry}")"
    if is_meta "${base}"; then
      skipped=$((skipped + 1))
      continue
    fi
    # Symlink target is relative to the parent of the link itself
    # (${opencode_dir}/${consumer_name}/), so we need an extra `../`.
    ln -s "../${link_prefix}/${bundle_subdir}/${base}" "${target_dir}/${base}"
    linked=$((linked + 1))
  done
  green "  ✓ .opencode/${consumer_name}/ (${linked} linked, ${skipped} meta-files filtered)"
done

# 2) Top-level file symlinks (AGENTS.md).
for entry in "${file_links[@]}"; do
  name="${entry%%:*}"
  src="${entry#*:}"
  link="${opencode_dir}/${name}"

  if [[ -e "${link}" || -L "${link}" ]]; then
    rm -rf "${link}"
  fi

  ln -s "${src}" "${link}"
  green "  ✓ .opencode/${name} -> ${src}"
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
  echo "  • skills via .opencode/skills/*    -> .agent-os/skills/*"
  echo "  • commands via .opencode/commands/* -> .agent-os/commands/*"
  echo "  • subagents via .opencode/agents/*  -> .agent-os/subagents/*"
  echo "  • bundle rules via .opencode/AGENTS.md -> .agent-os/AGENTS.md"
  echo
  echo "Housekeeping files (CHANGELOG.md, manifest.yaml) inside each artifact"
  echo "directory are filtered out of the symlink tree by design."
  echo
  echo "Per-repo overrides go in ${consumer_root}/AGENTS.md (root). Both files"
  echo "are read by OpenCode; the consumer one takes precedence."
else
  echo "Self-host mode: OpenCode running from ${consumer_root} (the upstream"
  echo "working tree) will now load skills/commands/subagents/AGENTS.md from"
  echo "the repo root via the .opencode/ symlinks. .opencode/ is gitignored."
fi
