"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
var globals_1 = require("../utils/globals");
var logger_1 = require("../utils/logger");
var logger = (0, logger_1.createLogger)('[ExternalScriptsLoader]');
var loadScript = function (posthog, url, callback) {
    if (posthog.config.disable_external_dependency_loading) {
        logger.warn("".concat(url, " was requested but loading of external scripts is disabled."));
        return callback('Loading of external scripts is disabled');
    }
    // If we add a script more than once then the browser will parse and execute it
    // So, even if idempotent we waste parsing and processing time
    var existingScripts = globals_1.document === null || globals_1.document === void 0 ? void 0 : globals_1.document.querySelectorAll('script');
    if (existingScripts) {
        for (var i = 0; i < existingScripts.length; i++) {
            if (existingScripts[i].src === url) {
                // Script already exists, we still call the callback, they have to be idempotent
                return callback();
            }
        }
    }
    var addScript = function () {
        var _a;
        if (!globals_1.document) {
            return callback('document not found');
        }
        var scriptTag = globals_1.document.createElement('script');
        scriptTag.type = 'text/javascript';
        scriptTag.crossOrigin = 'anonymous';
        scriptTag.src = url;
        scriptTag.onload = function (event) { return callback(undefined, event); };
        scriptTag.onerror = function (error) { return callback(error); };
        if (posthog.config.prepare_external_dependency_script) {
            scriptTag = posthog.config.prepare_external_dependency_script(scriptTag);
        }
        if (!scriptTag) {
            return callback('prepare_external_dependency_script returned null');
        }
        var scripts = globals_1.document.querySelectorAll('body > script');
        if (scripts.length > 0) {
            (_a = scripts[0].parentNode) === null || _a === void 0 ? void 0 : _a.insertBefore(scriptTag, scripts[0]);
        }
        else {
            // In exceptional situations this call might load before the DOM is fully ready.
            globals_1.document.body.appendChild(scriptTag);
        }
    };
    if (globals_1.document === null || globals_1.document === void 0 ? void 0 : globals_1.document.body) {
        addScript();
    }
    else {
        // Inlining this because we don't care about `passive: true` here
        // and this saves us ~3% of the bundle size
        // eslint-disable-next-line posthog-js/no-add-event-listener
        globals_1.document === null || globals_1.document === void 0 ? void 0 : globals_1.document.addEventListener('DOMContentLoaded', addScript);
    }
};
globals_1.assignableWindow.__PosthogExtensions__ = globals_1.assignableWindow.__PosthogExtensions__ || {};
globals_1.assignableWindow.__PosthogExtensions__.loadExternalDependency = function (posthog, kind, callback) {
    var scriptUrlToLoad = "/static/".concat(kind, ".js") + "?v=".concat(posthog.version);
    if (kind === 'remote-config') {
        scriptUrlToLoad = "/array/".concat(posthog.config.token, "/config.js");
    }
    if (kind === 'toolbar') {
        // toolbar.js is served from the PostHog CDN, this has a TTL of 24 hours.
        // the toolbar asset includes a rotating "token" that is valid for 5 minutes.
        var fiveMinutesInMillis = 5 * 60 * 1000;
        // this ensures that we bust the cache periodically
        var timestampToNearestFiveMinutes = Math.floor(Date.now() / fiveMinutesInMillis) * fiveMinutesInMillis;
        scriptUrlToLoad = "".concat(scriptUrlToLoad, "&t=").concat(timestampToNearestFiveMinutes);
    }
    var url = posthog.requestRouter.endpointFor('assets', scriptUrlToLoad);
    loadScript(posthog, url, callback);
};
globals_1.assignableWindow.__PosthogExtensions__.loadSiteApp = function (posthog, url, callback) {
    var scriptUrl = posthog.requestRouter.endpointFor('api', url);
    loadScript(posthog, scriptUrl, callback);
};
//# sourceMappingURL=external-scripts-loader.js.map