'use strict'

const fs = require('fs')
const path = require('path')
const { execSync } = require('child_process')
const config = require('../config')

module.exports = async function stop (input) {
  // No config — approve silently
  if (!config.load()) {
    approve()
    return
  }

  const testCommand = config.get('test_fast.command')
  if (!testCommand) {
    approve()
    return
  }

  if (!hasChangesSinceLastGreen()) {
    approve()
    return
  }

  // Run the test command
  try {
    execSync(testCommand, { stdio: 'pipe', encoding: 'utf8' })
    updateLastGreen()
    approve()
  } catch (err) {
    const output = (err.stdout || '') + (err.stderr || '')
    block(`Tests are failing. Fix them before proceeding.\n\n${output}`)
  }
}

function hasChangesSinceLastGreen () {
  config.ensureStateDir()
  const lastGreenFile = path.join(config.STATE_DIR, '.last-green')

  if (!fs.existsSync(lastGreenFile)) return true

  const lastGreenSha = fs.readFileSync(lastGreenFile, 'utf8').trim()

  // Check for uncommitted changes
  try {
    const status = execSync('git status --porcelain', { encoding: 'utf8' })
    if (status.trim()) return true
  } catch {
    return true
  }

  // Check for commits since last green
  try {
    const currentSha = execSync('git rev-parse HEAD', { encoding: 'utf8' }).trim()
    return currentSha !== lastGreenSha
  } catch {
    return true
  }
}

function updateLastGreen () {
  config.ensureStateDir()
  const lastGreenFile = path.join(config.STATE_DIR, '.last-green')
  try {
    const sha = execSync('git rev-parse HEAD', { encoding: 'utf8' }).trim()
    fs.writeFileSync(lastGreenFile, sha + '\n')
  } catch {
    // Graceful degradation if not in a git repo
  }
}

function approve () {
  console.log(JSON.stringify({ decision: 'approve' }))
}

function block (reason) {
  console.log(JSON.stringify({ decision: 'block', reason }))
}
