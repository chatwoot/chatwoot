const stack = []

// exported for tests
export let target = null
export const _setTarget = (x) => {
  target = x
}

export function pushParams() {
  if (target !== null) {
    stack.push(target)
  }
  target = {}
}

export function popParams() {
  const lastTarget = target
  const newTarget = (target = stack.pop() || null)
  if (newTarget) {
    if (!Array.isArray(newTarget.$sub)) {
      newTarget.$sub = []
    }
    newTarget.$sub.push(lastTarget)
  }
  return lastTarget
}

function addParams(params) {
  if (typeof params === 'object' && !Array.isArray(params)) {
    target = { ...target, ...params }
  } else {
    throw new Error('params must be an object')
  }
}

function withParamsDirect(params, validator) {
  return withParamsClosure((add) => {
    return function(...args) {
      add(params)
      return validator.apply(this, args)
    }
  })
}

function withParamsClosure(closure) {
  const validator = closure(addParams)
  return function(...args) {
    pushParams()
    try {
      return validator.apply(this, args)
    } finally {
      popParams()
    }
  }
}

export function withParams(paramsOrClosure, maybeValidator) {
  if (typeof paramsOrClosure === 'object' && maybeValidator !== undefined) {
    return withParamsDirect(paramsOrClosure, maybeValidator)
  }
  return withParamsClosure(paramsOrClosure)
}
