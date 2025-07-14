import { Analytics } from '../analytics'
import { Context } from '../context'
import { isThenable } from '../../lib/is-thenable'
import { AnalyticsBrowserCore } from '../analytics/interfaces'
import { version } from '../../generated/version'

/**
 * The names of any AnalyticsBrowser methods that also exist on Analytics
 */
export type PreInitMethodName =
  | 'screen'
  | 'register'
  | 'deregister'
  | 'user'
  | 'trackSubmit'
  | 'trackClick'
  | 'trackLink'
  | 'trackForm'
  | 'pageview'
  | 'identify'
  | 'reset'
  | 'group'
  | 'track'
  | 'ready'
  | 'alias'
  | 'debug'
  | 'page'
  | 'once'
  | 'off'
  | 'on'
  | 'addSourceMiddleware'
  | 'setAnonymousId'
  | 'addDestinationMiddleware'

// Union of all analytics methods that _do not_ return a Promise
type SyncPreInitMethodName = {
  [MethodName in PreInitMethodName]: ReturnType<
    Analytics[MethodName]
  > extends Promise<any>
    ? never
    : MethodName
}[PreInitMethodName]

const flushSyncAnalyticsCalls = (
  name: SyncPreInitMethodName,
  analytics: Analytics,
  buffer: PreInitMethodCallBuffer
): void => {
  buffer.getCalls(name).forEach((c) => {
    // While the underlying methods are synchronous, the callAnalyticsMethod returns a promise,
    // which normalizes success and error states between async and non-async methods, with no perf penalty.
    callAnalyticsMethod(analytics, c).catch(console.error)
  })
}

export const flushAddSourceMiddleware = async (
  analytics: Analytics,
  buffer: PreInitMethodCallBuffer
) => {
  for (const c of buffer.getCalls('addSourceMiddleware')) {
    await callAnalyticsMethod(analytics, c).catch(console.error)
  }
}

export const flushOn = flushSyncAnalyticsCalls.bind(this, 'on')

export const flushSetAnonymousID = flushSyncAnalyticsCalls.bind(
  this,
  'setAnonymousId'
)

export const flushAnalyticsCallsInNewTask = (
  analytics: Analytics,
  buffer: PreInitMethodCallBuffer
): void => {
  buffer.toArray().forEach((m) => {
    setTimeout(() => {
      callAnalyticsMethod(analytics, m).catch(console.error)
    }, 0)
  })
}

/**
 *  Represents a buffered method call that occurred before initialization.
 */
export interface PreInitMethodCall<
  MethodName extends PreInitMethodName = PreInitMethodName
> {
  method: MethodName
  args: PreInitMethodParams<MethodName>
  called: boolean
  resolve: (v: ReturnType<Analytics[MethodName]>) => void
  reject: (reason: any) => void
}

export type PreInitMethodParams<MethodName extends PreInitMethodName> =
  Parameters<Analytics[MethodName]>

/**
 * Infer return type; if return type is promise, unwrap it.
 */
type ReturnTypeUnwrap<Fn> = Fn extends (...args: any[]) => infer ReturnT
  ? ReturnT extends PromiseLike<infer Unwrapped>
    ? Unwrapped
    : ReturnT
  : never

type MethodCallMap = Partial<Record<PreInitMethodName, PreInitMethodCall[]>>

/**
 *  Represents any and all the buffered method calls that occurred before initialization.
 */
export class PreInitMethodCallBuffer {
  private _value = {} as MethodCallMap

  toArray(): PreInitMethodCall[] {
    return ([] as PreInitMethodCall[]).concat(...Object.values(this._value))
  }

  getCalls<T extends PreInitMethodName>(methodName: T): PreInitMethodCall<T>[] {
    return (this._value[methodName] ?? []) as PreInitMethodCall<T>[]
  }

  push(...calls: PreInitMethodCall[]): PreInitMethodCallBuffer {
    calls.forEach((call) => {
      if (this._value[call.method]) {
        this._value[call.method]!.push(call)
      } else {
        this._value[call.method] = [call]
      }
    })
    return this
  }

  clear(): PreInitMethodCallBuffer {
    this._value = {} as MethodCallMap
    return this
  }
}

/**
 *  Call method and mark as "called"
 *  This function should never throw an error
 */
