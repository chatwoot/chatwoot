import { req, len, withParams } from './common'
export default (length) =>
  withParams(
    { type: 'minLength', min: length },
    (value) => !req(value) || len(value) >= length
  )
