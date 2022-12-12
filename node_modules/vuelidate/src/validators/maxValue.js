import { req, withParams } from './common'
export default (max) =>
  withParams(
    { type: 'maxValue', max },
    (value) =>
      !req(value) ||
      ((!/\s/.test(value) || value instanceof Date) && +value <= +max)
  )
