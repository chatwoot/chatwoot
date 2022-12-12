Object.defineProperty(exports, "__esModule", { value: true });
var utils_1 = require("@sentry/utils");
exports.ERROR_TRANSPORT_CATEGORY = 'error';
exports.TRANSACTION_TRANSPORT_CATEGORY = 'transaction';
exports.ATTACHMENT_TRANSPORT_CATEGORY = 'attachment';
exports.SESSION_TRANSPORT_CATEGORY = 'session';
exports.DEFAULT_TRANSPORT_BUFFER_SIZE = 30;
/**
 * Creates a `NewTransport`
 *
 * @param options
 * @param makeRequest
 */
function createTransport(options, makeRequest, buffer) {
    if (buffer === void 0) { buffer = utils_1.makePromiseBuffer(options.bufferSize || exports.DEFAULT_TRANSPORT_BUFFER_SIZE); }
    var rateLimits = {};
    var flush = function (timeout) { return buffer.drain(timeout); };
    function send(envelope) {
        var envCategory = utils_1.getEnvelopeType(envelope);
        var category = envCategory === 'event' ? 'error' : envCategory;
        var request = {
            category: category,
            body: utils_1.serializeEnvelope(envelope),
        };
        // Don't add to buffer if transport is already rate-limited
        if (utils_1.isRateLimited(rateLimits, category)) {
            return utils_1.rejectedSyncPromise({
                status: 'rate_limit',
                reason: getRateLimitReason(rateLimits, category),
            });
        }
        var requestTask = function () {
            return makeRequest(request).then(function (_a) {
                var body = _a.body, headers = _a.headers, reason = _a.reason, statusCode = _a.statusCode;
                var status = utils_1.eventStatusFromHttpCode(statusCode);
                if (headers) {
                    rateLimits = utils_1.updateRateLimits(rateLimits, headers);
                }
                if (status === 'success') {
                    return utils_1.resolvedSyncPromise({ status: status, reason: reason });
                }
                return utils_1.rejectedSyncPromise({
                    status: status,
                    reason: reason ||
                        body ||
                        (status === 'rate_limit' ? getRateLimitReason(rateLimits, category) : 'Unknown transport error'),
                });
            });
        };
        return buffer.add(requestTask);
    }
    return {
        send: send,
        flush: flush,
    };
}
exports.createTransport = createTransport;
function getRateLimitReason(rateLimits, category) {
    return "Too many " + category + " requests, backing off until: " + new Date(utils_1.disabledUntil(rateLimits, category)).toISOString();
}
//# sourceMappingURL=base.js.map