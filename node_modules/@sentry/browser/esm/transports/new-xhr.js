import { createTransport, } from '@sentry/core';
import { SyncPromise } from '@sentry/utils';
/**
 * The DONE ready state for XmlHttpRequest
 *
 * Defining it here as a constant b/c XMLHttpRequest.DONE is not always defined
 * (e.g. during testing, it is `undefined`)
 *
 * @see {@link https://developer.mozilla.org/en-US/docs/Web/API/XMLHttpRequest/readyState}
 */
var XHR_READYSTATE_DONE = 4;
/**
 * Creates a Transport that uses the XMLHttpRequest API to send events to Sentry.
 */
export function makeNewXHRTransport(options) {
    function makeRequest(request) {
        return new SyncPromise(function (resolve, _reject) {
            var xhr = new XMLHttpRequest();
            xhr.onreadystatechange = function () {
                if (xhr.readyState === XHR_READYSTATE_DONE) {
                    var response = {
                        body: xhr.response,
                        headers: {
                            'x-sentry-rate-limits': xhr.getResponseHeader('X-Sentry-Rate-Limits'),
                            'retry-after': xhr.getResponseHeader('Retry-After'),
                        },
                        reason: xhr.statusText,
                        statusCode: xhr.status,
                    };
                    resolve(response);
                }
            };
            xhr.open('POST', options.url);
            for (var header in options.headers) {
                if (Object.prototype.hasOwnProperty.call(options.headers, header)) {
                    xhr.setRequestHeader(header, options.headers[header]);
                }
            }
            xhr.send(request.body);
        });
    }
    return createTransport({ bufferSize: options.bufferSize }, makeRequest);
}
//# sourceMappingURL=new-xhr.js.map