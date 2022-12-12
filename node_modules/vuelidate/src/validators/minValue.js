import { req, withParams } from './common'
export default (min) =>
  withParams(
    { type: 'minValue', min },
    (value) =>
      !req(value) ||
      ((!/\s/.test(value) || value instanceof Date) && +value >= +min)
  )
