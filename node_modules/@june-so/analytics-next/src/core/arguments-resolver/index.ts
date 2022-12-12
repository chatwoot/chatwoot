import {
  isFunction,
  isPlainObject,
  isString,
  isNumber,
} from '../../plugins/validation'
import { Context } from '../context'
import { Options, SegmentEvent } from '../events'
import { ID, User } from '../user'

export type Callback = (ctx: Context | undefined) => Promise<unknown> | unknown

export function resolveArguments(
  eventName: string | SegmentEvent,
  properties?: object | Callback,
  options?: Options | Callback,
  callback?: Callback
): [string, object, Options, Callback | undefined] {
  const args = [eventName, properties, options, callback]

  const name = isPlainObject(eventName) ? eventName.event : eventName
  if (!name || !isString(name)) {
    throw new Error('Event missing')
  }

  const data = isPlainObject(eventName)
    ? eventName.properties ?? {}
    : isPlainObject(properties)
    ? properties
    : {}

  let opts = {}
  if (isPlainObject(properties) && !isFunction(options)) {
    opts = options ?? {}
  }

  if (isPlainObject(eventName) && !isFunction(properties)) {
    opts = properties ?? {}
  }

  const cb = args.find(isFunction) as Callback | undefined
  return [name, data, opts, cb]
}

export function resolvePageArguments(
  category?: string | object,
  name?: string | object | Callback,
  properties?: object | Options | Callback | null,
  options?: Options | Callback,
  callback?: Callback
): [string | null, string | null, object, Options, Callback | undefined] {
  let resolvedCategory: string | undefined | null = null
  let resolvedName: string | undefined | null = null
  const args = [category, name, properties, options, callback]

  const strings = args.filter(isString)
  if (strings[0] !== undefined && strings[1] !== undefined) {
    resolvedCategory = strings[0]
    resolvedName = strings[1]
  }

  if (strings.length === 1) {
    resolvedCategory = null
    resolvedName = strings[0]
  }

  const resolvedCallback = args.find(isFunction) as Callback | undefined

  const objects = args.filter((obj) => {
    if (resolvedName === null) {
      return isPlainObject(obj)
    }
    return isPlainObject(obj) || obj === null
  }) as Array<object | null>

  const resolvedProperties = objects[0] ?? {}
  const resolvedOptions = objects[1] ?? {}

  return [
    resolvedCategory,
    resolvedName,
    resolvedProperties,
    resolvedOptions,
    resolvedCallback,
  ]
}

export const resolveUserArguments = (user: User): ResolveUser => {
  return (...args): ReturnType<ResolveUser> => {
    let id: string | ID | null = null
    id = args.find(isString) ?? args.find(isNumber)?.toString() ?? user.id()

    const objects = args.filter((obj) => {
      if (id === null) {
        return isPlainObject(obj)
      }
      return isPlainObject(obj) || obj === null
    }) as Array<object | null>

    const data = objects[0] ?? {}
    const opts = objects[1] ?? {}

    const resolvedCallback = args.find(isFunction) as Callback | undefined

    return [id, data, opts, resolvedCallback]
  }
}

export function resolveAliasArguments(
  to: string | number,
  from?: string | number | Options,
  options?: Options | Callback,
  callback?: Callback
): [string, string | null, Options, Callback | undefined] {
  if (isNumber(to)) to = to.toString() // Legacy behaviour - allow integers for alias calls
  if (isNumber(from)) from = from.toString()
  const args = [to, from, options, callback]

  const [aliasTo = to, aliasFrom = null] = args.filter(isString)
  const [opts = {}] = args.filter(isPlainObject)
  const resolvedCallback = args.find(isFunction) as Callback | undefined

  return [aliasTo, aliasFrom, opts, resolvedCallback]
}

type ResolveUser = (
  id?: ID | object,
  traits?: object | Callback | null,
  options?: Options | Callback,
  callback?: Callback
) => [ID, object, Options, Callback | undefined]

export type UserParams = Parameters<ResolveUser>
export type EventParams = Parameters<typeof resolveArguments>
export type PageParams = Parameters<typeof resolvePageArguments>
export type AliasParams = Parameters<typeof resolveAliasArguments>

export type DispatchedEvent = Context
