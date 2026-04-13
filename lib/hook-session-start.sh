#!/usr/bin/env bash
# badger SessionStart hook — inject workflow context into Claude's session

source "$BADGER_ROOT/lib/config.sh"

badger_hook_session_start() {
  # Read hook input from stdin
  local input
  input="$(cat)"

  # If no config, do nothing
  if [ ! -f "$BADGER_CONFIG" ]; then
    echo '{}'
    return
  fi

  local submit_command
  submit_command="$(badger_config_get "submit.command")"

  local message="This project uses badger for quality enforcement. Your tests will be checked automatically when you stop."

  if [ -n "$submit_command" ]; then
    message="$message When you complete a unit of work, submit it by running \`badger submit\`. Do not skip or bypass these checks."
  fi

  python3 -c "
import json, sys
print(json.dumps({'additionalContext': sys.stdin.read()}))
" <<< "$message"
}
