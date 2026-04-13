'use strict'

const fs = require('fs')
const path = require('path')
const { execSync } = require('child_process')
const config = require('./config')

module.exports = async function submit (args) {
  if (!config.load()) {
    console.error("badger: no config found. Run 'badger install' first.")
    process.exit(1)
  }

  if (args[0] === '--finalize') {
    await doFinalize()
  } else {
    await doSubmit()
  }
}

async function doSubmit () {
  console.log('badger: running pre-submit checks...')
  console.log('')

  if (!runPreSubmitCommands()) {
    process.exit(1)
  }

  console.log('')
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━')
  console.log('Pre-submit checks passed. Please review the following guidance:')
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━')
  console.log('')

  printPrompts()

  console.log('')
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━')
  console.log('Review the guidance above and address any issues.')
  console.log('When ready, run: badger submit --finalize')
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━')
}

async function doFinalize () {
  console.log('badger: re-running pre-submit checks...')
  console.log('')

  if (!runPreSubmitCommands()) {
    console.error('')
    console.error('badger: pre-submit checks failed. Fix the issues and try again.')
    process.exit(1)
  }

  console.log('')
  console.log('badger: all checks passed. Running submit...')
  console.log('')

  const submitCommand = config.get('submit.command')
  if (!submitCommand) {
    console.error('badger: no submit command configured.')
    process.exit(1)
  }

  try {
    execSync(submitCommand, { stdio: 'inherit' })
  } catch (err) {
    console.error('')
    console.error(`badger: submit command failed (exit code ${err.status}).`)
    process.exit(err.status || 1)
  }

  // Reset state on successful submit
  config.ensureStateDir()
  const lastGreenFile = path.join(config.STATE_DIR, '.last-green')
  try { fs.unlinkSync(lastGreenFile) } catch {}

  console.log('')
  console.log('badger: submitted successfully.')
}

function runPreSubmitCommands () {
  const commands = config.getArray('pre_submit.commands')
  if (commands.length === 0) return true

  for (const cmd of commands) {
    if (!cmd) continue
    console.log(`  Running: ${cmd}`)
    try {
      execSync(cmd, { stdio: 'pipe', encoding: 'utf8' })
      console.log('  ✓ Passed')
    } catch (err) {
      const output = (err.stdout || '') + (err.stderr || '')
      console.error('')
      console.error(`  FAILED: ${cmd} (exit code ${err.status})`)
      if (output) console.error(output)
      return false
    }
  }

  return true
}

function printPrompts () {
  const prompts = config.getArray('pre_submit.prompts')
  if (prompts.length === 0) return

  for (const promptPath of prompts) {
    if (!promptPath) continue
    if (!fs.existsSync(promptPath)) {
      console.error(`  Warning: prompt not found: ${promptPath}`)
      continue
    }

    const name = path.basename(promptPath, '.md')
    console.log(`--- ${name} ---`)
    console.log('')
    console.log(fs.readFileSync(promptPath, 'utf8'))
    console.log('')
  }
}
