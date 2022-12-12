import { req, withParams } from './common'

export default (min, max) =>
  withParams(
    { type: 'between', min, max },
    (value) =>
      !req(value) ||
      ((!/\s/.test(value) || value instanceof Date) &&
        +min <= +value &&
        +max >= +value)
  )
