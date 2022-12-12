'use strict'

const getRenderer = ({ debug, quiet }, env = process.env) => {
  if (quiet) return { renderer: 'silent' }
  // Better support for dumb terminals: https://en.wikipedia.org/wiki/Computer_terminal#Dumb_terminals
  const isDumbTerminal = env.TERM === 'dumb'
  if (debug || isDumbTerminal || env.NODE_ENV === 'test') return { renderer: 'verbose' }
  return { renderer: 'update', rendererOptions: { dateFormat: false } }
}

module.exports = getRenderer
