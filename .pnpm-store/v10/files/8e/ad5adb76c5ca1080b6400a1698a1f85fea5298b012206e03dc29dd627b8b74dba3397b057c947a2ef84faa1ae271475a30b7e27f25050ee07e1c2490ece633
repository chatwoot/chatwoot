interface Options {
  stream?: NodeJS.WriteStream
  frames?: string[]
  interval?: number
  text?: string
  color?: string
}

interface Spinner {
  success(opts?: { text?: string; mark?: string }): Spinner
  error(opts?: { text?: string; mark?: string }): Spinner
  warn(opts?: { text?: string; mark?: string }): Spinner
  stop(opts?: { text?: string; mark?: string; color?: string }): Spinner
  start(opts?: { text?: string; color?: string }): Spinner
  update(opts?: Options): Spinner
  reset(): Spinner
  clear(): Spinner
  spin(): Spinner
}

export function createSpinner(text?: string, opts?: Options): Spinner
