"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.RateLimiter = void 0;
var constants_1 = require("./constants");
var logger_1 = require("./utils/logger");
var logger = (0, logger_1.createLogger)('[RateLimiter]');
var ONE_MINUTE_IN_MILLISECONDS = 60 * 1000;
var RATE_LIMIT_EVENT = '$$client_ingestion_warning';
var RateLimiter = /** @class */ (function () {
    function RateLimiter(instance) {
        var _this = this;
        var _a, _b;
        this.serverLimits = {};
        this.lastEventRateLimited = false;
        this.checkForLimiting = function (httpResponse) {
            var text = httpResponse.text;
            if (!text || !text.length) {
                return;
            }
            try {
                var response = JSON.parse(text);
                var quotaLimitedProducts = response.quota_limited || [];
                quotaLimitedProducts.forEach(function (batchKey) {
                    logger.info("".concat(batchKey || 'events', " is quota limited."));
                    _this.serverLimits[batchKey] = new Date().getTime() + ONE_MINUTE_IN_MILLISECONDS;
                });
            }
            catch (e) {
                logger.warn("could not rate limit - continuing. Error: \"".concat(e === null || e === void 0 ? void 0 : e.message, "\""), { text: text });
                return;
            }
        };
        this.instance = instance;
        this.captureEventsPerSecond = ((_a = instance.config.rate_limiting) === null || _a === void 0 ? void 0 : _a.events_per_second) || 10;
        this.captureEventsBurstLimit = Math.max(((_b = instance.config.rate_limiting) === null || _b === void 0 ? void 0 : _b.events_burst_limit) || this.captureEventsPerSecond * 10, this.captureEventsPerSecond);
        this.lastEventRateLimited = this.clientRateLimitContext(true).isRateLimited;
    }
    RateLimiter.prototype.clientRateLimitContext = function (checkOnly) {
        var _a, _b, _c;
        if (checkOnly === void 0) { checkOnly = false; }
        // This is primarily to prevent runaway loops from flooding capture with millions of events for a single user.
        // It's as much for our protection as theirs.
        var now = new Date().getTime();
        var bucket = (_b = (_a = this.instance.persistence) === null || _a === void 0 ? void 0 : _a.get_property(constants_1.CAPTURE_RATE_LIMIT)) !== null && _b !== void 0 ? _b : {
            tokens: this.captureEventsBurstLimit,
            last: now,
        };
        bucket.tokens += ((now - bucket.last) / 1000) * this.captureEventsPerSecond;
        bucket.last = now;
        if (bucket.tokens > this.captureEventsBurstLimit) {
            bucket.tokens = this.captureEventsBurstLimit;
        }
        var isRateLimited = bucket.tokens < 1;
        if (!isRateLimited && !checkOnly) {
            bucket.tokens = Math.max(0, bucket.tokens - 1);
        }
        if (isRateLimited && !this.lastEventRateLimited && !checkOnly) {
            this.instance.capture(RATE_LIMIT_EVENT, {
                $$client_ingestion_warning_message: "posthog-js client rate limited. Config is set to ".concat(this.captureEventsPerSecond, " events per second and ").concat(this.captureEventsBurstLimit, " events burst limit."),
            }, {
                skip_client_rate_limiting: true,
            });
        }
        this.lastEventRateLimited = isRateLimited;
        (_c = this.instance.persistence) === null || _c === void 0 ? void 0 : _c.set_property(constants_1.CAPTURE_RATE_LIMIT, bucket);
        return {
            isRateLimited: isRateLimited,
            remainingTokens: bucket.tokens,
        };
    };
    RateLimiter.prototype.isServerRateLimited = function (batchKey) {
        var retryAfter = this.serverLimits[batchKey || 'events'] || false;
        if (retryAfter === false) {
            return false;
        }
        return new Date().getTime() < retryAfter;
    };
    return RateLimiter;
}());
exports.RateLimiter = RateLimiter;
//# sourceMappingURL=rate-limiter.js.map