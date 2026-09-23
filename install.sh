#!/usr/bin/env bash
# dev-workflow installer — macOS / Linux
#
# One-liner usage (no clone needed):
#   curl -fsSL https://raw.githubusercontent.com/andresdigiovanni/dev-workflow/main/install.sh | bash
#   curl -fsSL https://raw.githubusercontent.com/andresdigiovanni/dev-workflow/main/install.sh | bash -s -- --agents claude --scope global
#
# Downloads a tarball of this repository into a temp directory, copies the
# skills/ folders into the directories your agent reads skills from, and
# inserts the content of AGENTS.md between a pair of markers in that
# agent's own instruction file. Nothing here is ever symlinked — every
# install is a plain copy, independent of this script afterward.
#
# Usage:
#   ./install.sh [--uninstall] [--agents claude,codex,opencode]
#                [--scope global|project] [--dir PATH] [--ref REF] [--yes]
#
# Run with no flags for an interactive menu.
set -euo pipefail

# ---------------------------------------------------------------------------
# Where this ships from
# ---------------------------------------------------------------------------

REPO="${DEV_WORKFLOW_REPO:-andresdigiovanni/dev-workflow}"
REF="${DEV_WORKFLOW_REF:-main}"

MARKER_START="<!-- dev-workflow:start -->"
MARKER_END="<!-- dev-workflow:end -->"

AGENT_IDS=(claude codex opencode)
AGENT_LABELS=("Claude Code" "Codex CLI" "OpenCode")

MODE="install"
SCOPE=""
PROJECT_DIR="$(pwd)"
ASSUME_YES=0
AGENTS_ARG=""

# ---------------------------------------------------------------------------
# Output helpers
# ---------------------------------------------------------------------------

if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
  BOLD=$'\033[1m'; GREEN=$'\033[32m'; YELLOW=$'\033[33m'; RESET=$'\033[0m'
else
  BOLD=""; GREEN=""; YELLOW=""; RESET=""
fi

info()  { printf '%s\n' "$*"; }
step()  { printf '%s→%s %s\n' "$BOLD" "$RESET" "$*"; }
ok()    { printf '  %s✓%s %s\n' "$GREEN" "$RESET" "$*"; }
warn()  { printf '  %s!%s %s\n' "$YELLOW" "$RESET" "$*" >&2; }
die()   { printf 'error: %s\n' "$*" >&2; exit 1; }

# ---------------------------------------------------------------------------
# Usage
# ---------------------------------------------------------------------------

usage() {
  cat <<EOF
dev-workflow installer

Usage:
  curl -fsSL https://raw.githubusercontent.com/${REPO}/${REF}/install.sh | bash
  curl -fsSL https://raw.githubusercontent.com/${REPO}/${REF}/install.sh | bash -s -- [options]
  ./install.sh [options]                    (if you already have this file)
  ./install.sh --uninstall [options]

Options:
  --agents LIST     Comma-separated: claude, codex, opencode, or all.
                     Skips the interactive selector.
  --scope SCOPE      global (your home directory) or project (--dir).
                     Skips the interactive selector.
  --dir PATH         Project directory for --scope project. Defaults to
                     the current directory.
  --ref REF          Branch or tag to install from (default: ${REF}).
  --uninstall, -u    Remove the skills and the router block that this
                     script previously installed. Does not touch anything
                     else in the target instruction file.
  --yes, -y          Don't ask for confirmation before removing files.
  --help, -h         Show this help.

With no options, both agents and scope are chosen from an interactive menu.
Every install is a plain copy — nothing here is ever symlinked, and once
installed a target has no dependency on this script or on GitHub.
EOF
}

# ---------------------------------------------------------------------------
# Argument parsing
# ---------------------------------------------------------------------------

