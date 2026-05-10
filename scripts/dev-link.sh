#!/usr/bin/env bash
# dev-link.sh — self-host this bundle for OpenCode in the upstream working tree.
#
# OpenCode reads agent context from `.opencode/{skills,commands,agents}/` and
# `.opencode/AGENTS.md`. This bundle stores its source of truth at the repo
# root in `skills/`, `commands/`, `subagents/` and `AGENTS.md`. While
# developing the bundle itself, we want OpenCode (running from this repo's
# root) to see the same artifacts a consumer would see — without copying.
#
# This script materializes `.opencode/` as a set of relative symlinks pointing
# back at the source directories. It is idempotent: re-running replaces stale
# links. It is dev-only: `.opencode/` is gitignored.
#
# Mapping:
#   .opencode/skills    -> ../skills
#   .opencode/commands  -> ../commands
#   .opencode/agents    -> ../subagents     (OpenCode calls them "agents")
#   .opencode/AGENTS.md -> ../AGENTS.md
#
# NOT linked:
#   - rules/  : OpenCode does not read a rules directory; rule content is
#     surfaced through AGENTS.md and the per-skill SKILL.md files.
#   - specs/  : SDD scaffolding consumed by humans + commands at planning
#     time, not loaded by OpenCode at runtime.
#
# Usage:
#   ./scripts/dev-link.sh           # create or refresh symlinks
#   ./scripts/dev-link.sh --clean   # remove .opencode/ entirely
#
# Exit codes:
#   0 — success
#   1 — error (missing source dir, not running from repo root, etc.)
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TARGET="${ROOT}/.opencode"

red()    { printf "\033[31m%s\033[0m\n" "$*"; }
green()  { printf "\033[32m%s\033[0m\n" "$*"; }
yellow() { printf "\033[33m%s\033[0m\n" "$*"; }

if [[ "${1:-}" == "--clean" ]]; then
  if [[ -e "${TARGET}" || -L "${TARGET}" ]]; then
    rm -rf "${TARGET}"
    green "Removed ${TARGET}"
  else
    yellow "${TARGET} does not exist — nothing to clean"
  fi
  exit 0
fi

# Sanity: required source artifacts must exist.
required_files=(
  "${ROOT}/skills"
  "${ROOT}/commands"
  "${ROOT}/subagents"
  "${ROOT}/AGENTS.md"
)
for src in "${required_files[@]}"; do
  if [[ ! -e "${src}" ]]; then
    red "ERROR: missing source artifact ${src}"
    red "       run from a complete clone of lg5-spring-agent-os"
    exit 1
  fi
done

mkdir -p "${TARGET}"

# Mapping table: link-name → source-path-relative-to-target
# (target is .opencode/, so `../X` references repo-root X)
declare -a links=(
  "skills:../skills"
  "commands:../commands"
  "agents:../subagents"
  "AGENTS.md:../AGENTS.md"
)

echo "Linking .opencode/ → repo-root artifacts (lg5-spring-agent-os)"
for entry in "${links[@]}"; do
  name="${entry%%:*}"
  src="${entry#*:}"
  link="${TARGET}/${name}"

  # Replace any pre-existing entry (file, dir, symlink) at the link path.
  if [[ -e "${link}" || -L "${link}" ]]; then
    rm -rf "${link}"
  fi

  ln -s "${src}" "${link}"
  green "  ✓ .opencode/${name} → ${src}"
done

echo
echo "Done. OpenCode running from ${ROOT} will now see:"
echo "  • skills via .opencode/skills/"
echo "  • commands via .opencode/commands/"
echo "  • subagents via .opencode/agents/  (OpenCode's naming)"
echo "  • bundle AGENTS.md via .opencode/AGENTS.md"
echo
echo "Note: .opencode/ is gitignored — re-run this script after fresh clone."
