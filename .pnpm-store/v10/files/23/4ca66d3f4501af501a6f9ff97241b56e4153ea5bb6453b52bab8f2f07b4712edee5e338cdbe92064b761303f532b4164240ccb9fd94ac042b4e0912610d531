"use strict";
var __awaiter = (this && this.__awaiter) || function (thisArg, _arguments, P, generator) {
    function adopt(value) { return value instanceof P ? value : new P(function (resolve) { resolve(value); }); }
    return new (P || (P = Promise))(function (resolve, reject) {
        function fulfilled(value) { try { step(generator.next(value)); } catch (e) { reject(e); } }
        function rejected(value) { try { step(generator["throw"](value)); } catch (e) { reject(e); } }
        function step(result) { result.done ? resolve(result.value) : adopt(result.value).then(fulfilled, rejected); }
        step((generator = generator.apply(thisArg, _arguments || [])).next());
    });
};
var __generator = (this && this.__generator) || function (thisArg, body) {
    var _ = { label: 0, sent: function() { if (t[0] & 1) throw t[1]; return t[1]; }, trys: [], ops: [] }, f, y, t, g = Object.create((typeof Iterator === "function" ? Iterator : Object).prototype);
    return g.next = verb(0), g["throw"] = verb(1), g["return"] = verb(2), typeof Symbol === "function" && (g[Symbol.iterator] = function() { return this; }), g;
    function verb(n) { return function (v) { return step([n, v]); }; }
    function step(op) {
        if (f) throw new TypeError("Generator is already executing.");
        while (g && (g = 0, op[0] && (_ = 0)), _) try {
            if (f = 1, y && (t = op[0] & 2 ? y["return"] : op[0] ? y["throw"] || ((t = y["return"]) && t.call(y), 0) : y.next) && !(t = t.call(y, op[1])).done) return t;
            if (y = 0, t) op = [op[0] & 2, t.value];
            switch (op[0]) {
                case 0: case 1: t = op; break;
                case 4: _.label++; return { value: op[1], done: false };
                case 5: _.label++; y = op[1]; op = [0]; continue;
                case 7: op = _.ops.pop(); _.trys.pop(); continue;
                default:
                    if (!(t = _.trys, t = t.length > 0 && t[t.length - 1]) && (op[0] === 6 || op[0] === 2)) { _ = 0; continue; }
                    if (op[0] === 3 && (!t || (op[1] > t[0] && op[1] < t[3]))) { _.label = op[1]; break; }
                    if (op[0] === 6 && _.label < t[1]) { _.label = t[1]; t = op; break; }
                    if (t && _.label < t[2]) { _.label = t[2]; _.ops.push(op); break; }
                    if (t[2]) _.ops.pop();
                    _.trys.pop(); continue;
            }
            op = body.call(thisArg, _);
        } catch (e) { op = [6, e]; y = 0; } finally { f = t = 0; }
        if (op[0] & 5) throw op[1]; return { value: op[0] ? op[1] : void 0, done: true };
    }
};
Object.defineProperty(exports, "__esModule", { value: true });
var patch_1 = require("../extensions/replay/rrweb-plugins/patch");
var globals_1 = require("../utils/globals");
var constants_1 = require("../constants");
var core_1 = require("@posthog/core");
var addTracingHeaders = function (hostnames, distinctId, sessionManager, req) {
    var reqHostname;
    try {
        // we don't need to support IE11 here
        // eslint-disable-next-line compat/compat
        reqHostname = new URL(req.url).hostname;
    }
    catch (_a) {
        // If the URL is invalid, we skip adding tracing headers
        return;
    }
    if ((0, core_1.isArray)(hostnames) && !hostnames.includes(reqHostname)) {
        // Skip if the hostname is not in the list (also skip if hostnames is not an array,
        // because in the earliest version of this __add_tracing_headers was a bool)
        return;
    }
    if (sessionManager) {
        var _b = sessionManager.checkAndGetSessionAndWindowId(true), sessionId = _b.sessionId, windowId = _b.windowId;
        req.headers.set('X-POSTHOG-SESSION-ID', sessionId);
        req.headers.set('X-POSTHOG-WINDOW-ID', windowId);
    }
    if (distinctId !== constants_1.COOKIELESS_SENTINEL_VALUE) {
        req.headers.set('X-POSTHOG-DISTINCT-ID', distinctId);
    }
};
var patchFetch = function (hostnames, distinctId, sessionManager) {
    // eslint-disable-next-line @typescript-eslint/ban-ts-comment
    // @ts-ignore
    return (0, patch_1.patch)(globals_1.window, 'fetch', function (originalFetch) {
        return function (url, init) {
            return __awaiter(this, void 0, void 0, function () {
                var req;
                return __generator(this, function (_a) {
                    req = new Request(url, init);
                    addTracingHeaders(hostnames, distinctId, sessionManager, req);
                    return [2 /*return*/, originalFetch(req)];
                });
            });
        };
    });
};
var patchXHR = function (hostnames, distinctId, sessionManager) {
    return (0, patch_1.patch)(
    // we can assert this is present because we've checked previously
    globals_1.window.XMLHttpRequest.prototype, 'open', 
    // eslint-disable-next-line @typescript-eslint/ban-ts-comment
    // @ts-ignore
    function (originalOpen) {
        return function (method, url, async, username, password) {
            if (async === void 0) { async = true; }
            // because this function is returned in its actual context `this` _is_ an XMLHttpRequest
            // eslint-disable-next-line @typescript-eslint/ban-ts-comment
            // @ts-ignore
            var xhr = this;
            // check IE earlier than this, we only initialize if Request is present
            // eslint-disable-next-line compat/compat
            var req = new Request(url);
            addTracingHeaders(hostnames, distinctId, sessionManager, req);
            return originalOpen.call(xhr, method, req.url, async, username, password);
        };
    });
};
globals_1.assignableWindow.__PosthogExtensions__ = globals_1.assignableWindow.__PosthogExtensions__ || {};
var patchFns = {
    _patchFetch: patchFetch,
    _patchXHR: patchXHR,
};
globals_1.assignableWindow.__PosthogExtensions__.tracingHeadersPatchFns = patchFns;
// we used to put tracingHeadersPatchFns on window, and now we put it on __PosthogExtensions__
// but that means that old clients which lazily load this extension are looking in the wrong place
// yuck,
// so we also put it directly on the window
// when 1.161.1 is the oldest version seen in production we can remove this
globals_1.assignableWindow.postHogTracingHeadersPatchFns = patchFns;
exports.default = patchFns;
//# sourceMappingURL=tracing-headers.js.map