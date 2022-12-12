/**
 * Wraps an arbitrary value in a Promise so that it can be awaited on
 */
export function asPromise<T>(value: T | PromiseLike<T>): Promise<T> {
  return Promise.resolve(value)
}
