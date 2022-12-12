import { __assign } from "tslib";
export * from './exports';
import { Integrations as CoreIntegrations } from '@sentry/core';
import { getGlobalObject } from '@sentry/utils';
import * as BrowserIntegrations from './integrations';
import * as Transports from './transports';
var windowIntegrations = {};
// This block is needed to add compatibility with the integrations packages when used with a CDN
var _window = getGlobalObject();
if (_window.Sentry && _window.Sentry.Integrations) {
    windowIntegrations = _window.Sentry.Integrations;
}
var INTEGRATIONS = __assign(__assign(__assign({}, windowIntegrations), CoreIntegrations), BrowserIntegrations);
export { INTEGRATIONS as Integrations, Transports };
//# sourceMappingURL=index.js.map