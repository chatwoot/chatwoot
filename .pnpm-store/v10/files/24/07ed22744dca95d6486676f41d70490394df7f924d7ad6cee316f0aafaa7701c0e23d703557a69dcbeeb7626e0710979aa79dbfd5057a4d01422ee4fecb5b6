"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.RequestRouter = exports.RequestRouterRegion = void 0;
/**
 * The request router helps simplify the logic to determine which endpoints should be called for which things
 * The basic idea is that for a given region (US or EU), we have a set of endpoints that we should call depending
 * on the type of request (events, replays, flags, etc.) and handle overrides that may come from configs or the flags endpoint
 */
var RequestRouterRegion;
(function (RequestRouterRegion) {
    RequestRouterRegion["US"] = "us";
    RequestRouterRegion["EU"] = "eu";
    RequestRouterRegion["CUSTOM"] = "custom";
})(RequestRouterRegion || (exports.RequestRouterRegion = RequestRouterRegion = {}));
var ingestionDomain = 'i.posthog.com';
var RequestRouter = /** @class */ (function () {
    function RequestRouter(instance) {
        this._regionCache = {};
        this.instance = instance;
    }
    Object.defineProperty(RequestRouter.prototype, "apiHost", {
        get: function () {
            var host = this.instance.config.api_host.trim().replace(/\/$/, '');
            if (host === 'https://app.posthog.com') {
                return 'https://us.i.posthog.com';
            }
            return host;
        },
        enumerable: false,
        configurable: true
    });
    Object.defineProperty(RequestRouter.prototype, "uiHost", {
        get: function () {
            var _a;
            var host = (_a = this.instance.config.ui_host) === null || _a === void 0 ? void 0 : _a.replace(/\/$/, '');
            if (!host) {
                // No ui_host set, get it from the api_host. But api_host differs
                // from the actual UI host, so replace the ingestion subdomain with just posthog.com
                host = this.apiHost.replace(".".concat(ingestionDomain), '.posthog.com');
            }
            if (host === 'https://app.posthog.com') {
                return 'https://us.posthog.com';
            }
            return host;
        },
        enumerable: false,
        configurable: true
    });
    Object.defineProperty(RequestRouter.prototype, "region", {
        get: function () {
            // We don't need to compute this every time so we cache the result
            if (!this._regionCache[this.apiHost]) {
                if (/https:\/\/(app|us|us-assets)(\.i)?\.posthog\.com/i.test(this.apiHost)) {
                    this._regionCache[this.apiHost] = RequestRouterRegion.US;
                }
                else if (/https:\/\/(eu|eu-assets)(\.i)?\.posthog\.com/i.test(this.apiHost)) {
                    this._regionCache[this.apiHost] = RequestRouterRegion.EU;
                }
                else {
                    this._regionCache[this.apiHost] = RequestRouterRegion.CUSTOM;
                }
            }
            return this._regionCache[this.apiHost];
        },
        enumerable: false,
        configurable: true
    });
    RequestRouter.prototype.endpointFor = function (target, path) {
        if (path === void 0) { path = ''; }
        if (path) {
            path = path[0] === '/' ? path : "/".concat(path);
        }
        if (target === 'ui') {
            return this.uiHost + path;
        }
        if (this.region === RequestRouterRegion.CUSTOM) {
            return this.apiHost + path;
        }
        var suffix = ingestionDomain + path;
        switch (target) {
            case 'assets':
                return "https://".concat(this.region, "-assets.").concat(suffix);
            case 'api':
                return "https://".concat(this.region, ".").concat(suffix);
        }
    };
    return RequestRouter;
}());
exports.RequestRouter = RequestRouter;
//# sourceMappingURL=request-router.js.map