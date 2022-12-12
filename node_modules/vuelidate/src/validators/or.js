import { withParams } from './common'
export default (...validators) => {
  return withParams({ type: 'or' }, function(...args) {
    return (
      validators.length > 0 &&
      validators.reduce((valid, fn) => valid || fn.apply(this, args), false)
    )
  })
}
