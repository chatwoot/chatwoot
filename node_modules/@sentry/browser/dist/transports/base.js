Object.defineProperty(exports, "__esModule", { value: true });
var tslib_1 = require("tslib");
var core_1 = require("@sentry/core");
var utils_1 = require("@sentry/utils");
var flags_1 = require("../flags");
var utils_2 = require("./utils");
function requestTypeToCategory(ty) {
    var tyStr = ty;
    return tyStr === 'event' ? 'error' : tyStr;
}
var global = utils_1.getGlobalObject();
/** Base Transport class implementation */
var BaseTransport = /** @class */ (function () {
    function BaseTransport(options) {
        var _this = this;
        this.options = options;
        /** A simple buffer holding all requests. */
        this._buffer = utils_1.makePromiseBuffer(30);
        /** Locks transport after receiving rate limits in a response */
        this._rateLimits = {};
        this._outcomes = {};
        this._api = core_1.initAPIDetails(options.dsn, options._metadata, options.tunnel);
        // eslint-disable-next-line deprecation/deprecation
        this.url = core_1.getStoreEndpointWithUrlEncodedAuth(this._api.dsn);
        if (this.options.sendClientReports && global.document) {
            global.document.addEventListener('visibilitychange', function () {
                if (global.document.visibilityState === 'hidden') {
                    _this._flushOutcomes();
                }
            });
        }
    }
    /**
     * @inheritDoc
     */
    BaseTransport.prototype.sendEvent = function (event) {
        return this._sendRequest(core_1.eventToSentryRequest(event, this._api), event);
    };
    /**
     * @inheritDoc
     */
    BaseTransport.prototype.sendSession = function (session) {
        return this._sendRequest(core_1.sessionToSentryRequest(session, this._api), session);
    };
    /**
     * @inheritDoc
     */
    BaseTransport.prototype.close = function (timeout) {
        return this._buffer.drain(timeout);
    };
    /**
     * @inheritDoc
     */
    BaseTransport.prototype.recordLostEvent = function (reason, category) {
        var _a;
        if (!this.options.sendClientReports) {
            return;
        }
        // We want to track each category (event, transaction, session) separately
        // but still keep the distinction between different type of outcomes.
        // We could use nested maps, but it's much easier to read and type this way.
        // A correct type for map-based implementation if we want to go that route
        // would be `Partial<Record<SentryRequestType, Partial<Record<Outcome, number>>>>`
        var key = requestTypeToCategory(category) + ":" + reason;
        flags_1.IS_DEBUG_BUILD && utils_1.logger.log("Adding outcome: " + key);
        this._outcomes[key] = (_a = this._outcomes[key], (_a !== null && _a !== void 0 ? _a : 0)) + 1;
    };
    /**
     * Send outcomes as an envelope
     */
    BaseTransport.prototype._flushOutcomes = function () {
        if (!this.options.sendClientReports) {
            return;
        }
        var outcomes = this._outcomes;
        this._outcomes = {};
        // Nothing to send
        if (!Object.keys(outcomes).length) {
            flags_1.IS_DEBUG_BUILD && utils_1.logger.log('No outcomes to flush');
            return;
        }
        flags_1.IS_DEBUG_BUILD && utils_1.logger.log("Flushing outcomes:\n" + JSON.stringify(outcomes, null, 2));
        var url = core_1.getEnvelopeEndpointWithUrlEncodedAuth(this._api.dsn, this._api.tunnel);
        var discardedEvents = Object.keys(outcomes).map(function (key) {
            var _a = tslib_1.__read(key.split(':'), 2), category = _a[0], reason = _a[1];
            return {
                reason: reason,
                category: category,
                quantity: outcomes[key],
            };
            // TODO: Improve types on discarded_events to get rid of cast
        });
        var envelope = utils_1.createClientReportEnvelope(discardedEvents, this._api.tunnel && utils_1.dsnToString(this._api.dsn));
        try {
            utils_2.sendReport(url, utils_1.serializeEnvelope(envelope));
        }
        catch (e) {
            flags_1.IS_DEBUG_BUILD && utils_1.logger.error(e);
        }
    };
    /**
     * Handle Sentry repsonse for promise-based transports.
     */
    BaseTransport.prototype._handleResponse = function (_a) {
        var requestType = _a.requestType, response = _a.response, headers = _a.headers, resolve = _a.resolve, reject = _a.reject;
        var status = utils_1.eventStatusFromHttpCode(response.status);
        this._rateLimits = utils_1.updateRateLimits(this._rateLimits, headers);
        // eslint-disable-next-line deprecation/deprecation
        if (this._isRateLimited(requestType)) {
            flags_1.IS_DEBUG_BUILD &&
                // eslint-disable-next-line deprecation/deprecation
                utils_1.logger.warn("Too many " + requestType + " requests, backing off until: " + this._disabledUntil(requestType));
        }
        if (status === 'success') {
            resolve({ status: status });
            return;
        }
        reject(response);
    };
    /**
     * Gets the time that given category is disabled until for rate limiting
     *
     * @deprecated Please use `disabledUntil` from @sentry/utils
     */
    BaseTransport.prototype._disabledUntil = function (requestType) {
        var category = requestTypeToCategory(requestType);
        return new Date(utils_1.disabledUntil(this._rateLimits, category));
    };
    /**
     * Checks if a category is rate limited
     *
     * @deprecated Please use `isRateLimited` from @sentry/utils
     */
    BaseTransport.prototype._isRateLimited = function (requestType) {
        var category = requestTypeToCategory(requestType);
        return utils_1.isRateLimited(this._rateLimits, category);
    };
    return BaseTransport;
}());
exports.BaseTransport = BaseTransport;
//# sourceMappingURL=base.js.map