# badger

A lightweight quality gate for [Claude Code](https://docs.anthropic.com/en/docs/claude-code) sessions.

Claude Code is great at writing code. It's less great at making sure that code actually works before declaring victory. badger fixes that — it runs your tests when Claude stops, and gates submissions behind configurable quality checks.

No subagents. No backchannel appeals. No token-burning review loops. Just your test suite and a few well-placed prompts.

## How it works

badger does two things:

1. **Runs your fast tests every time Claude stops** (but only if code actually changed). If tests fail, Claude is blocked until they pass.

2. **Gates your submit workflow** with pre-submit checks — both scripts (your full test suite, linters, etc.) and prompt-based reviews (test coverage, correctness, security) that run in Claude's own context.

### The Stop hook

When Claude tries to stop, badger checks whether anything changed since tests last passed (using git). If so, it runs your fast test script. If tests fail, Claude gets blocked with the test output and has to fix them.

If nothing changed — you were just chatting, asking questions, reading code — badger approves immediately. Zero overhead.

### The submit workflow

When Claude finishes a unit of work:

```
Claude runs: badger submit
```

badger runs your pre-submit commands (full test suite, linting, etc.). If they pass, it prints your configured review prompts — guidance for Claude to review its own work for test coverage, correctness, and security. Claude reads the prompts, addresses any issues, then:

```
Claude runs: badger submit --finalize
```

badger re-runs the pre-submit commands (in case Claude changed code during review) and, if everything passes, executes your submit script.

## Quick start

```bash
brew install garyjohnson/tap/badger
cd your-project
badger install
```

The interactive installer asks for three script paths:

- **Fast test script** — runs on every stop when code has changed (e.g., `./script/test_fast`)
- **Full test script** — runs before submit (e.g., `./script/test`)
- **Submit script** — your submission workflow (e.g., `./script/submit`)

If any script doesn't exist, badger creates a starter stub for you.

Restart Claude Code and you're live.

## What gets created

```
your-project/
├── .claude/
│   ├── settings.json              # badger hooks added here
│   └── badger/
│       ├── config.json            # your badger configuration
│       ├── prompts/
│       │   ├── done-review.md     # pre-ship checklist
│       │   ├── coverage-review.md # test coverage review
│       │   └── test-validity.md   # test quality review
│       ├── .gitignore             # ignores state files
│       └── .state/                # internal state (gitignored)
├── script/
│   ├── test_fast                  # your fast tests
│   ├── test                       # your full test suite
│   └── submit                     # your submit workflow
```

**Commit `.claude/badger/` to git** (except `.state/`, which is gitignored). This shares your badger config and prompts with your team.

## Configuration

`.claude/badger/config.json`:

```json
{
  "test_fast": {
    "command": "./script/test_fast"
  },
  "submit": {
    "command": "./script/submit"
  },
  "pre_submit": {
    "commands": ["./script/test"],
    "prompts": [
      ".claude/badger/prompts/done-review.md",
      ".claude/badger/prompts/coverage-review.md",
      ".claude/badger/prompts/test-validity.md"
    ]
  }
}
```

### Customizing prompts

badger ships three review prompts:

- **done-review** — a compressed pre-ship checklist: correctness, integration, security, error handling, omissions
- **coverage-review** — checks that new/changed logic has tests
- **test-validity** — catches tests that give false confidence (vacuous assertions, missing assertions, over-mocking)

These are plain markdown files. Edit them, replace them, or add your own. The prompts run in Claude's own context — Claude reads them and acts on them as part of its workflow. No subagents, no external reviewers.

To add a custom prompt, drop a `.md` file in `.claude/badger/prompts/` and add its path to `pre_submit.prompts` in your config.

## Commands

| Command | Description |
|---|---|
| `badger install` | Interactive project setup |
| `badger uninstall` | Remove badger from the current project |
| `badger submit` | Run pre-submit checks and prompt review |
| `badger submit --finalize` | Re-run checks and execute submit action |
| `badger version` | Print version |

## Uninstalling

```bash
badger uninstall
```

Removes hooks from `.claude/settings.json` and deletes `.claude/badger/`. Your scripts in `./script/` are left untouched.

## Philosophy

badger is a reaction to the complexity of tools that try to enforce perfect behavior from AI coding assistants. The reality is:

- Claude will mess up sometimes. That's fine.
- Running tests catches most problems. Subagent reviewers catch marginally more at 10x the cost.
- A well-placed prompt in Claude's own context is worth more than an expensive external audit.
- The best quality gate is the one that's fast enough that you never think about disabling it.

## License

MIT
