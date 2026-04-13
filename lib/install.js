'use strict'

const fs = require('fs')
const path = require('path')
const readline = require('readline')
const config = require('./config')

function ask (rl, question) {
  return new Promise(resolve => rl.question(question, resolve))
}

function createScriptIfMissing (scriptPath, description) {
  if (fs.existsSync(scriptPath)) {
    console.log(`  ✓ ${scriptPath} exists`)
    return
  }

  fs.mkdirSync(path.dirname(scriptPath), { recursive: true })
  fs.writeFileSync(scriptPath, `#!/usr/bin/env bash
set -euo pipefail

# TODO: Configure your ${description} here.
echo "badger: ${scriptPath} is not configured yet. Edit this script to add your ${description}."
`)
  fs.chmodSync(scriptPath, 0o755)
  console.log(`  ✓ Created starter script at ${scriptPath}`)
}

function copyDefaultPrompts (badgerRoot) {
  const promptsDir = path.join(config.BADGER_DIR, 'prompts')
  const defaultsDir = path.join(badgerRoot, 'prompts')

  if (!fs.existsSync(defaultsDir)) return

  for (const file of fs.readdirSync(defaultsDir)) {
    if (!file.endsWith('.md')) continue
    const dest = path.join(promptsDir, file)
    if (fs.existsSync(dest)) {
      console.log(`  ✓ ${dest} already exists (keeping yours)`)
    } else {
      fs.copyFileSync(path.join(defaultsDir, file), dest)
      console.log(`  ✓ Copied ${file} to ${promptsDir}/`)
    }
  }
}

function installHooks () {
  const settingsFile = '.claude/settings.json'
  fs.mkdirSync('.claude', { recursive: true })

  let settings = {}
  if (fs.existsSync(settingsFile)) {
    settings = JSON.parse(fs.readFileSync(settingsFile, 'utf8'))
  }

  if (!settings.hooks) settings.hooks = {}

  const badgerHooks = {
    Stop: { matcher: '', command: 'badger hook stop' },
    SessionStart: { matcher: '', command: 'badger hook session-start' }
  }

  for (const [event, hookEntry] of Object.entries(badgerHooks)) {
    if (!settings.hooks[event]) settings.hooks[event] = []
    const exists = settings.hooks[event].some(h => (h.command || '').includes('badger hook'))
    if (!exists) {
      settings.hooks[event].push(hookEntry)
    }
  }

  fs.writeFileSync(settingsFile, JSON.stringify(settings, null, 2) + '\n')
  console.log(`  ✓ Hooks registered in ${settingsFile}`)
}

module.exports = async function install () {
  const badgerRoot = path.resolve(__dirname, '..')

  console.log('badger — A lightweight quality gate for Claude Code sessions.')
  console.log('')

  if (fs.existsSync(config.CONFIG_PATH)) {
    const rl = readline.createInterface({ input: process.stdin, output: process.stdout })
    const answer = await ask(rl, 'badger is already configured in this project. Reinstall? [y/N] ')
    rl.close()
    if (answer.toLowerCase() !== 'y') {
      console.log('Aborted.')
      return
    }
    console.log('')
  }

  const rl = readline.createInterface({ input: process.stdin, output: process.stdout })

  console.log('badger needs a few scripts to work. For each one, provide a path.')
  console.log("If the file doesn't exist, we'll create a starter script for you.")
  console.log('')

  const testFastPath = (await ask(rl, 'Fast test script (runs on every stop when code has changed) [./script/test_fast]: ')) || './script/test_fast'
  createScriptIfMissing(testFastPath, 'fast tests')

  const testPath = (await ask(rl, 'Full test script (runs before submit) [./script/test]: ')) || './script/test'
  createScriptIfMissing(testPath, 'full test suite')

  const submitPath = (await ask(rl, 'Submit script (runs your submission workflow, e.g. create a PR) [./script/submit]: ')) || './script/submit'
  createScriptIfMissing(submitPath, 'submit workflow')

  rl.close()
  console.log('')

  // Create directories
  fs.mkdirSync(path.join(config.BADGER_DIR, 'prompts'), { recursive: true })
  fs.mkdirSync(config.STATE_DIR, { recursive: true })

  // Write config
  const cfg = {
    test_fast: { command: testFastPath },
    submit: { command: submitPath },
    pre_submit: {
      commands: [testPath],
      prompts: [
        '.claude/badger/prompts/done-review.md',
        '.claude/badger/prompts/coverage-review.md',
        '.claude/badger/prompts/test-validity.md'
      ]
    }
  }
  fs.writeFileSync(config.CONFIG_PATH, JSON.stringify(cfg, null, 2) + '\n')
  console.log(`Created ${config.CONFIG_PATH}`)

  // Copy default prompts
  copyDefaultPrompts(badgerRoot)

  // Create .gitignore for state files
  fs.writeFileSync(path.join(config.BADGER_DIR, '.gitignore'), '.state/\n')
  console.log(`Created ${config.BADGER_DIR}/.gitignore`)

  // Install hooks
  installHooks()

  console.log('')
  console.log('Done! Restart Claude Code to activate badger.')
}
