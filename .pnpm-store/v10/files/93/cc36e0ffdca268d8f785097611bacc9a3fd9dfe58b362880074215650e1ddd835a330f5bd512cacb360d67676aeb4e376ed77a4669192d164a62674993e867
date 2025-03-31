import type { Mechanism, WrappedFunction } from '@sentry/types';
export declare const WINDOW: import("@sentry/utils").InternalGlobal & Window;
/**
 * @hidden
 */
export declare function shouldIgnoreOnError(): boolean;
/**
 * @hidden
 */
export declare function ignoreNextOnError(): void;
/**
 * Instruments the given function and sends an event to Sentry every time the
 * function throws an exception.
 *
 * @param fn A function to wrap. It is generally safe to pass an unbound function, because the returned wrapper always
 * has a correct `this` context.
 * @returns The wrapped function.
 * @hidden
 */
export declare function wrap(fn: WrappedFunction, options?: {
    mechanism?: Mechanism;
}, before?: WrappedFunction): any;
//# sourceMappingURL=helpers.d.ts.map