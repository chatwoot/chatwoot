Object.defineProperty(exports, "__esModule", { value: true });
var tslib_1 = require("tslib");
tslib_1.__exportStar(require("./exports"), exports);
var core_1 = require("@sentry/core");
var utils_1 = require("@sentry/utils");
var BrowserIntegrations = require("./integrations");
var Transports = require("./transports");
exports.Transports = Transports;
var windowIntegrations = {};
// This block is needed to add compatibility with the integrations packages when used with a CDN
var _window = utils_1.getGlobalObject();
if (_window.Sentry && _window.Sentry.Integrations) {
    windowIntegrations = _window.Sentry.Integrations;
}
var INTEGRATIONS = tslib_1.__assign(tslib_1.__assign(tslib_1.__assign({}, windowIntegrations), core_1.Integrations), BrowserIntegrations);
exports.Integrations = INTEGRATIONS;
//# sourceMappingURL=index.js.map