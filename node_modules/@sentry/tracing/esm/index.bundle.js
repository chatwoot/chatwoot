import { __assign } from "tslib";
export { Severity, } from '@sentry/types';
export { addGlobalEventProcessor, addBreadcrumb, captureException, captureEvent, captureMessage, configureScope, getHubFromCarrier, getCurrentHub, Hub, Scope, setContext, setExtra, setExtras, setTag, setTags, setUser, startTransaction, Transports, withScope, } from '@sentry/browser';
export { BrowserClient } from '@sentry/browser';
export { defaultIntegrations, forceLoad, init, lastEventId, onLoad, showReportDialog, flush, close, wrap, } from '@sentry/browser';
export { SDK_NAME, SDK_VERSION } from '@sentry/browser';
import { Integrations as BrowserIntegrations } from '@sentry/browser';
import { getGlobalObject } from '@sentry/utils';
import { BrowserTracing } from './browser';
import { addExtensionMethods } from './hubextensions';
export { Span } from './span';
var windowIntegrations = {};
// This block is needed to add compatibility with the integrations packages when used with a CDN
var _window = getGlobalObject();
if (_window.Sentry && _window.Sentry.Integrations) {
    windowIntegrations = _window.Sentry.Integrations;
}
var INTEGRATIONS = __assign(__assign(__assign({}, windowIntegrations), BrowserIntegrations), { BrowserTracing: BrowserTracing });
export { INTEGRATIONS as Integrations };
// Though in this case exporting this separately in addition to exporting it as part of `Sentry.Integrations` doesn't
// gain us any bundle size advantage (we're making the bundle here, not the user, and we can't leave anything out of
// ours), it does bring the API for using the integration in line with that recommended for users bundling Sentry
// themselves.
export { BrowserTracing };
// We are patching the global object with our hub extension methods
addExtensionMethods();
export { addExtensionMethods };
//# sourceMappingURL=index.bundle.js.map