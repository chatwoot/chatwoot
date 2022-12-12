import { disabledUntil, eventStatusFromHttpCode, getEnvelopeType, isRateLimited, makePromiseBuffer, rejectedSyncPromise, resolvedSyncPromise, serializeEnvelope, updateRateLimits, } from '@sentry/utils';
export var ERROR_TRANSPORT_CATEGORY = 'error';
export var TRANSACTION_TRANSPORT_CATEGORY = 'transaction';
export var ATTACHMENT_TRANSPORT_CATEGORY = 'attachment';
export var SESSION_TRANSPORT_CATEGORY = 'session';
export var DEFAULT_TRANSPORT_BUFFER_SIZE = 30;
/**
 * Creates a `NewTransport`
 *
 * @param options
 * @param makeRequest
 */
export function createTransport(options, makeRequest, buffer) {
    if (buffer === void 0) { buffer = makePromiseBuffer(options.bufferSize || DEFAULT_TRANSPORT_BUFFER_SIZE); }
    var rateLimits = {};
    var flush = function (timeout) { return buffer.drain(timeout); };
    function send(envelope) {
        var envCategory = getEnvelopeType(envelope);
        var category = envCategory === 'event' ? 'error' : envCategory;
        var request = {
            category: category,
            body: serializeEnvelope(envelope),
        };
        // Don't add to buffer if transport is already rate-limited
        if (isRateLimited(rateLimits, category)) {
            return rejectedSyncPromise({
                status: 'rate_limit',
                reason: getRateLimitReason(rateLimits, category),
            });
        }
        var requestTask = function () {
            return makeRequest(request).then(function (_a) {
                var body = _a.body, headers = _a.headers, reason = _a.reason, statusCode = _a.statusCode;
                var status = eventStatusFromHttpCode(statusCode);
                if (headers) {
                    rateLimits = updateRateLimits(rateLimits, headers);
                }
                if (status === 'success') {
                    return resolvedSyncPromise({ status: status, reason: reason });
                }
                return rejectedSyncPromise({
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
function getRateLimitReason(rateLimits, category) {
    return "Too many " + category + " requests, backing off until: " + new Date(disabledUntil(rateLimits, category)).toISOString();
}
//# sourceMappingURL=base.js.map