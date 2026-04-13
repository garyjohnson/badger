#!/usr/bin/env bash
# badger uninstall — remove badger from the current project

source "$BADGER_ROOT/lib/config.sh"

badger_uninstall() {
  local removed_something=false

  # Remove hooks from settings.json
  local settings_file=".claude/settings.json"
  if [ -f "$settings_file" ]; then
    python3 <<'PYTHON'
import json
import os

settings_file = ".claude/settings.json"

with open(settings_file) as f:
    settings = json.load(f)

hooks = settings.get("hooks", {})
changed = False

for event in list(hooks.keys()):
    original_len = len(hooks[event])
    hooks[event] = [h for h in hooks[event] if "badger hook" not in h.get("command", "")]
    if len(hooks[event]) != original_len:
        changed = True
    if not hooks[event]:
        del hooks[event]

if not hooks:
    settings.pop("hooks", None)

if changed:
    with open(settings_file, "w") as f:
        json.dump(settings, f, indent=2)
        f.write("\n")
    print("  ✓ Removed badger hooks from .claude/settings.json")
else:
    print("  No badger hooks found in .claude/settings.json")
PYTHON
    removed_something=true
  fi

  # Remove .claude/badger/ directory
  if [ -d "$BADGER_DIR" ]; then
    rm -rf "$BADGER_DIR"
    echo "  ✓ Removed $BADGER_DIR/"
    removed_something=true
  fi

  if [ "$removed_something" = false ]; then
    echo "badger is not installed in this project."
    return 0
  fi

  echo ""
  echo "badger has been removed. Restart Claude Code to deactivate."
}
