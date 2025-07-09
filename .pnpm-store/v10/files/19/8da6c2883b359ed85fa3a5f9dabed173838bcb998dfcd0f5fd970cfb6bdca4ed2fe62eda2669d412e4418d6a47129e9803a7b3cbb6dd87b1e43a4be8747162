"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.queryString = void 0;
var pickPrefix_1 = require("./pickPrefix");
var gracefulDecodeURIComponent_1 = require("./gracefulDecodeURIComponent");
var analytics_core_1 = require("@segment/analytics-core");
function queryString(analytics, query) {
    var a = document.createElement('a');
    a.href = query;
    var parsed = a.search.slice(1);
    var params = parsed.split('&').reduce(function (acc, str) {
        var _a = str.split('='), k = _a[0], v = _a[1];
        acc[k] = (0, gracefulDecodeURIComponent_1.gracefulDecodeURIComponent)(v);
        return acc;
    }, {});
    var calls = [];
    var ajs_uid = params.ajs_uid, ajs_event = params.ajs_event, ajs_aid = params.ajs_aid;
    var _a = (0, analytics_core_1.isPlainObject)(analytics.options.useQueryString)
        ? analytics.options.useQueryString
        : {}, _b = _a.aid, aidPattern = _b === void 0 ? /.+/ : _b, _c = _a.uid, uidPattern = _c === void 0 ? /.+/ : _c;
    if (ajs_aid) {
        var anonId = Array.isArray(params.ajs_aid)
            ? params.ajs_aid[0]
            : params.ajs_aid;
        if (aidPattern.test(anonId)) {
            analytics.setAnonymousId(anonId);
        }
    }
    if (ajs_uid) {
        var uid = Array.isArray(params.ajs_uid)
            ? params.ajs_uid[0]
            : params.ajs_uid;
        if (uidPattern.test(uid)) {
            var traits = (0, pickPrefix_1.pickPrefix)('ajs_trait_', params);
            calls.push(analytics.identify(uid, traits));
        }
    }
    if (ajs_event) {
        var event_1 = Array.isArray(params.ajs_event)
            ? params.ajs_event[0]
            : params.ajs_event;
        var props = (0, pickPrefix_1.pickPrefix)('ajs_prop_', params);
        calls.push(analytics.track(event_1, props));
    }
    return Promise.all(calls);
}
exports.queryString = queryString;
//# sourceMappingURL=index.js.map