Object.defineProperty(exports, "__esModule", { value: true });
var tslib_1 = require("tslib");
exports.DEFAULT_RETRY_AFTER = 60 * 1000; // 60 seconds
/**
 * Extracts Retry-After value from the request header or returns default value
 * @param header string representation of 'Retry-After' header
 * @param now current unix timestamp
 *
 */
function parseRetryAfterHeader(header, now) {
    if (now === void 0) { now = Date.now(); }
    var headerDelay = parseInt("" + header, 10);
    if (!isNaN(headerDelay)) {
        return headerDelay * 1000;
    }
    var headerDate = Date.parse("" + header);
    if (!isNaN(headerDate)) {
        return headerDate - now;
    }
    return exports.DEFAULT_RETRY_AFTER;
}
exports.parseRetryAfterHeader = parseRetryAfterHeader;
/**
 * Gets the time that given category is disabled until for rate limiting
 */
function disabledUntil(limits, category) {
    return limits[category] || limits.all || 0;
}
exports.disabledUntil = disabledUntil;
/**
 * Checks if a category is rate limited
 */
function isRateLimited(limits, category, now) {
    if (now === void 0) { now = Date.now(); }
    return disabledUntil(limits, category) > now;
}
exports.isRateLimited = isRateLimited;
/**
 * Update ratelimits from incoming headers.
 * Returns true if headers contains a non-empty rate limiting header.
 */
function updateRateLimits(limits, headers, now) {
    var e_1, _a, e_2, _b;
    if (now === void 0) { now = Date.now(); }
    var updatedRateLimits = tslib_1.__assign({}, limits);
    // "The name is case-insensitive."
    // https://developer.mozilla.org/en-US/docs/Web/API/Headers/get
    var rateLimitHeader = headers['x-sentry-rate-limits'];
    var retryAfterHeader = headers['retry-after'];
    if (rateLimitHeader) {
        try {
            /**
             * rate limit headers are of the form
             *     <header>,<header>,..
             * where each <header> is of the form
             *     <retry_after>: <categories>: <scope>: <reason_code>
             * where
             *     <retry_after> is a delay in seconds
             *     <categories> is the event type(s) (error, transaction, etc) being rate limited and is of the form
             *         <category>;<category>;...
             *     <scope> is what's being limited (org, project, or key) - ignored by SDK
             *     <reason_code> is an arbitrary string like "org_quota" - ignored by SDK
             */
            for (var _c = tslib_1.__values(rateLimitHeader.trim().split(',')), _d = _c.next(); !_d.done; _d = _c.next()) {
                var limit = _d.value;
                var parameters = limit.split(':', 2);
                var headerDelay = parseInt(parameters[0], 10);
                var delay = (!isNaN(headerDelay) ? headerDelay : 60) * 1000; // 60sec default
                if (!parameters[1]) {
                    updatedRateLimits.all = now + delay;
                }
                else {
                    try {
                        for (var _e = (e_2 = void 0, tslib_1.__values(parameters[1].split(';'))), _f = _e.next(); !_f.done; _f = _e.next()) {
                            var category = _f.value;
                            updatedRateLimits[category] = now + delay;
                        }
                    }
                    catch (e_2_1) { e_2 = { error: e_2_1 }; }
                    finally {
                        try {
                            if (_f && !_f.done && (_b = _e.return)) _b.call(_e);
                        }
                        finally { if (e_2) throw e_2.error; }
                    }
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
    }
    else if (retryAfterHeader) {
        updatedRateLimits.all = now + parseRetryAfterHeader(retryAfterHeader, now);
    }
    return updatedRateLimits;
}
exports.updateRateLimits = updateRateLimits;
//# sourceMappingURL=ratelimit.js.map