while [ $# -gt 0 ]; do
  case "$1" in
    --uninstall|-u) MODE="uninstall" ;;
    --agents) AGENTS_ARG="${2:-}"; shift ;;
    --agents=*) AGENTS_ARG="${1#*=}" ;;
    --scope) SCOPE="${2:-}"; shift ;;
    --scope=*) SCOPE="${1#*=}" ;;
    --dir) PROJECT_DIR="${2:-}"; shift ;;
    --dir=*) PROJECT_DIR="${1#*=}" ;;
    --ref) REF="${2:-}"; shift ;;
    --ref=*) REF="${1#*=}" ;;
    --yes|-y) ASSUME_YES=1 ;;
    --help|-h) usage; exit 0 ;;
    *) die "unknown option: $1 (see --help)" ;;
  esac
  shift
done

case "$SCOPE" in
  ""|global|project) ;;
  *) die "--scope must be 'global' or 'project'" ;;
esac

# ---------------------------------------------------------------------------
# Get the skills and the router, from a local checkout if this script is
# sitting next to them, otherwise by downloading a tarball of the repo.
# Either way this ends with SKILLS_SRC and ROUTER_SRC pointing at real
# files on disk, and SKILL_NAMES listing what's actually there — never a
# separately maintained list that could drift from the real folder.
# ---------------------------------------------------------------------------

TMP_PATHS=()
cleanup() { rm -rf "${TMP_PATHS[@]}" 2>/dev/null || true; }
trap cleanup EXIT

resolve_source() {
  local script_source="${BASH_SOURCE[0]:-}"
  if [ -n "$script_source" ] && [ -f "$script_source" ]; then
    local dir
    dir="$(cd "$(dirname "$script_source")" && pwd)"
    if [ -d "$dir/skills" ] && [ -f "$dir/AGENTS.md" ]; then
      SKILLS_SRC="$dir/skills"
      ROUTER_SRC="$dir/AGENTS.md"
      return
    fi
  fi
  fetch_release
}

fetch_release() {
  [ "$REPO" != "OWNER/REPO" ] || die "this copy of install.sh hasn't been configured with a real REPO — edit the REPO= line near the top, or run it from inside a full checkout"

  command -v curl >/dev/null 2>&1 || die "curl is required to fetch dev-workflow"
  command -v tar  >/dev/null 2>&1 || die "tar is required to fetch dev-workflow"

  local tmp url extracted
  tmp="$(mktemp -d)"
  TMP_PATHS+=("$tmp")
  url="https://codeload.github.com/${REPO}/tar.gz/refs/heads/${REF}"

  step "Fetching dev-workflow (${REPO}@${REF})"
  curl -fsSL "$url" -o "$tmp/src.tar.gz" \
    || die "couldn't download $url — check the repo name, your connection, or pass --ref"
  tar -xzf "$tmp/src.tar.gz" -C "$tmp" || die "downloaded archive looks corrupt"

  extracted="$(find "$tmp" -mindepth 1 -maxdepth 1 -type d | head -1)"
  [ -n "$extracted" ] || die "unexpected archive layout from ${REPO}"

  SKILLS_SRC="$extracted/skills"
  ROUTER_SRC="$extracted/AGENTS.md"
  [ -d "$SKILLS_SRC" ] && [ -f "$ROUTER_SRC" ] \
    || die "fetched ${REPO}@${REF} but it doesn't look like dev-workflow (missing skills/ or AGENTS.md)"
}

resolve_source

