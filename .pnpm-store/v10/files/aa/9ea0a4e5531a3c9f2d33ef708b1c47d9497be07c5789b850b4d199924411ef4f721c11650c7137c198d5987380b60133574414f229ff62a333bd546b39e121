/**
 * @file resolve-url.js - Handling how URLs are resolved and manipulated
 */

import _resolveUrl from '@videojs/vhs-utils/es/resolve-url.js';

export const resolveUrl = _resolveUrl;

/**
 * Checks whether xhr request was redirected and returns correct url depending
 * on `handleManifestRedirects` option
 *
 * @api private
 *
 * @param  {string} url - an url being requested
 * @param  {XMLHttpRequest} req - xhr request result
 *
 * @return {string}
 */
export const resolveManifestRedirect = (handleManifestRedirect, url, req) => {
  // To understand how the responseURL below is set and generated:
  // - https://fetch.spec.whatwg.org/#concept-response-url
  // - https://fetch.spec.whatwg.org/#atomic-http-redirect-handling
  if (
    handleManifestRedirect &&
    req &&
    req.responseURL &&
    url !== req.responseURL
  ) {
    return req.responseURL;
  }

  return url;
};

export default resolveUrl;
