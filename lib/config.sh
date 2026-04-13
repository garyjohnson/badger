#!/usr/bin/env bash
# Shared config utilities for badger

BADGER_DIR=".claude/badger"
BADGER_CONFIG="$BADGER_DIR/config.json"
BADGER_STATE_DIR="$BADGER_DIR/.state"

badger_config_get() {
  local key="$1"
  local default="${2:-}"

  if [ ! -f "$BADGER_CONFIG" ]; then
    echo "$default"
    return
  fi

  # Use python for JSON parsing (available on macOS and most Linux)
  local value
  value=$(python3 -c "
import json, sys
try:
    with open('$BADGER_CONFIG') as f:
        cfg = json.load(f)
    keys = '$key'.split('.')
    val = cfg
    for k in keys:
        if isinstance(val, dict):
            val = val.get(k)
        elif isinstance(val, list):
            val = val[int(k)] if k.isdigit() and int(k) < len(val) else None
        else:
            val = None
        if val is None:
            break
    if val is None:
        print('')
    elif isinstance(val, (list, dict)):
        print(json.dumps(val))
    else:
        print(val)
except Exception:
    print('')
" 2>/dev/null)

  if [ -z "$value" ]; then
    echo "$default"
  else
    echo "$value"
  fi
}

badger_config_get_array() {
  local key="$1"

  if [ ! -f "$BADGER_CONFIG" ]; then
    return
  fi

  python3 -c "
import json
try:
    with open('$BADGER_CONFIG') as f:
        cfg = json.load(f)
    keys = '$key'.split('.')
    val = cfg
    for k in keys:
        if isinstance(val, dict):
            val = val.get(k)
        else:
            val = None
        if val is None:
            break
    if isinstance(val, list):
        for item in val:
            print(item)
except Exception:
    pass
" 2>/dev/null
}

ensure_state_dir() {
  mkdir -p "$BADGER_STATE_DIR"
}
