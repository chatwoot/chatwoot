import { withParams, req } from './common'

export default (validator) => {
  return withParams({ type: 'not' }, function(value, vm) {
    return !req(value) || !validator.call(this, value, vm)
  })
}
