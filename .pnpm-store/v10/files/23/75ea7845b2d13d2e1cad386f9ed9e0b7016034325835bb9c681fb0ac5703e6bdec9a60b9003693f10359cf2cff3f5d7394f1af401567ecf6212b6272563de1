import { getNativeImplementation, clearCachedImplementation } from '@sentry-internal/browser-utils';
import { createTransport } from '@sentry/core';
import { rejectedSyncPromise } from '@sentry/utils';

/**
 * Creates a Transport that uses the Fetch API to send events to Sentry.
 */
function makeFetchTransport(
  options,
  nativeFetch = getNativeImplementation('fetch'),
) {
  let pendingBodySize = 0;
  let pendingCount = 0;

  function makeRequest(request) {
    const requestSize = request.body.length;
    pendingBodySize += requestSize;
    pendingCount++;

    const requestOptions = {
      body: request.body,
      method: 'POST',
      referrerPolicy: 'origin',
      headers: options.headers,
      // Outgoing requests are usually cancelled when navigating to a different page, causing a "TypeError: Failed to
      // fetch" error and sending a "network_error" client-outcome - in Chrome, the request status shows "(cancelled)".
      // The `keepalive` flag keeps outgoing requests alive, even when switching pages. We want this since we're
      // frequently sending events right before the user is switching pages (eg. whenfinishing navigation transactions).
      // Gotchas:
      // - `keepalive` isn't supported by Firefox
      // - As per spec (https://fetch.spec.whatwg.org/#http-network-or-cache-fetch):
      //   If the sum of contentLength and inflightKeepaliveBytes is greater than 64 kibibytes, then return a network error.
      //   We will therefore only activate the flag when we're below that limit.
      // There is also a limit of requests that can be open at the same time, so we also limit this to 15
      // See https://github.com/getsentry/sentry-javascript/pull/7553 for details
      keepalive: pendingBodySize <= 60000 && pendingCount < 15,
      ...options.fetchOptions,
    };

    if (!nativeFetch) {
      clearCachedImplementation('fetch');
      return rejectedSyncPromise('No fetch implementation available');
    }

    try {
      // TODO: This may need a `suppresTracing` call in the future when we switch the browser SDK to OTEL
      return nativeFetch(options.url, requestOptions).then(response => {
        pendingBodySize -= requestSize;
        pendingCount--;
        return {
          statusCode: response.status,
          headers: {
            'x-sentry-rate-limits': response.headers.get('X-Sentry-Rate-Limits'),
            'retry-after': response.headers.get('Retry-After'),
          },
        };
      });
    } catch (e) {
      clearCachedImplementation('fetch');
      pendingBodySize -= requestSize;
      pendingCount--;
      return rejectedSyncPromise(e);
    }
  }

  return createTransport(options, makeRequest);
}

export { makeFetchTransport };
//# sourceMappingURL=fetch.js.map
