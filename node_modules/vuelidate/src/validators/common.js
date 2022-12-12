import withParams from '../withParams'
export { withParams }

// "required" core, used in almost every validator to allow empty values
export const req = (value) => {
  if (Array.isArray(value)) return !!value.length
  if (value === undefined || value === null) {
    return false
  }

  if (value === false) {
    return true
  }

  if (value instanceof Date) {
    // invalid date won't pass
    return !isNaN(value.getTime())
  }

  if (typeof value === 'object') {
    for (let _ in value) return true
    return false
  }

  return !!String(value).length
}

// get length in type-agnostic way
export const len = (value) => {
  if (Array.isArray(value)) return value.length
  if (typeof value === 'object') {
    return Object.keys(value).length
  }
  return String(value).length
}

// resolve referenced value
export const ref = (reference, vm, parentVm) =>
  typeof reference === 'function'
    ? reference.call(vm, parentVm)
    : parentVm[reference]

// regex based validator template
export const regex = (type, expr) =>
  withParams({ type }, (value) => !req(value) || expr.test(value))
