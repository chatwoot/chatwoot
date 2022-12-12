import { withParams, req } from './common'
export default withParams({ type: 'required' }, (value) => {
  if (typeof value === 'string') {
    return req(value.trim())
  }
  return req(value)
})
