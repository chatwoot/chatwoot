import { CoreSegmentEvent } from '../events'
import { hasUser, isString, isPlainObject } from './helpers'

export class ValidationError extends Error {
  field: string

  constructor(field: string, message: string) {
    super(message)
    this.field = field
  }
}

export function validateEvent(event?: CoreSegmentEvent | null) {
  if (!event || typeof event !== 'object') {
    throw new ValidationError('event', 'Event is missing')
  }

  if (!isString(event.type)) {
    throw new ValidationError('type', 'type is not a string')
  }

  if (event.type === 'track') {
    if (!isString(event.event)) {
      throw new ValidationError('event', 'Event is not a string')
    }
    if (!isPlainObject(event.properties)) {
      throw new ValidationError('properties', 'properties is not an object')
    }
  }

  if (['group', 'identify'].includes(event.type)) {
    if (!isPlainObject(event.traits)) {
      throw new ValidationError('traits', 'traits is not an object')
    }
  }

  if (!hasUser(event)) {
    throw new ValidationError(
      'userId/anonymousId/previousId/groupId',
      'Must have userId or anonymousId or previousId or groupId'
    )
  }
}
