'use strict'

const fs = require('fs')
const path = require('path')

const BADGER_DIR = '.claude/badger'
const CONFIG_PATH = path.join(BADGER_DIR, 'config.json')
const STATE_DIR = path.join(BADGER_DIR, '.state')

function load () {
  if (!fs.existsSync(CONFIG_PATH)) return null
  return JSON.parse(fs.readFileSync(CONFIG_PATH, 'utf8'))
}

function get (key, defaultValue) {
  const cfg = load()
  if (!cfg) return defaultValue

  const keys = key.split('.')
  let val = cfg
  for (const k of keys) {
    if (val == null || typeof val !== 'object') return defaultValue
    val = Array.isArray(val) ? val[parseInt(k, 10)] : val[k]
  }
  return val === undefined ? defaultValue : val
}

function getArray (key) {
  const val = get(key)
  return Array.isArray(val) ? val : []
}

function ensureStateDir () {
  fs.mkdirSync(STATE_DIR, { recursive: true })
}

module.exports = { BADGER_DIR, CONFIG_PATH, STATE_DIR, load, get, getArray, ensureStateDir }
