import { __assign } from "tslib";
import { getCurrentHub, initAndBind, Integrations as CoreIntegrations } from '@sentry/core';
import { addInstrumentationHandler, getGlobalObject, logger, resolvedSyncPromise } from '@sentry/utils';
import { BrowserClient } from './client';
import { IS_DEBUG_BUILD } from './flags';
import { wrap as internalWrap } from './helpers';
import { Breadcrumbs, Dedupe, GlobalHandlers, LinkedErrors, TryCatch, UserAgent } from './integrations';
export var defaultIntegrations = [
    new CoreIntegrations.InboundFilters(),
    new CoreIntegrations.FunctionToString(),
    new TryCatch(),
    new Breadcrumbs(),
    new GlobalHandlers(),
    new LinkedErrors(),
    new Dedupe(),
    new UserAgent(),
];
/**
 * The Sentry Browser SDK Client.
 *
 * To use this SDK, call the {@link init} function as early as possible when
 * loading the web page. To set context information or send manual events, use
 * the provided methods.
 *
 * @example
 *
 * ```
 *
 * import { init } from '@sentry/browser';
 *
 * init({
 *   dsn: '__DSN__',
 *   // ...
 * });
 * ```
 *
 * @example
 * ```
 *
 * import { configureScope } from '@sentry/browser';
 * configureScope((scope: Scope) => {
 *   scope.setExtra({ battery: 0.7 });
 *   scope.setTag({ user_mode: 'admin' });
 *   scope.setUser({ id: '4711' });
 * });
 * ```
 *
 * @example
 * ```
 *
 * import { addBreadcrumb } from '@sentry/browser';
 * addBreadcrumb({
 *   message: 'My Breadcrumb',
 *   // ...
 * });
 * ```
 *
 * @example
 *
 * ```
 *
 * import * as Sentry from '@sentry/browser';
 * Sentry.captureMessage('Hello, world!');
 * Sentry.captureException(new Error('Good bye'));
 * Sentry.captureEvent({
 *   message: 'Manual',
 *   stacktrace: [
 *     // ...
 *   ],
 * });
 * ```
 *
 * @see {@link BrowserOptions} for documentation on configuration options.
 */
export function init(options) {
    if (options === void 0) { options = {}; }
    if (options.defaultIntegrations === undefined) {
        options.defaultIntegrations = defaultIntegrations;
    }
    if (options.release === undefined) {
        var window_1 = getGlobalObject();
        // This supports the variable that sentry-webpack-plugin injects
        if (window_1.SENTRY_RELEASE && window_1.SENTRY_RELEASE.id) {
            options.release = window_1.SENTRY_RELEASE.id;
        }
    }
    if (options.autoSessionTracking === undefined) {
        options.autoSessionTracking = true;
    }
    if (options.sendClientReports === undefined) {
        options.sendClientReports = true;
    }
    initAndBind(BrowserClient, options);
    if (options.autoSessionTracking) {
        startSessionTracking();
    }
}
/**
 * Present the user with a report dialog.
 *
 * @param options Everything is optional, we try to fetch all info need from the global scope.
 */
export function showReportDialog(options) {
    if (options === void 0) { options = {}; }
    var hub = getCurrentHub();
    var scope = hub.getScope();
    if (scope) {
        options.user = __assign(__assign({}, scope.getUser()), options.user);
    }
    if (!options.eventId) {
        options.eventId = hub.lastEventId();
    }
    var client = hub.getClient();
    if (client) {
        client.showReportDialog(options);
    }
}
/**
 * This is the getter for lastEventId.
 *
 * @returns The last event id of a captured event.
 */
export function lastEventId() {
    return getCurrentHub().lastEventId();
}
/**
 * This function is here to be API compatible with the loader.
 * @hidden
 */
export function forceLoad() {
    // Noop
}
/**
 * This function is here to be API compatible with the loader.
 * @hidden
 */
export function onLoad(callback) {
    callback();
}
/**
 * Call `flush()` on the current client, if there is one. See {@link Client.flush}.
 *
 * @param timeout Maximum time in ms the client should wait to flush its event queue. Omitting this parameter will cause
 * the client to wait until all events are sent before resolving the promise.
 * @returns A promise which resolves to `true` if the queue successfully drains before the timeout, or `false` if it
 * doesn't (or if there's no client defined).
 */
export function flush(timeout) {
    var client = getCurrentHub().getClient();
    if (client) {
        return client.flush(timeout);
    }
    IS_DEBUG_BUILD && logger.warn('Cannot flush events. No client defined.');
    return resolvedSyncPromise(false);
}
/**
 * Call `close()` on the current client, if there is one. See {@link Client.close}.
 *
 * @param timeout Maximum time in ms the client should wait to flush its event queue before shutting down. Omitting this
 * parameter will cause the client to wait until all events are sent before disabling itself.
 * @returns A promise which resolves to `true` if the queue successfully drains before the timeout, or `false` if it
 * doesn't (or if there's no client defined).
 */
export function close(timeout) {
    var client = getCurrentHub().getClient();
    if (client) {
        return client.close(timeout);
    }
    IS_DEBUG_BUILD && logger.warn('Cannot flush events and disable SDK. No client defined.');
    return resolvedSyncPromise(false);
}
/**
 * Wrap code within a try/catch block so the SDK is able to capture errors.
 *
 * @param fn A function to wrap.
 *
 * @returns The result of wrapped function call.
 */
// eslint-disable-next-line @typescript-eslint/no-explicit-any
export function wrap(fn) {
    return internalWrap(fn)();
}
function startSessionOnHub(hub) {
    hub.startSession({ ignoreDuration: true });
    hub.captureSession();
}
/**
 * Enable automatic Session Tracking for the initial page load.
 */
function startSessionTracking() {
    var window = getGlobalObject();
    var document = window.document;
    if (typeof document === 'undefined') {
        IS_DEBUG_BUILD && logger.warn('Session tracking in non-browser environment with @sentry/browser is not supported.');
        return;
    }
    var hub = getCurrentHub();
    // The only way for this to be false is for there to be a version mismatch between @sentry/browser (>= 6.0.0) and
    // @sentry/hub (< 5.27.0). In the simple case, there won't ever be such a mismatch, because the two packages are
    // pinned at the same version in package.json, but there are edge cases where it's possible. See
    // https://github.com/getsentry/sentry-javascript/issues/3207 and
    // https://github.com/getsentry/sentry-javascript/issues/3234 and
    // https://github.com/getsentry/sentry-javascript/issues/3278.
    if (!hub.captureSession) {
        return;
    }
    // The session duration for browser sessions does not track a meaningful
    // concept that can be used as a metric.
    // Automatically captured sessions are akin to page views, and thus we
    // discard their duration.
    startSessionOnHub(hub);
    // We want to create a session for every navigation as well
    addInstrumentationHandler('history', function (_a) {
        var from = _a.from, to = _a.to;
        // Don't create an additional session for the initial route or if the location did not change
        if (!(from === undefined || from === to)) {
            startSessionOnHub(getCurrentHub());
        }
    });
}
//# sourceMappingURL=sdk.js.map