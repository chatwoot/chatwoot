import { Hub } from '@sentry/hub';
import { Options, Transaction } from '@sentry/types';
/**
 * The `extractTraceparentData` function and `TRACEPARENT_REGEXP` constant used
 * to be declared in this file. It was later moved into `@sentry/utils` as part of a
 * move to remove `@sentry/tracing` dependencies from `@sentry/node` (`extractTraceparentData`
 * is the only tracing function used by `@sentry/node`).
 *
 * These exports are kept here for backwards compatability's sake.
 *
 * TODO(v7): Reorganize these exports
 *
 * See https://github.com/getsentry/sentry-javascript/issues/4642 for more details.
 */
export { TRACEPARENT_REGEXP, extractTraceparentData } from '@sentry/utils';
/**
 * Determines if tracing is currently enabled.
 *
 * Tracing is enabled when at least one of `tracesSampleRate` and `tracesSampler` is defined in the SDK config.
 */
export declare function hasTracingEnabled(maybeOptions?: Options | undefined): boolean;
/** Grabs active transaction off scope, if any */
export declare function getActiveTransaction<T extends Transaction>(maybeHub?: Hub): T | undefined;
/**
 * Converts from milliseconds to seconds
 * @param time time in ms
 */
export declare function msToSec(time: number): number;
/**
 * Converts from seconds to milliseconds
 * @param time time in seconds
 */
export declare function secToMs(time: number): number;
export { stripUrlQueryAndFragment } from '@sentry/utils';
//# sourceMappingURL=utils.d.ts.map