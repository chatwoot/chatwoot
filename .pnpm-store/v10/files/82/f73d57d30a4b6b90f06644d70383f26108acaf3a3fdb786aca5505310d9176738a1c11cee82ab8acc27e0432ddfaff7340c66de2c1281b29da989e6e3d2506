import { unref, isRef, watch } from 'vue'
import {
  unref as _unref,
  isRef as _isRef,
  watch as _watch,
} from '@histoire/vendors/vue'
import { applyState } from '@histoire/shared'

const isObject = (val) => val !== null && typeof val === 'object'

/**
 * Using external/user Vue
 */
export function toRawDeep (val, seen = new WeakMap()) {
  const unwrappedValue = isRef(val) ? unref(val) : val

  if (typeof unwrappedValue === 'symbol') {
    return unwrappedValue.toString()
  }

  if (!isObject(unwrappedValue)) {
    return unwrappedValue
  }

  if (seen.has(unwrappedValue)) {
    return seen.get(unwrappedValue)
  }

  if (Array.isArray(unwrappedValue)) {
    const result = []
    seen.set(unwrappedValue, result)
    result.push(...unwrappedValue.map(value => toRawDeep(value, seen)))
    return result
  } else {
    const result = {}
    seen.set(unwrappedValue, result)
    toRawObject(unwrappedValue, result, seen)
    return result
  }
}

const toRawObject = (obj: Record<any, any>, target: Record<any, any>, seen = new WeakMap()) => {
  Object.keys(obj).forEach((key) => {
    target[key] = toRawDeep(obj[key], seen)
  })
}

/**
 * Using bundled Vue
 */
export function _toRawDeep (val, seen = new WeakMap()) {
  const unwrappedValue = _isRef(val) ? _unref(val) : val

  if (typeof unwrappedValue === 'symbol') {
    return unwrappedValue.toString()
  }

  if (!isObject(unwrappedValue)) {
    return unwrappedValue
  }

  if (seen.has(unwrappedValue)) {
    return seen.get(unwrappedValue)
  }

  if (Array.isArray(unwrappedValue)) {
    const result = []
    seen.set(unwrappedValue, result)
    result.push(...unwrappedValue.map(value => _toRawDeep(value, seen)))
    return result
  } else {
    const result = {}
    seen.set(unwrappedValue, result)
    _toRawObject(unwrappedValue, result, seen)
    return result
  }
}

const _toRawObject = (obj: Record<any, any>, target: Record<any, any>, seen = new WeakMap()) => {
  Object.keys(obj).forEach((key) => {
    target[key] = toRawDeep(obj[key], seen)
  })
}

/**
 * Synchronize states between the bundled and external/user versions of Vue
 * @param bundledState Reactive state created with the bundled Vue
 * @param externalState Reactive state created with the external/user Vue
 */
export function syncStateBundledAndExternal (bundledState, externalState) {
  let syncing = false

  const _stop = _watch(() => bundledState, value => {
    if (value == null) return
    if (!syncing) {
      syncing = true
      applyState(externalState, _toRawDeep(value))
    } else {
      syncing = false
    }
  }, {
    deep: true,
    immediate: true,
  })

  const stop = watch(() => externalState, value => {
    if (value == null) return
    if (!syncing) {
      syncing = true
      applyState(bundledState, toRawDeep(value))
    } else {
      syncing = false
    }
  }, {
    deep: true,
    immediate: true,
  })

  return {
    stop () {
      _stop()
      stop()
    },
  }
}
