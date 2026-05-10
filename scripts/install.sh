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
#   ├── skills    -> ../.agent-os/skills
#   ├── commands  -> ../.agent-os/commands
#   ├── agents    -> ../.agent-os/subagents      (OpenCode's naming)
#   └── AGENTS.md -> ../.agent-os/AGENTS.md
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
# Plan: link table (link-name : target relative to .opencode/)
# ─────────────────────────────────────────────────────────────────────────────
declare -a links=(
  "skills:${link_prefix}/skills"
  "commands:${link_prefix}/commands"
  "agents:${link_prefix}/subagents"
  "AGENTS.md:${link_prefix}/AGENTS.md"
)

# ─────────────────────────────────────────────────────────────────────────────
# --dry-run
# ─────────────────────────────────────────────────────────────────────────────
if [[ "${mode}" == "dry-run" ]]; then
  blue "Would install lg5-spring-agent-os@${bundle_version} (mode: ${install_mode}) into ${consumer_root}"
  echo "  Symlinks to create under ${opencode_dir}:"
  for entry in "${links[@]}"; do
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

for entry in "${links[@]}"; do
  name="${entry%%:*}"
  src="${entry#*:}"
  link="${opencode_dir}/${name}"

  # Replace any pre-existing entry (file, dir, symlink) at the link path.
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
