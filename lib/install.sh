#!/usr/bin/env bash
# badger install — interactive project setup

source "$BADGER_ROOT/lib/config.sh"

badger_install() {
  echo "🦡 badger — A lightweight quality gate for Claude Code sessions."
  echo ""

  # Check if already installed
  if [ -f "$BADGER_CONFIG" ]; then
    echo "badger is already configured in this project ($BADGER_CONFIG)."
    printf "Reinstall? This will overwrite your config. [y/N] "
    read -r answer
    if [ "$answer" != "y" ] && [ "$answer" != "Y" ]; then
      echo "Aborted."
      return 0
    fi
    echo ""
  fi

  # Ask for script paths
  echo "badger needs a few scripts to work. For each one, provide a path."
  echo "If the file doesn't exist, we'll create a starter script for you."
  echo ""

  # test_fast
  printf "Fast test script (runs on every stop when code has changed) [./script/test_fast]: "
  read -r test_fast_path
  test_fast_path="${test_fast_path:-./script/test_fast}"
  create_script_if_missing "$test_fast_path" "fast tests"

  # full test suite
  printf "Full test script (runs before submit) [./script/test]: "
  read -r test_path
  test_path="${test_path:-./script/test}"
  create_script_if_missing "$test_path" "full test suite"

  # submit
  printf "Submit script (runs your submission workflow, e.g. create a PR) [./script/submit]: "
  read -r submit_path
  submit_path="${submit_path:-./script/submit}"
  create_script_if_missing "$submit_path" "submit workflow"

  echo ""

  # Create config
  mkdir -p "$BADGER_DIR/prompts"
  mkdir -p "$BADGER_STATE_DIR"

  cat > "$BADGER_CONFIG" <<EOF
{
  "test_fast": {
    "command": "$test_fast_path"
  },
  "submit": {
    "command": "$submit_path"
  },
  "pre_submit": {
    "commands": ["$test_path"],
    "prompts": [
      ".claude/badger/prompts/done-review.md",
      ".claude/badger/prompts/coverage-review.md",
      ".claude/badger/prompts/test-validity.md"
    ]
  }
}
EOF

  echo "Created $BADGER_CONFIG"

  # Copy default prompts (skip if they already exist)
  copy_default_prompts

  # Create .gitignore for state files
  cat > "$BADGER_DIR/.gitignore" <<'EOF'
.state/
EOF
  echo "Created $BADGER_DIR/.gitignore"

  # Merge hooks into settings.json
  install_hooks

  echo ""
  echo "Done! Restart Claude Code to activate badger."
}

create_script_if_missing() {
  local script_path="$1"
  local description="$2"

  if [ -f "$script_path" ]; then
    echo "  ✓ $script_path exists"
    return
  fi

  local script_dir
  script_dir="$(dirname "$script_path")"
  mkdir -p "$script_dir"

  cat > "$script_path" <<EOF
#!/usr/bin/env bash
set -euo pipefail

# TODO: Configure your $description here.
echo "badger: $script_path is not configured yet. Edit this script to add your $description."
EOF

  chmod +x "$script_path"
  echo "  ✓ Created starter script at $script_path"
}

copy_default_prompts() {
  local prompts_dir="$BADGER_DIR/prompts"
  local defaults_dir="$BADGER_ROOT/prompts"

  for prompt_file in "$defaults_dir"/*.md; do
    local name
    name="$(basename "$prompt_file")"
    local dest="$prompts_dir/$name"

    if [ -f "$dest" ]; then
      echo "  ✓ $dest already exists (keeping yours)"
    else
      cp "$prompt_file" "$dest"
      echo "  ✓ Copied $name to $prompts_dir/"
    fi
  done
}

install_hooks() {
  local settings_file=".claude/settings.json"

  # Create .claude dir if needed
  mkdir -p .claude

  # Use python3 to merge hooks into settings.json
  python3 <<'PYTHON'
import json
import os

settings_file = ".claude/settings.json"

# Load existing settings or start fresh
if os.path.exists(settings_file):
    with open(settings_file) as f:
        settings = json.load(f)
else:
    settings = {}

if "hooks" not in settings:
    settings["hooks"] = {}

hooks = settings["hooks"]

# Define badger hooks
badger_hooks = {
    "Stop": {
        "matcher": "",
        "command": "badger hook stop"
    },
    "SessionStart": {
        "matcher": "",
        "command": "badger hook session-start"
    }
}

for event, hook_entry in badger_hooks.items():
    if event not in hooks:
        hooks[event] = []

    # Check if badger hook already exists
    existing = [h for h in hooks[event] if "badger hook" in h.get("command", "")]
    if not existing:
        hooks[event].append(hook_entry)

with open(settings_file, "w") as f:
    json.dump(settings, f, indent=2)
    f.write("\n")

print(f"  ✓ Hooks registered in {settings_file}")
PYTHON
}
