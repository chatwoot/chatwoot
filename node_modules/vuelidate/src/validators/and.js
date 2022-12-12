import { withParams } from './common'
export default (...validators) => {
  return withParams({ type: 'and' }, function(...args) {
    return (
      validators.length > 0 &&
      validators.reduce((valid, fn) => valid && fn.apply(this, args), true)
    )
  })
}
