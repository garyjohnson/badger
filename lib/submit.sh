#!/usr/bin/env bash
# badger submit — pre-submit checks and submit workflow

source "$BADGER_ROOT/lib/config.sh"

badger_submit() {
  if [ ! -f "$BADGER_CONFIG" ]; then
    echo "badger: no config found. Run 'badger install' first." >&2
    exit 1
  fi

  local finalize=false
  if [ "${1:-}" = "--finalize" ]; then
    finalize=true
  fi

  if [ "$finalize" = true ]; then
    do_finalize
  else
    do_submit
  fi
}

do_submit() {
  echo "badger: running pre-submit checks..."
  echo ""

  # Run pre_submit commands
  if ! run_pre_submit_commands; then
    exit 1
  fi

  # Print prompts for review
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "Pre-submit checks passed. Please review the following guidance:"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""

  print_prompts

  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "Review the guidance above and address any issues."
  echo "When ready, run: badger submit --finalize"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

do_finalize() {
  echo "badger: re-running pre-submit checks..."
  echo ""

  # Re-run pre_submit commands
  if ! run_pre_submit_commands; then
    echo "" >&2
    echo "badger: pre-submit checks failed. Fix the issues and try again." >&2
    exit 1
  fi

  echo ""
  echo "badger: all checks passed. Running submit..."
  echo ""

  # Run the submit command
  local submit_command
  submit_command="$(badger_config_get "submit.command")"

  if [ -z "$submit_command" ]; then
    echo "badger: no submit command configured." >&2
    exit 1
  fi

  eval "$submit_command"
  local exit_code=$?

  if [ $exit_code -eq 0 ]; then
    # Reset state on successful submit
    ensure_state_dir
    rm -f "$BADGER_STATE_DIR/.last-green"
    echo ""
    echo "badger: submitted successfully."
  else
    echo "" >&2
    echo "badger: submit command failed (exit code $exit_code)." >&2
    exit $exit_code
  fi
}

run_pre_submit_commands() {
  local commands
  commands="$(badger_config_get_array "pre_submit.commands")"

  if [ -z "$commands" ]; then
    return 0
  fi

  while IFS= read -r cmd; do
    [ -z "$cmd" ] && continue
    echo "  Running: $cmd"
    local output
    local exit_code=0
    output="$(eval "$cmd" 2>&1)" || exit_code=$?

    if [ $exit_code -ne 0 ]; then
      echo "" >&2
      echo "  FAILED: $cmd (exit code $exit_code)" >&2
      echo "$output" >&2
      return 1
    else
      echo "  ✓ Passed"
    fi
  done <<< "$commands"

  return 0
}

print_prompts() {
  local prompts
  prompts="$(badger_config_get_array "pre_submit.prompts")"

  if [ -z "$prompts" ]; then
    return
  fi

  while IFS= read -r prompt_path; do
    [ -z "$prompt_path" ] && continue

    if [ ! -f "$prompt_path" ]; then
      echo "  Warning: prompt not found: $prompt_path" >&2
      continue
    fi

    echo "--- $(basename "$prompt_path" .md) ---"
    echo ""
    cat "$prompt_path"
    echo ""
  done <<< "$prompts"
}