export async function callAnalyticsMethod<T extends PreInitMethodName>(
  analytics: Analytics,
  call: PreInitMethodCall<T>
): Promise<void> {
  try {
    if (call.called) {
      return undefined
    }
    call.called = true

    const result: ReturnType<Analytics[T]> = (
      analytics[call.method] as Function
    )(...call.args)

    if (isThenable(result)) {
      // do not defer for non-async methods
      await result
    }

    call.resolve(result)
  } catch (err) {
    call.reject(err)
  }
}

export type AnalyticsLoader = (
  preInitBuffer: PreInitMethodCallBuffer
) => Promise<[Analytics, Context]>

export class AnalyticsBuffered
  implements PromiseLike<[Analytics, Context]>, AnalyticsBrowserCore
{
  instance?: Analytics
  ctx?: Context
  private _preInitBuffer = new PreInitMethodCallBuffer()
  private _promise: Promise<[Analytics, Context]>
  constructor(loader: AnalyticsLoader) {
    this._promise = loader(this._preInitBuffer)
    this._promise
      .then(([ajs, ctx]) => {
        this.instance = ajs
        this.ctx = ctx
      })
      .catch(() => {
        // intentionally do nothing...
        // this result of this promise will be caught by the 'catch' block on this class.
      })
  }

  then<T1, T2 = never>(
    ...args: [
      onfulfilled:
        | ((instance: [Analytics, Context]) => T1 | PromiseLike<T1>)
        | null
        | undefined,
      onrejected?: (reason: unknown) => T2 | PromiseLike<T2>
    ]
  ) {
    return this._promise.then(...args)
  }

  catch<TResult = never>(
    ...args: [
      onrejected?:
        | ((reason: any) => TResult | PromiseLike<TResult>)
        | undefined
        | null
    ]
  ) {
    return this._promise.catch(...args)
  }

  finally(...args: [onfinally?: (() => void) | undefined | null]) {
    return this._promise.finally(...args)
  }

  trackSubmit = this._createMethod('trackSubmit')
  trackClick = this._createMethod('trackClick')
  trackLink = this._createMethod('trackLink')
  pageView = this._createMethod('pageview')
  identify = this._createMethod('identify')
  reset = this._createMethod('reset')
  group = this._createMethod('group') as AnalyticsBrowserCore['group']
  track = this._createMethod('track')
  ready = this._createMethod('ready')
  alias = this._createMethod('alias')
  debug = this._createChainableMethod('debug')
  page = this._createMethod('page')
  once = this._createChainableMethod('once')
  off = this._createChainableMethod('off')
  on = this._createChainableMethod('on')
  addSourceMiddleware = this._createMethod('addSourceMiddleware')
  setAnonymousId = this._createMethod('setAnonymousId')
  addDestinationMiddleware = this._createMethod('addDestinationMiddleware')

  screen = this._createMethod('screen')
  register = this._createMethod('register')
  deregister = this._createMethod('deregister')
  user = this._createMethod('user')
  readonly VERSION = version

  private _createMethod<T extends PreInitMethodName>(methodName: T) {
    return (
      ...args: Parameters<Analytics[T]>
    ): Promise<ReturnTypeUnwrap<Analytics[T]>> => {
      if (this.instance) {
        const result = (this.instance[methodName] as Function)(...args)
        return Promise.resolve(result)
      }

      return new Promise((resolve, reject) => {
        this._preInitBuffer.push({
          method: methodName,
          args,
          resolve: resolve,
          reject: reject,
          called: false,
        } as PreInitMethodCall)
      })
    }
  }

  /**
   *  These are for methods that where determining when the method gets "flushed" is not important.
   *  These methods will resolve when analytics is fully initialized, and return type (other than Analytics)will not be available.
   */
  private _createChainableMethod<T extends PreInitMethodName>(methodName: T) {
    return (...args: Parameters<Analytics[T]>): AnalyticsBuffered => {
      if (this.instance) {
        void (this.instance[methodName] as Function)(...args)
        return this
      } else {
        this._preInitBuffer.push({
          method: methodName,
          args,
          resolve: () => {},
          reject: console.error,
          called: false,
        } as PreInitMethodCall)
      }

      return this
    }
  }
}
