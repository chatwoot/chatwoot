import { __assign } from "tslib";
export { BrowserClient, defaultIntegrations, forceLoad, lastEventId, onLoad, showReportDialog, flush, close, wrap, addGlobalEventProcessor, addBreadcrumb, captureException, captureEvent, captureMessage, configureScope, getHubFromCarrier, getCurrentHub, Hub, Scope, setContext, setExtra, setExtras, setTag, setTags, setUser, startTransaction, Transports, withScope, SDK_NAME, SDK_VERSION, } from '@sentry/browser';
import { Integrations as BrowserIntegrations } from '@sentry/browser';
import { getGlobalObject } from '@sentry/utils';
export { init } from './sdk';
export { vueRouterInstrumentation } from './router';
export { attachErrorHandler } from './errorhandler';
export { createTracingMixins } from './tracing';
var windowIntegrations = {};
// This block is needed to add compatibility with the integrations packages when used with a CDN
var _window = getGlobalObject();
if (_window.Sentry && _window.Sentry.Integrations) {
    windowIntegrations = _window.Sentry.Integrations;
}
var INTEGRATIONS = __assign(__assign({}, windowIntegrations), BrowserIntegrations);
export { INTEGRATIONS as Integrations };
//# sourceMappingURL=index.bundle.js.map