type PartialURL = {
    host?: string;
    path?: string;
    protocol?: string;
    relative?: string;
    search?: string;
    hash?: string;
};
/**
 * Parses string form of URL into an object
 * // borrowed from https://tools.ietf.org/html/rfc3986#appendix-B
 * // intentionally using regex and not <a/> href parsing trick because React Native and other
 * // environments where DOM might not be available
 * @returns parsed URL object
 */
export declare function parseUrl(url: string): PartialURL;
/**
 * Strip the query string and fragment off of a given URL or path (if present)
 *
 * @param urlPath Full URL or path, including possible query string and/or fragment
 * @returns URL or path without query string or fragment
 */
export declare function stripUrlQueryAndFragment(urlPath: string): string;
/**
 * Returns number of URL segments of a passed string URL.
 */
export declare function getNumberOfUrlSegments(url: string): number;
/**
 * Takes a URL object and returns a sanitized string which is safe to use as span name
 * see: https://develop.sentry.dev/sdk/data-handling/#structuring-data
 */
export declare function getSanitizedUrlString(url: PartialURL): string;
export {};
//# sourceMappingURL=url.d.ts.map
