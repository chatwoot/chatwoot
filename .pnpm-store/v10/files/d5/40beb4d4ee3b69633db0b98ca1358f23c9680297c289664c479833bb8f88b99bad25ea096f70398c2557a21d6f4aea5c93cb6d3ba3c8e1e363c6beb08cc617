"use strict";
var __values = (this && this.__values) || function(o) {
    var s = typeof Symbol === "function" && Symbol.iterator, m = s && o[s], i = 0;
    if (m) return m.call(o);
    if (o && typeof o.length === "number") return {
        next: function () {
            if (o && i >= o.length) o = void 0;
            return { value: o && o[i++], done: !o };
        }
    };
    throw new TypeError(s ? "Object is not iterable." : "Symbol.iterator is not defined.");
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.isHostOnDenyList = isHostOnDenyList;
function hostnameFromURL(url) {
    try {
        if (typeof url === 'string') {
            return new URL(url).hostname;
        }
        if ('url' in url) {
            return new URL(url.url).hostname;
        }
        return url.hostname;
    }
    catch (_a) {
        return null;
    }
}
function isHostOnDenyList(url, options) {
    var e_1, _a;
    var _b;
    var hostname = hostnameFromURL(url);
    var defaultNotDenied = { hostname: hostname, isHostDenied: false };
    if (!((_b = options.payloadHostDenyList) === null || _b === void 0 ? void 0 : _b.length) || !(hostname === null || hostname === void 0 ? void 0 : hostname.trim().length)) {
        return defaultNotDenied;
    }
    try {
        for (var _c = __values(options.payloadHostDenyList), _d = _c.next(); !_d.done; _d = _c.next()) {
            var deny = _d.value;
            if (hostname.endsWith(deny)) {
                return { hostname: hostname, isHostDenied: true };
            }
        }
    }
    catch (e_1_1) { e_1 = { error: e_1_1 }; }
    finally {
        try {
            if (_d && !_d.done && (_a = _c.return)) _a.call(_c);
        }
        finally { if (e_1) throw e_1.error; }
    }
    return defaultNotDenied;
}
//# sourceMappingURL=denylist.js.map