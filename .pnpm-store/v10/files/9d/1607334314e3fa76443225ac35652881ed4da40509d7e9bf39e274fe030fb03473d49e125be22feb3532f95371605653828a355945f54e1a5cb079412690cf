const tty = require('tty')

const isCI =
  process.env.CI ||
  process.env.WT_SESSION ||
  process.env.ConEmuTask === '{cmd::Cmder}' ||
  process.env.TERM_PROGRAM === 'vscode' ||
  process.env.TERM === 'xterm-256color' ||
  process.env.TERM === 'alacritty'
const isTTY = tty.isatty(1) && process.env.TERM !== 'dumb' && !('CI' in process.env)
const supportUnicode = process.platform !== 'win32' ? process.env.TERM !== 'linux' : isCI
const symbols = {
  frames: isTTY
    ? supportUnicode
      ? ['⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏']
      : ['-', '\\', '|', '/']
    : ['-'],
  tick: supportUnicode ? '✔' : '√',
  cross: supportUnicode ? '✖' : '×',
  warn: supportUnicode ? '⚠' : '!!',
}

module.exports = { isTTY, symbols }
