import { __assign } from "tslib";
import { createTransport, } from '@sentry/core';
import { getNativeFetchImplementation } from './utils';
/**
 * Creates a Transport that uses the Fetch API to send events to Sentry.
 */
export function makeNewFetchTransport(options, nativeFetch) {
    if (nativeFetch === void 0) { nativeFetch = getNativeFetchImplementation(); }
    function makeRequest(request) {
        var requestOptions = __assign({ body: request.body, method: 'POST', referrerPolicy: 'origin' }, options.requestOptions);
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
    return createTransport({ bufferSize: options.bufferSize }, makeRequest);
}
//# sourceMappingURL=new-fetch.js.map