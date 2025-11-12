const pico = require('picocolors')

const { isTTY, symbols } = require('./consts')

const { green, red, yellow } = pico

function getLines(str = '', width = 80) {
  return str
    .replace(/\u001b[^m]*?m/g, '')
    .split('\n')
    .reduce((col, line) => (col += Math.max(1, Math.ceil(line.length / width))), 0)
}

function createSpinner(text = '', opts = {}) {
  let current = 0,
    interval = opts.interval || 50,
    stream = opts.stream || process.stderr,
    frames = opts.frames && opts.frames.length ? opts.frames : symbols.frames,
    color = opts.color || 'yellow',
    lines = 0,
    timer

  let spinner = {
    reset() {
      current = 0
      lines = 0
      timer = clearTimeout(timer)
    },

    clear() {
      spinner.write('\x1b[1G')
      for (let i = 0; i < lines; i++) {
        i > 0 && spinner.write('\x1b[1A')
        spinner.write('\x1b[2K\x1b[1G')
      }
      lines = 0

      return spinner
    },

    write(str, clear = false) {
      if (clear && isTTY) {
        spinner.clear()
      }

      stream.write(str)
      return spinner
    },

    render() {
      let mark = pico[color](frames[current])
      let str = `${mark} ${text}`
      isTTY ? spinner.write(`\x1b[?25l`) : (str += '\n')
      spinner.write(str, true)
      isTTY && (lines = getLines(str, stream.columns))
    },

    spin() {
      spinner.render()
      current = ++current % frames.length
      return spinner
    },

    update(opts = {}) {
      text = opts.text || text
      frames = opts.frames && opts.frames.length ? opts.frames : frames
      interval = opts.interval || interval
      color = opts.color || color

      if (frames.length - 1 < current) {
        current = 0
      }

      return spinner
    },

    loop() {
      isTTY && (timer = setTimeout(() => spinner.loop(), interval))
      return spinner.spin()
    },

    start(opts = {}) {
      timer && spinner.reset()
      return spinner.update({ text: opts.text, color: opts.color }).loop()
    },

    stop(opts = {}) {
      timer = clearTimeout(timer)

      let mark = pico[opts.color || color](frames[current])
      let optsMark = opts.mark && opts.color ? pico[opts.color](opts.mark) : opts.mark
      spinner.write(`${optsMark || mark} ${opts.text || text}\n`, true)

      return isTTY ? spinner.write(`\x1b[?25h`) : spinner
    },

    success(opts = {}) {
      let mark = green(symbols.tick)
      return spinner.stop({ mark, ...opts })
    },

    error(opts = {}) {
      let mark = red(symbols.cross)
      return spinner.stop({ mark, ...opts })
    },

    warn(opts = {}) {
      let mark = yellow(symbols.warn)
      return spinner.stop({ mark, ...opts })
    },
  }

  return spinner
}

module.exports = {
  createSpinner,
}
