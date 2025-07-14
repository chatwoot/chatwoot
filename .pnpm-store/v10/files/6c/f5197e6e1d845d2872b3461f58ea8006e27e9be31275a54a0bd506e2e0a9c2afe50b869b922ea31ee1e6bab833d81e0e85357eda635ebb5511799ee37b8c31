import { CoreSegmentEvent } from '../events'

export function isString(obj: unknown): obj is string {
  return typeof obj === 'string'
}

export function isNumber(obj: unknown): obj is number {
  return typeof obj === 'number'
}

export function isFunction(obj: unknown): obj is Function {
  return typeof obj === 'function'
}

export function isPlainObject(
  obj: unknown
): obj is Record<string | symbol | number, any> {
  return (
    Object.prototype.toString.call(obj).slice(8, -1).toLowerCase() === 'object'
  )
}

export function hasUser(event: CoreSegmentEvent): boolean {
  const id =
    event.userId ?? event.anonymousId ?? event.groupId ?? event.previousId
  return isString(id)
}
