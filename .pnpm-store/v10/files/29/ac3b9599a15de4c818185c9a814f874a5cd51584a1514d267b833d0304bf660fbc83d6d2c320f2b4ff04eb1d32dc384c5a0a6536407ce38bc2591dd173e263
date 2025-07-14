/**
 * Return a promise that can be externally resolved
 */
export const createDeferred = <T>() => {
  let resolve!: (value: T | PromiseLike<T>) => void
  let reject!: (reason: any) => void
  const promise = new Promise<T>((_resolve, _reject) => {
    resolve = _resolve
    reject = _reject
  })
  return {
    resolve,
    reject,
    promise,
  }
}
