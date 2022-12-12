Object.defineProperty(exports, "__esModule", { value: true });
var utils_1 = require("@sentry/utils");
var flags_1 = require("./flags");
var hub_1 = require("./hub");
/**
 * @inheritdoc
 */
var SessionFlusher = /** @class */ (function () {
    function SessionFlusher(transport, attrs) {
        var _this = this;
        this.flushTimeout = 60;
        this._pendingAggregates = {};
        this._isEnabled = true;
        this._transport = transport;
        // Call to setInterval, so that flush is called every 60 seconds
        this._intervalId = setInterval(function () { return _this.flush(); }, this.flushTimeout * 1000);
        this._sessionAttrs = attrs;
    }
    /** Sends session aggregates to Transport */
    SessionFlusher.prototype.sendSessionAggregates = function (sessionAggregates) {
        if (!this._transport.sendSession) {
            flags_1.IS_DEBUG_BUILD && utils_1.logger.warn("Dropping session because custom transport doesn't implement sendSession");
            return;
        }
        void this._transport.sendSession(sessionAggregates).then(null, function (reason) {
            flags_1.IS_DEBUG_BUILD && utils_1.logger.error('Error while sending session:', reason);
        });
    };
    /** Checks if `pendingAggregates` has entries, and if it does flushes them by calling `sendSessions` */
    SessionFlusher.prototype.flush = function () {
        var sessionAggregates = this.getSessionAggregates();
        if (sessionAggregates.aggregates.length === 0) {
            return;
        }
        this._pendingAggregates = {};
        this.sendSessionAggregates(sessionAggregates);
    };
    /** Massages the entries in `pendingAggregates` and returns aggregated sessions */
    SessionFlusher.prototype.getSessionAggregates = function () {
        var _this = this;
        var aggregates = Object.keys(this._pendingAggregates).map(function (key) {
            return _this._pendingAggregates[parseInt(key)];
        });
        var sessionAggregates = {
            attrs: this._sessionAttrs,
            aggregates: aggregates,
        };
        return utils_1.dropUndefinedKeys(sessionAggregates);
    };
    /** JSDoc */
    SessionFlusher.prototype.close = function () {
        clearInterval(this._intervalId);
        this._isEnabled = false;
        this.flush();
    };
    /**
     * Wrapper function for _incrementSessionStatusCount that checks if the instance of SessionFlusher is enabled then
     * fetches the session status of the request from `Scope.getRequestSession().status` on the scope and passes them to
     * `_incrementSessionStatusCount` along with the start date
     */
    SessionFlusher.prototype.incrementSessionStatusCount = function () {
        if (!this._isEnabled) {
            return;
        }
        var scope = hub_1.getCurrentHub().getScope();
        var requestSession = scope && scope.getRequestSession();
        if (requestSession && requestSession.status) {
            this._incrementSessionStatusCount(requestSession.status, new Date());
            // This is not entirely necessarily but is added as a safe guard to indicate the bounds of a request and so in
            // case captureRequestSession is called more than once to prevent double count
            if (scope) {
                scope.setRequestSession(undefined);
            }
            /* eslint-enable @typescript-eslint/no-unsafe-member-access */
        }
    };
    /**
     * Increments status bucket in pendingAggregates buffer (internal state) corresponding to status of
     * the session received
     */
    SessionFlusher.prototype._incrementSessionStatusCount = function (status, date) {
        // Truncate minutes and seconds on Session Started attribute to have one minute bucket keys
        var sessionStartedTrunc = new Date(date).setSeconds(0, 0);
        this._pendingAggregates[sessionStartedTrunc] = this._pendingAggregates[sessionStartedTrunc] || {};
        // corresponds to aggregated sessions in one specific minute bucket
        // for example, {"started":"2021-03-16T08:00:00.000Z","exited":4, "errored": 1}
        var aggregationCounts = this._pendingAggregates[sessionStartedTrunc];
        if (!aggregationCounts.started) {
            aggregationCounts.started = new Date(sessionStartedTrunc).toISOString();
        }
        switch (status) {
            case 'errored':
                aggregationCounts.errored = (aggregationCounts.errored || 0) + 1;
                return aggregationCounts.errored;
            case 'ok':
                aggregationCounts.exited = (aggregationCounts.exited || 0) + 1;
                return aggregationCounts.exited;
            default:
                aggregationCounts.crashed = (aggregationCounts.crashed || 0) + 1;
                return aggregationCounts.crashed;
        }
    };
    return SessionFlusher;
}());
exports.SessionFlusher = SessionFlusher;
//# sourceMappingURL=sessionflusher.js.map