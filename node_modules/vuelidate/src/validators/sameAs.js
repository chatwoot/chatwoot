import { ref, withParams } from './common'
export default (equalTo) =>
  withParams({ type: 'sameAs', eq: equalTo }, function(value, parentVm) {
    return value === ref(equalTo, this, parentVm)
  })
