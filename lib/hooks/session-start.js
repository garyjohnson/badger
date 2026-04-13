'use strict'

const config = require('../config')

module.exports = async function sessionStart (input) {
  if (!config.load()) {
    console.log('{}')
    return
  }

  const submitCommand = config.get('submit.command')
  let message = 'This project uses badger for quality enforcement. Your tests will be checked automatically when you stop.'

  if (submitCommand) {
    message += ' When you complete a unit of work, submit it by running `badger submit`. Do not skip or bypass these checks.'
  }

  console.log(JSON.stringify({
    hookSpecificOutput: {
      hookEventName: 'SessionStart',
      additionalContext: message
    }
  }))
}
