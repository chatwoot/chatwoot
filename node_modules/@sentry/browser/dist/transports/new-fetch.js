Object.defineProperty(exports, "__esModule", { value: true });
var tslib_1 = require("tslib");
var core_1 = require("@sentry/core");
var utils_1 = require("./utils");
/**
 * Creates a Transport that uses the Fetch API to send events to Sentry.
 */
function makeNewFetchTransport(options, nativeFetch) {
    if (nativeFetch === void 0) { nativeFetch = utils_1.getNativeFetchImplementation(); }
    function makeRequest(request) {
        var requestOptions = tslib_1.__assign({ body: request.body, method: 'POST', referrerPolicy: 'origin' }, options.requestOptions);
        return nativeFetch(options.url, requestOptions).then(function (response) {
            return response.text().then(function (body) { return ({
                body: body,
                headers: {
                    'x-sentry-rate-limits': response.headers.get('X-Sentry-Rate-Limits'),
                    'retry-after': response.headers.get('Retry-After'),
                },
                reason: response.statusText,
                statusCode: response.status,
            }); });
        });
    }
    return core_1.createTransport({ bufferSize: options.bufferSize }, makeRequest);
}
exports.makeNewFetchTransport = makeNewFetchTransport;
//# sourceMappingURL=new-fetch.js.map