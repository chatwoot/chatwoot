Object.defineProperty(exports, "__esModule", { value: true });
var hub_1 = require("@sentry/hub");
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
var utils_1 = require("@sentry/utils");
exports.TRACEPARENT_REGEXP = utils_1.TRACEPARENT_REGEXP;
exports.extractTraceparentData = utils_1.extractTraceparentData;
/**
 * Determines if tracing is currently enabled.
 *
 * Tracing is enabled when at least one of `tracesSampleRate` and `tracesSampler` is defined in the SDK config.
 */
function hasTracingEnabled(maybeOptions) {
    var client = hub_1.getCurrentHub().getClient();
    var options = maybeOptions || (client && client.getOptions());
    return !!options && ('tracesSampleRate' in options || 'tracesSampler' in options);
}
exports.hasTracingEnabled = hasTracingEnabled;
/** Grabs active transaction off scope, if any */
function getActiveTransaction(maybeHub) {
    var hub = maybeHub || hub_1.getCurrentHub();
    var scope = hub.getScope();
    return scope && scope.getTransaction();
}
exports.getActiveTransaction = getActiveTransaction;
/**
 * Converts from milliseconds to seconds
 * @param time time in ms
 */
function msToSec(time) {
    return time / 1000;
}
exports.msToSec = msToSec;
/**
 * Converts from seconds to milliseconds
 * @param time time in seconds
 */
function secToMs(time) {
    return time * 1000;
}
exports.secToMs = secToMs;
// so it can be used in manual instrumentation without necessitating a hard dependency on @sentry/utils
var utils_2 = require("@sentry/utils");
exports.stripUrlQueryAndFragment = utils_2.stripUrlQueryAndFragment;
//# sourceMappingURL=utils.js.map