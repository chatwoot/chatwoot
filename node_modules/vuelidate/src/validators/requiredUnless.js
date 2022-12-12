import { req, ref, withParams } from './common'
export default (prop) =>
  withParams({ type: 'requiredUnless', prop }, function(value, parentVm) {
    return !ref(prop, this, parentVm) ? req(value) : true
  })
