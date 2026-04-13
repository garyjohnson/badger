'use strict'

const fs = require('fs')
const config = require('./config')

module.exports = async function uninstall () {
  let removedSomething = false

  // Remove hooks from settings.json
  const settingsFile = '.claude/settings.json'
  if (fs.existsSync(settingsFile)) {
    const settings = JSON.parse(fs.readFileSync(settingsFile, 'utf8'))
    const hooks = settings.hooks || {}
    let changed = false

    for (const event of Object.keys(hooks)) {
      const original = hooks[event].length
      hooks[event] = hooks[event].filter(h => !(h.command || '').includes('badger hook'))
      if (hooks[event].length !== original) changed = true
      if (hooks[event].length === 0) delete hooks[event]
    }

    if (Object.keys(hooks).length === 0) delete settings.hooks

    if (changed) {
      fs.writeFileSync(settingsFile, JSON.stringify(settings, null, 2) + '\n')
      console.log('  ✓ Removed badger hooks from .claude/settings.json')
      removedSomething = true
    } else {
      console.log('  No badger hooks found in .claude/settings.json')
    }
  }

  // Remove .claude/badger/ directory
  if (fs.existsSync(config.BADGER_DIR)) {
    fs.rmSync(config.BADGER_DIR, { recursive: true, force: true })
    console.log(`  ✓ Removed ${config.BADGER_DIR}/`)
    removedSomething = true
  }

  if (!removedSomething) {
    console.log('badger is not installed in this project.')
    return
  }

  console.log('')
  console.log('badger has been removed. Restart Claude Code to deactivate.')
}