SKILL_NAMES=()
for d in "$SKILLS_SRC"/*/; do
  [ -f "${d}SKILL.md" ] && SKILL_NAMES+=("$(basename "$d")")
done
[ "${#SKILL_NAMES[@]}" -gt 0 ] || die "no skills found in ${SKILLS_SRC}"

# ---------------------------------------------------------------------------
# Reading from the terminal even when stdin is a pipe
#
# `curl ... | bash` hands the script's stdin to the pipe carrying the
# script itself — a `read` against stdin gets EOF, not a keystroke. Every
# prompt in this script reads from /dev/tty instead, which is the actual
# keyboard whether the script arrived via pipe or was run directly.
# ---------------------------------------------------------------------------

can_prompt() { [ -t 1 ] && { [ -e /dev/tty ] || [ -t 0 ]; }; }

prompt_read() {
  if [ -e /dev/tty ]; then
    IFS= read -r "$1" < /dev/tty
  else
    IFS= read -r "$1"
  fi
}

# ---------------------------------------------------------------------------
# Interactive selection (bash 3.2 compatible: indexed arrays only)
# ---------------------------------------------------------------------------

SELECTED_AGENTS=()

select_agents_interactive() {
  local -a picked=(0 0 0)
  local input idx i any

  while true; do
    echo
    echo "Select target agent(s):"
    for i in "${!AGENT_LABELS[@]}"; do
      local mark=" "
      [ "${picked[$i]}" = "1" ] && mark="x"
      printf "  [%s] %d) %s\n" "$mark" "$((i + 1))" "${AGENT_LABELS[$i]}"
    done
    printf "  a) select all      (Enter to confirm)\n> "
    prompt_read input || die "no input available — pass --agents instead"

    case "$input" in
      "")
        any=0
        for i in "${!picked[@]}"; do [ "${picked[$i]}" = "1" ] && any=1; done
        [ "$any" = "1" ] && break
        warn "select at least one agent"
        ;;
      a|A) for i in "${!picked[@]}"; do picked[$i]=1; done ;;
      [1-9]|[1-9][0-9])
        if [ "$input" -ge 1 ] && [ "$input" -le "${#AGENT_LABELS[@]}" ]; then
          idx=$((input - 1))
          if [ "${picked[$idx]}" = "1" ]; then picked[$idx]=0; else picked[$idx]=1; fi
        else
          warn "not a valid number"
        fi
        ;;
      *) warn "type a number to toggle, 'a' for all, or Enter to confirm" ;;
    esac
  done

  for i in "${!AGENT_IDS[@]}"; do
    if [ "${picked[$i]}" = "1" ]; then
      SELECTED_AGENTS+=("${AGENT_IDS[$i]}")
    fi
  done
  return 0
}

select_scope_interactive() {
  local input
  echo
  echo "Install scope:"
  echo "  1) Global  — your home directory, applies to every project"
  echo "  2) Project — $PROJECT_DIR"
  printf "> "
  prompt_read input || die "no input available — pass --scope instead"
  case "$input" in
    2) SCOPE="project" ;;
    *) SCOPE="global" ;;
  esac
}

if [ -n "$AGENTS_ARG" ]; then
  if [ "$AGENTS_ARG" = "all" ]; then
    SELECTED_AGENTS=("${AGENT_IDS[@]}")
  else
    saved_ifs="$IFS"; IFS=','
    for a in $AGENTS_ARG; do
      case "$a" in claude|codex|opencode) SELECTED_AGENTS+=("$a") ;; *) die "unknown agent: $a" ;; esac
    done
    IFS="$saved_ifs"
  fi
else
  can_prompt || die "not an interactive terminal — pass --agents (see --help)"
  select_agents_interactive
fi

if [ -z "$SCOPE" ]; then
  can_prompt || die "not an interactive terminal — pass --scope (see --help)"
  select_scope_interactive
fi

PROJECT_DIR="$(cd "$PROJECT_DIR" 2>/dev/null && pwd)" || die "--dir does not exist: $PROJECT_DIR"

# ---------------------------------------------------------------------------
# Per-agent target paths
# ---------------------------------------------------------------------------

skills_dir_for() {
  case "$1" in
    claude)   [ "$SCOPE" = global ] && echo "$HOME/.claude/skills"             || echo "$PROJECT_DIR/.claude/skills" ;;
    codex)    [ "$SCOPE" = global ] && echo "$HOME/.codex/skills"              || echo "$PROJECT_DIR/.codex/skills" ;;
    opencode) [ "$SCOPE" = global ] && echo "$HOME/.config/opencode/skills"    || echo "$PROJECT_DIR/.opencode/skills" ;;
  esac
}

instruction_file_for() {
  case "$1" in
    claude)   [ "$SCOPE" = global ] && echo "$HOME/.claude/CLAUDE.md"          || echo "$PROJECT_DIR/CLAUDE.md" ;;
    codex)    [ "$SCOPE" = global ] && echo "$HOME/.codex/AGENTS.md"           || echo "$PROJECT_DIR/AGENTS.md" ;;
    opencode) [ "$SCOPE" = global ] && echo "$HOME/.config/opencode/AGENTS.md" || echo "$PROJECT_DIR/AGENTS.md" ;;
  esac
}

label_for() {
  local i
  for i in "${!AGENT_IDS[@]}"; do
    if [ "${AGENT_IDS[$i]}" = "$1" ]; then
      echo "${AGENT_LABELS[$i]}"
      return 0
    fi
  done
  echo "$1"
  return 0
}

# ---------------------------------------------------------------------------
# Skill install / remove — always a plain copy, never a symlink
# ---------------------------------------------------------------------------

# A destination is "ours" if it doesn't exist yet, or if its SKILL.md
# declares the same name we're about to install — never clobber something
# that happens to share a directory name for another reason.
is_ours() {
  local dest="$1" name="$2"
  [ -e "$dest" ] || [ -L "$dest" ] || return 0
  [ -f "$dest/SKILL.md" ] || return 1
  grep -qE "^name: *${name}\$" "$dest/SKILL.md" 2>/dev/null
}

install_skill() {
  local name="$1" target_dir="$2"
  local dest="$target_dir/$name"
  mkdir -p "$target_dir"

  if [ -e "$dest" ] || [ -L "$dest" ]; then
    if ! is_ours "$dest" "$name"; then
      warn "$dest already exists and isn't a dev-workflow skill — skipped"
      return
    fi
    rm -rf "$dest"
  fi

  cp -R "$SKILLS_SRC/$name" "$dest"
}

remove_skill() {
  local name="$1" target_dir="$2"
  local dest="$target_dir/$name"
  [ -e "$dest" ] || [ -L "$dest" ] || return 0
  if ! is_ours "$dest" "$name"; then
    warn "$dest doesn't look like a dev-workflow skill — left in place"
    return
  fi
  rm -rf "$dest"
}

# ---------------------------------------------------------------------------
# Router block: insert, replace, or remove between the markers
#
# Spliced with grep -n (for line numbers) and sed (for ranges) rather than
# awk -v: some system awk builds (notably macOS's) reject a multi-line
# string passed through -v, which this block always is.
# ---------------------------------------------------------------------------

BLOCK_FILE="$(mktemp)"
TMP_PATHS+=("$BLOCK_FILE")

build_block() {
  { printf '%s\n' "$MARKER_START"; cat "$ROUTER_SRC"; printf '%s\n' "$MARKER_END"; } > "$BLOCK_FILE"
}

upsert_block() {
  local file="$1" spliced start_line end_line
  mkdir -p "$(dirname "$file")"

  if [ ! -f "$file" ]; then
    cp "$BLOCK_FILE" "$file"
    return
  fi

  if grep -qF "$MARKER_START" "$file"; then
    start_line="$(grep -nF "$MARKER_START" "$file" | head -1 | cut -d: -f1)"
    end_line="$(grep -nF "$MARKER_END" "$file" | head -1 | cut -d: -f1)"
    spliced="$(mktemp)"
    TMP_PATHS+=("$spliced")
    {
      [ "$start_line" -gt 1 ] && sed -n "1,$((start_line - 1))p" "$file"
      cat "$BLOCK_FILE"
      sed -n "$((end_line + 1)),\$p" "$file"
    } > "$spliced"
    mv "$spliced" "$file"
  else
    printf '\n' >> "$file"
    cat "$BLOCK_FILE" >> "$file"
  fi
}

remove_block() {
  local file="$1" spliced start_line end_line
  [ -f "$file" ] || return 0
  grep -qF "$MARKER_START" "$file" || return 0

  start_line="$(grep -nF "$MARKER_START" "$file" | head -1 | cut -d: -f1)"
  end_line="$(grep -nF "$MARKER_END" "$file" | head -1 | cut -d: -f1)"
  spliced="$(mktemp)"
  TMP_PATHS+=("$spliced")
  {
    [ "$start_line" -gt 1 ] && sed -n "1,$((start_line - 1))p" "$file"
    sed -n "$((end_line + 1)),\$p" "$file"
  } > "$spliced"
  mv "$spliced" "$file"

  if ! grep -q '[^[:space:]]' "$file" 2>/dev/null; then
    rm -f "$file"
  fi
}

# ---------------------------------------------------------------------------
# Confirmation
# ---------------------------------------------------------------------------

confirm() {
  [ "$ASSUME_YES" = "1" ] && return 0
  can_prompt || return 0
  local reply
  printf '%s [y/N] ' "$1"
  prompt_read reply || true
  case "$reply" in y|Y|yes|YES) return 0 ;; *) return 1 ;; esac
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

echo
info "${BOLD}dev-workflow${RESET} — ${MODE} · scope: ${SCOPE}$([ "$SCOPE" = project ] && echo " ($PROJECT_DIR)")"

# De-duplicate instruction files: codex and opencode share AGENTS.md when
# scope is project, so the block is written once, not twice.
PROCESSED_FILES=()
already_processed() {
  local f="$1" p
  for p in "${PROCESSED_FILES[@]:-}"; do [ "$p" = "$f" ] && return 0; done
  return 1
}

if [ "$MODE" = "install" ]; then
  build_block

  for agent in "${SELECTED_AGENTS[@]}"; do
    label="$(label_for "$agent")"
    step "$label"

    target_skills_dir="$(skills_dir_for "$agent")"
    for name in "${SKILL_NAMES[@]}"; do
      install_skill "$name" "$target_skills_dir"
    done
    ok "${#SKILL_NAMES[@]} skills → $target_skills_dir"

    instr_file="$(instruction_file_for "$agent")"
    if already_processed "$instr_file"; then
      ok "router block already written to $instr_file"
      continue
    fi
    upsert_block "$instr_file"
    PROCESSED_FILES+=("$instr_file")
    ok "router block → $instr_file"
  done

  echo
  info "Done. Every skill folder was copied — this install has no dependency"
  info "on GitHub or on this script from here on. Re-run any time to update:"
  info "installing again replaces the skills and the router block in place"
  info "without touching anything else in the instruction file."

else
  if ! confirm "Remove dev-workflow skills and router block for: ${SELECTED_AGENTS[*]} (${SCOPE})?"; then
    info "aborted"
    exit 1
  fi

  for agent in "${SELECTED_AGENTS[@]}"; do
    label="$(label_for "$agent")"
    step "$label"

    target_skills_dir="$(skills_dir_for "$agent")"
    for name in "${SKILL_NAMES[@]}"; do
      remove_skill "$name" "$target_skills_dir"
    done
    rmdir "$target_skills_dir" 2>/dev/null || true
    ok "skills removed from $target_skills_dir"

    instr_file="$(instruction_file_for "$agent")"
    if already_processed "$instr_file"; then
      ok "router block already removed from $instr_file"
      continue
    fi
    remove_block "$instr_file"
    PROCESSED_FILES+=("$instr_file")
    ok "router block removed from $instr_file"
  done

  echo
  info "Done. Only the dev-workflow block was removed — anything else in"
  info "those instruction files was left untouched."
fi
