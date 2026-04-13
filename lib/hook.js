'use strict'

const hookStop = require('./hooks/stop')
const hookSessionStart = require('./hooks/session-start')

const hooks = {
  stop: hookStop,
  'session-start': hookSessionStart
}

module.exports = async function hook (args) {
  const event = args[0]
  if (!event || !hooks[event]) {
    console.error(`badger: unknown hook event: ${event || '(none)'}`)
    process.exit(1)
  }

  // Read stdin (Claude Code sends JSON)
  const input = await readStdin()
  await hooks[event](input)
}

function readStdin () {
  return new Promise(resolve => {
    let data = ''
    process.stdin.setEncoding('utf8')
    process.stdin.on('data', chunk => { data += chunk })
    process.stdin.on('end', () => {
      try {
        resolve(JSON.parse(data))
      } catch {
        resolve({})
      }
    })
    // If stdin is a TTY (no piped input), resolve immediately
    if (process.stdin.isTTY) resolve({})
  })
}
