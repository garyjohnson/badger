#!/usr/bin/env bash
# badger Stop hook — run test_fast if code has changed since last green

source "$BADGER_ROOT/lib/config.sh"

badger_hook_stop() {
  # Read hook input from stdin (Claude Code sends JSON)
  local input
  input="$(cat)"

  # If no config, approve silently
  if [ ! -f "$BADGER_CONFIG" ]; then
    approve
    return
  fi

  local test_command
  test_command="$(badger_config_get "test_fast.command")"

  # If no test_fast command configured, approve
  if [ -z "$test_command" ]; then
    approve
    return
  fi

  # Check if code has changed since last green
  if ! has_changes_since_last_green; then
    approve
    return
  fi

  # Run the test command
  local test_output
  local test_exit_code
  test_output="$(eval "$test_command" 2>&1)" || test_exit_code=$?
  test_exit_code="${test_exit_code:-0}"

  if [ "$test_exit_code" -eq 0 ]; then
    # Tests passed — update last green SHA
    update_last_green
    approve
  else
    # Tests failed — block with output
    block "Tests are failing. Fix them before proceeding.

$test_output"
  fi
}

has_changes_since_last_green() {
  ensure_state_dir

  local last_green_file="$BADGER_STATE_DIR/.last-green"

  # If no last green SHA, there are changes (first run)
  if [ ! -f "$last_green_file" ]; then
    return 0
  fi

  local last_green_sha
  last_green_sha="$(cat "$last_green_file")"

  # Check for uncommitted changes
  if [ -n "$(git status --porcelain 2>/dev/null)" ]; then
    return 0
  fi

  # Check for commits since last green
  local current_sha
  current_sha="$(git rev-parse HEAD 2>/dev/null || echo "")"

  if [ "$current_sha" != "$last_green_sha" ]; then
    return 0
  fi

  # No changes
  return 1
}

update_last_green() {
  ensure_state_dir
  local last_green_file="$BADGER_STATE_DIR/.last-green"
  git rev-parse HEAD > "$last_green_file" 2>/dev/null || true
}

approve() {
  cat <<'EOF'
{"decision": "approve"}
EOF
}

block() {
  local reason="$1"
  python3 -c "
import json, sys
print(json.dumps({'decision': 'block', 'reason': sys.stdin.read()}))
" <<< "$reason"
}
