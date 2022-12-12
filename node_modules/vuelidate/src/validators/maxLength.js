import { req, len, withParams } from './common'
export default (length) =>
  withParams(
    { type: 'maxLength', max: length },
    (value) => !req(value) || len(value) <= length
  )
