import { Context } from '../context'
import { asPromise } from '../../lib/as-promise'

export function pTimeout(
  cb: Promise<unknown>,
  timeout: number
): Promise<unknown> {
  return new Promise((resolve, reject) => {
    const timeoutId = setTimeout(() => {
      reject(Error('Promise timed out'))
    }, timeout)

    cb.then((val) => {
      clearTimeout(timeoutId)
      return resolve(val)
    }).catch(reject)
  })
}

export type Callback = (ctx: Context) => Promise<unknown> | unknown

export function invokeCallback(
  ctx: Context,
  callback?: Callback,
  timeout?: number
): Promise<Context> {
  if (!callback) {
    return Promise.resolve(ctx)
  }

  const cb = () => {
    try {
      return asPromise(callback(ctx))
    } catch (err) {
      return Promise.reject(err)
    }
  }

  return pTimeout(cb(), timeout ?? 1000)
    .catch((err) => {
      ctx?.log('warn', 'Callback Error', { error: err })
      ctx?.stats.increment('callback_error')
    })
    .then(() => ctx)
}
