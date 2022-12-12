import type { Plugin } from '../../core/plugin'
import type { SegmentEvent } from '../../core/events'
import type { Context } from '../../core/context'

export function isString(obj: unknown): obj is string {
  return typeof obj === 'string'
}

export function isNumber(obj: unknown): obj is number {
  return typeof obj === 'number'
}

export function isFunction(obj: unknown): obj is Function {
  return typeof obj === 'function'
}

export function isPlainObject(obj: unknown): obj is object {
  return (
    Object.prototype.toString.call(obj).slice(8, -1).toLowerCase() === 'object'
  )
}

function hasUser(event: SegmentEvent): boolean {
  const id =
    event.userId ?? event.anonymousId ?? event.groupId ?? event.previousId
  return isString(id)
}

class ValidationError extends Error {
  field: string

  constructor(field: string, message: string) {
    super(message)
    this.field = field
  }
}

function validate(ctx: Context): Context {
  const eventType: unknown = ctx && ctx.event && ctx.event.type
  const event = ctx.event

  if (event === undefined) {
    throw new ValidationError('event', 'Event is missing')
  }

  if (!isString(eventType)) {
    throw new ValidationError('event', 'Event is not a string')
  }

  if (eventType === 'track' && !isString(event.event)) {
    throw new ValidationError('event', 'Event is not a string')
  }

  const props = event.properties ?? event.traits
  if (eventType !== 'alias' && !isPlainObject(props)) {
    throw new ValidationError('properties', 'properties is not an object')
  }

  if (!hasUser(event)) {
    throw new ValidationError('userId', 'Missing userId or anonymousId')
  }

  return ctx
}

export const validation: Plugin = {
  name: 'Event Validation',
  type: 'before',
  version: '1.0.0',

  isLoaded: () => true,
  load: () => Promise.resolve(),

  track: validate,
  identify: validate,
  page: validate,
  alias: validate,
  group: validate,
  screen: validate,
}
