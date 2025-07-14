/**
 * Wrap a callback function with error handling.
 * If an error is thrown, it will be passed to the `onError` callback and re-thrown.
 *
 * If the return value of the function is a promise, it will be handled with `maybeHandlePromiseRejection`.
 *
 * If an `onFinally` callback is provided, this will be called when the callback has finished
 * - so if it returns a promise, once the promise resolved/rejected,
 * else once the callback has finished executing.
 * The `onFinally` callback will _always_ be called, no matter if an error was thrown or not.
 */
export declare function handleCallbackErrors<Fn extends () => any>(fn: Fn, onError: (error: unknown) => void, onFinally?: () => void): ReturnType<Fn>;
//# sourceMappingURL=handleCallbackErrors.d.ts.map
